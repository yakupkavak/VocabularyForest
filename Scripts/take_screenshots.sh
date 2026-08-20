#!/usr/bin/env bash
#
# App Store ekran görüntülerini alır (store_screenshots.py sarmalayıcısı).
#
# Terminalden doğrudan çalıştırıldığında modeli hiç devreye sokmaz, yani sıfır token harcar:
#   ./Scripts/take_screenshots.sh                 # 12 dilin hepsi
#   ./Scripts/take_screenshots.sh Turkish         # yalnızca Türkçe
#   ./Scripts/take_screenshots.sh --skip-build    # test paketini yeniden derleme
#
# Çıplak dil adları otomatik olarak --languages'e çevrilir; tire ile başlayan her şey
# store_screenshots.py'ye olduğu gibi geçer.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

args=()
if [ "$#" -gt 0 ]; then
    case "$1" in
        -*) args=("$@") ;;
        *)  args=(--languages "$@") ;;
    esac
fi

# macOS bash 3.2'de set -u altında boş dizi genişletmesi hata verir.
exec python3 Scripts/store_screenshots.py ${args[@]+"${args[@]}"}
