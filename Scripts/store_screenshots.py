#!/usr/bin/env python3
"""Capture App Store screenshots for VocabularyForest in every supported language.

For each language the script switches the simulator's system language, pins a clean status
bar, runs the `StoreScreenshotTests` UI test, and drops the four exported screenshots into
that language's folder.

The test itself is language agnostic: every localized string it has to tap is resolved here
from `Localizable.xcstrings` and forwarded through `TEST_RUNNER_*` environment variables.

Usage:
    python3 Scripts/store_screenshots.py                    # every language
    python3 Scripts/store_screenshots.py --languages Turkish Chinese
    python3 Scripts/store_screenshots.py --skip-build
"""

from __future__ import annotations

import argparse
import json
import os
import plistlib
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass
from pathlib import Path

# --- CONFIGURATION ----------------------------------------------------------------------

PROJECT_DIR = Path(__file__).resolve().parent.parent
PROJECT = PROJECT_DIR / "VocabularyForest.xcodeproj"
SCHEME = "VocabularyForest"
TEST_ID = "VocabularyForestUITests/StoreScreenshotTests/testCaptureStoreScreenshots"
XCSTRINGS = PROJECT_DIR / "VocabularyForest" / "Data" / "Source" / "Localizable.xcstrings"
DERIVED_DATA = Path("/tmp/vf-screenshots-dd")

APP_BUNDLE_ID = "com.bootcamp.vocabulary-forest"
DEVICE_NAME = "iPhone 16e"
DEVICE_RUNTIME = "iOS 18.5"

OUTPUT_ROOT = (
    Path.home()
    / "Library/Mobile Documents/com~apple~CloudDocs/Desktop/Vocabulary Apple Store/NewFromPhone"
)

SCREENSHOT_NAMES = ["01_game", "02_adventure_road", "03_add_word", "04_bookcases"]

# The learning side is the same for every bookcase in the store screenshots.
LEARNING_LANGUAGE_CODE = "en-US"

# Keys the UI test needs resolved into the language being captured.
STRING_KEYS = {
    "SHOT_ENTER_FOREST": "Maceraya Atıl",
    "SHOT_PLAY_GAME": "a11y_play_game",
    "SHOT_ADVENTURE_BOARD": "a11y_adventure_board",
    "SHOT_ADVENTURE_ROAD": "Adventure Road",
    "SHOT_SELECT_BOOKCASE_BUTTON": "Kitaplık seçiniz",
    "SHOT_START_GAME": "Oyuna Başla",
    "SHOT_SELECT_BOOKCASE_ICON": "a11y_select_bookcase",
    # BattleEnemyModel.fireDragon.title — the game popup opens on Classic, so it is tapped.
    "SHOT_BATTLE_MODE": "Ateş Ejderi",
}

# `Libraries.toLanguageDisplayName()` in Packages/Domain resolves codes through these keys.
LANGUAGE_DISPLAY_KEYS = {
    "en-US": "İngilizce (US)",
    "en-GB": "İngilizce (Birleşik Krallık)",
    "es": "İspanyolca",
    "pt-BR": "Portekizce (Brezilya)",
    "zh-CN": "Çince (Basitleştirilmiş)",
    "ar": "Arapça",
    "hi": "Hintçe",
    "ru": "Rusça",
    "tr": "Türkçe",
    "fr": "Fransızca",
    "ja": "Japonca",
    "ko": "Korece",
    "de": "Almanca",
    "it": "İtalyanca",
}


@dataclass(frozen=True)
class Language:
    """One output folder: the UI language to run in and the bookcases to pick."""

    folder: str
    app_language: str  # value for AppleLanguages / knownRegions
    locale: str  # value for AppleLocale
    meaning_code: str  # bookcase meaning language stored in Core Data


# English is skipped: there is no English/English bookcase on the device.
LANGUAGES = [
    Language("Turkish", "tr", "tr_TR", "tr"),
    Language("Arabic", "ar", "ar_SA", "ar"),
    Language("German", "de", "de_DE", "de"),
    Language("Spanish", "es-419", "es_419", "es"),
    Language("French", "fr", "fr_FR", "fr"),
    Language("Hindi", "hi", "hi_IN", "hi"),
    Language("Italian", "it", "it_IT", "it"),
    Language("Japanese", "ja", "ja_JP", "ja"),
    Language("Korean", "ko", "ko_KR", "ko"),
    Language("Portuguese", "pt-BR", "pt_BR", "pt-BR"),
    Language("Russian", "ru", "ru_RU", "ru"),
    Language("Chinese", "zh-CN", "zh_CN", "zh-CN"),
]


# --- SHELL HELPERS ----------------------------------------------------------------------


def run(cmd: list[str], **kwargs) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True, **kwargs)


def check(cmd: list[str], **kwargs) -> str:
    result = run(cmd, **kwargs)
    if result.returncode != 0:
        raise RuntimeError(f"{' '.join(cmd[:3])}… failed:\n{result.stdout[-2000:]}\n{result.stderr[-2000:]}")
    return result.stdout


def log(message: str) -> None:
    print(f"[screenshots] {message}", flush=True)


# --- SIMULATOR --------------------------------------------------------------------------


def find_device() -> str:
    devices = json.loads(check(["xcrun", "simctl", "list", "devices", "available", "--json"]))["devices"]
    for runtime, entries in devices.items():
        if DEVICE_RUNTIME.replace(" ", "-").replace(".", "-") not in runtime:
            continue
        for entry in entries:
            if entry["name"] == DEVICE_NAME:
                return entry["udid"]
    raise RuntimeError(f"Simulator '{DEVICE_NAME}' ({DEVICE_RUNTIME}) not found")


def device_data_dir(udid: str) -> Path:
    return Path.home() / "Library/Developer/CoreSimulator/Devices" / udid / "data"


def shutdown(udid: str) -> None:
    run(["xcrun", "simctl", "shutdown", udid])
    for _ in range(60):
        state = check(["xcrun", "simctl", "list", "devices", "--json"])
        if f'"udid" : "{udid}"' not in state:
            break
        devices = json.loads(state)["devices"]
        current = next(
            (e for entries in devices.values() for e in entries if e["udid"] == udid), None
        )
        if current is None or current["state"] == "Shutdown":
            return
        time.sleep(1)


def set_system_language(udid: str, language: Language) -> None:
    """Writes the global preferences directly, which only applies while the device is down."""
    plist_path = device_data_dir(udid) / "Library/Preferences/.GlobalPreferences.plist"
    plist_path.parent.mkdir(parents=True, exist_ok=True)
    data = {}
    if plist_path.exists():
        with plist_path.open("rb") as handle:
            data = plistlib.load(handle)
    data["AppleLanguages"] = [language.app_language]
    data["AppleLocale"] = language.locale
    with plist_path.open("wb") as handle:
        plistlib.dump(data, handle)


def boot(udid: str) -> None:
    run(["xcrun", "simctl", "boot", udid])
    run(["xcrun", "simctl", "bootstatus", udid, "-b"])


def pin_status_bar(udid: str) -> None:
    """Apple's standard store-screenshot status bar, identical in every language."""
    run(
        [
            "xcrun", "simctl", "status_bar", udid, "override",
            "--time", "09:41",
            "--dataNetwork", "wifi",
            "--wifiMode", "active",
            "--wifiBars", "3",
            "--cellularMode", "active",
            "--cellularBars", "4",
            "--batteryState", "charged",
            "--batteryLevel", "100",
        ]
    )


# --- APP DATA ---------------------------------------------------------------------------


def app_store_path(udid: str) -> Path:
    container = check(
        ["xcrun", "simctl", "get_app_container", udid, APP_BUNDLE_ID, "data"]
    ).strip()
    return Path(container) / "Library/Application Support/VocabularyForest.sqlite"


def read_bookcases(store: Path) -> list[tuple[str, str, float]]:
    """Returns (name, meaning language, created date) newest first, matching the app's order."""
    with tempfile.TemporaryDirectory() as tmp:
        copy = Path(tmp) / "store.sqlite"
        for suffix in ["", "-wal", "-shm"]:
            source = Path(str(store) + suffix)
            if source.exists():
                shutil.copy(source, str(copy) + suffix)
        connection = sqlite3.connect(str(copy))
        rows = connection.execute(
            "SELECT ZNAME, ZMEANINGLANGUAGE, ZCREATEDDATE FROM ZBOOKCASE ORDER BY ZCREATEDDATE DESC"
        ).fetchall()
        connection.close()
    return rows


def bookcase_named(rows, prefix: str, meaning_code: str) -> str:
    for name, meaning, _ in rows:
        if meaning == meaning_code and name.startswith(prefix):
            return name
    raise RuntimeError(f"No '{prefix}' bookcase for meaning language '{meaning_code}'")


# --- LOCALIZATION -----------------------------------------------------------------------


def load_catalog() -> dict:
    with XCSTRINGS.open(encoding="utf-8") as handle:
        return json.load(handle)["strings"]


def localized(catalog: dict, key: str, language: str) -> str:
    """Mirrors SwiftUI's lookup: a missing localization falls back to the key itself."""
    entry = catalog.get(key)
    if not entry:
        return key
    unit = entry.get("localizations", {}).get(language, {}).get("stringUnit", {})
    value = unit.get("value")
    return value if value else key


def language_line(catalog: dict, language: str, meaning_code: str) -> str:
    """Reproduces the `<learning> / <meaning>` subtitle rendered by `BookcaseRow`."""
    learning = localized(catalog, LANGUAGE_DISPLAY_KEYS[LEARNING_LANGUAGE_CODE], language)
    meaning = localized(catalog, LANGUAGE_DISPLAY_KEYS[meaning_code], language)
    return f"{learning} / {meaning}"


# --- TEST RUN ---------------------------------------------------------------------------


def build_for_testing(udid: str) -> None:
    log("building test bundle…")
    check(
        [
            "xcodebuild", "build-for-testing",
            "-project", str(PROJECT),
            "-scheme", SCHEME,
            "-destination", f"platform=iOS Simulator,id={udid}",
            "-derivedDataPath", str(DERIVED_DATA),
        ],
        cwd=str(PROJECT_DIR),
    )


def run_test(udid: str, environment: dict[str, str], result_path: Path) -> subprocess.CompletedProcess:
    if result_path.exists():
        shutil.rmtree(result_path)
    env = os.environ.copy()
    # xcodebuild forwards TEST_RUNNER_-prefixed variables to the runner with the prefix stripped.
    env.update({f"TEST_RUNNER_{key}": value for key, value in environment.items()})
    return run(
        [
            "xcodebuild", "test-without-building",
            "-project", str(PROJECT),
            "-scheme", SCHEME,
            "-destination", f"platform=iOS Simulator,id={udid}",
            "-derivedDataPath", str(DERIVED_DATA),
            "-only-testing:" + TEST_ID,
            "-resultBundlePath", str(result_path),
        ],
        cwd=str(PROJECT_DIR),
        env=env,
    )


def export_screenshots(result_path: Path, destination: Path, wanted: list[str]) -> list[str]:
    with tempfile.TemporaryDirectory() as tmp:
        check(
            [
                "xcrun", "xcresulttool", "export", "attachments",
                "--path", str(result_path),
                "--output-path", tmp,
            ]
        )
        manifest_path = Path(tmp) / "manifest.json"
        if not manifest_path.exists():
            return []
        manifest = json.loads(manifest_path.read_text())

        exported = []
        destination.mkdir(parents=True, exist_ok=True)
        for test in manifest:
            for attachment in test.get("attachments", []):
                # XCTest appends "_<index>_<uuid>.png" to the name given in the test.
                name = attachment.get("suggestedHumanReadableName") or ""
                stem = next((s for s in wanted if name.startswith(s + "_")), None)
                if stem is None:
                    continue
                source = Path(tmp) / attachment["exportedFileName"]
                if not source.exists():
                    continue
                shutil.copy(source, destination / f"{stem}.png")
                exported.append(stem)
        return exported


# --- MAIN -------------------------------------------------------------------------------


def capture(
    udid: str,
    catalog: dict,
    bookcases,
    language: Language,
    results_dir: Path,
    wanted: list[str],
) -> list[str]:
    b1 = bookcase_named(bookcases, "B1", language.meaning_code)
    a2 = bookcase_named(bookcases, "A2", language.meaning_code)
    line = language_line(catalog, language.app_language, language.meaning_code)

    environment = {
        "SHOT_LANGUAGE": language.app_language,
        "SHOT_LOCALE": language.locale,
        "SHOT_B1_NAME": b1,
        "SHOT_A2_NAME": a2,
        "SHOT_B1_LANGUAGE_LINE": line,
        "SHOT_A2_LANGUAGE_LINE": line,
    }
    for variable, key in STRING_KEYS.items():
        environment[variable] = localized(catalog, key, language.app_language)
    if wanted != SCREENSHOT_NAMES:
        environment["SHOT_ONLY"] = ",".join(wanted)

    log(f"{language.folder}: {b1} / {a2} — '{line}'")

    shutdown(udid)
    set_system_language(udid, language)
    boot(udid)
    pin_status_bar(udid)

    result_path = results_dir / f"{language.folder}.xcresult"
    outcome = run_test(udid, environment, result_path)
    if outcome.returncode != 0:
        log(f"{language.folder}: test reported failure (exit {outcome.returncode})")
        tail = "\n".join(outcome.stdout.strip().splitlines()[-15:])
        log(tail)

    exported = export_screenshots(result_path, OUTPUT_ROOT / language.folder, wanted)
    log(
        f"{language.folder}: exported {len(exported)}/{len(wanted)}"
        f" → {', '.join(sorted(exported)) or 'none'}"
    )
    return exported


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--languages", nargs="*", help="folder names to capture (default: all)")
    parser.add_argument("--skip-build", action="store_true")
    parser.add_argument(
        "--only",
        nargs="*",
        choices=SCREENSHOT_NAMES,
        help="capture only these screenshots (default: all four)",
    )
    parser.add_argument("--results-dir", default="/tmp/vf-screenshot-results")
    args = parser.parse_args()

    selected = LANGUAGES
    if args.languages:
        wanted = {name.lower() for name in args.languages}
        selected = [language for language in LANGUAGES if language.folder.lower() in wanted]
        if not selected:
            log(f"no matching languages in {[l.folder for l in LANGUAGES]}")
            return 1

    wanted = args.only or SCREENSHOT_NAMES
    udid = find_device()
    log(f"device {DEVICE_NAME} ({udid})")
    if wanted != SCREENSHOT_NAMES:
        log(f"capturing only: {', '.join(wanted)}")

    boot(udid)
    catalog = load_catalog()
    bookcases = read_bookcases(app_store_path(udid))
    log(f"{len(bookcases)} bookcases on device")

    if not args.skip_build:
        build_for_testing(udid)

    results_dir = Path(args.results_dir)
    results_dir.mkdir(parents=True, exist_ok=True)

    summary = {}
    for language in selected:
        summary[language.folder] = capture(
            udid, catalog, bookcases, language, results_dir, wanted
        )

    run(["xcrun", "simctl", "status_bar", udid, "clear"])

    log("--- summary ---")
    incomplete = 0
    for folder, exported in summary.items():
        missing = [name for name in wanted if name not in exported]
        status = "ok" if not missing else f"MISSING {', '.join(missing)}"
        log(f"{folder:<12} {len(exported)}/{len(wanted)}  {status}")
        incomplete += bool(missing)
    return 1 if incomplete else 0


if __name__ == "__main__":
    sys.exit(main())
