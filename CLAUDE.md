# iOS Kod Yazım Kuralları — Vocabulary Forest

Bu dosya, `VocabularyForest iOS` projesinde kod yazarken uyulacak mühendislik kurallarını tanımlar.
Kod yazan herkes (insan veya ajan) **senior bir iOS developer'ın takım içinde çalıştığı** standartla
yazar: başkasının okuyacağı, test edilebilir, uzun ömürlü kod.

iOS bu ürünün **kaynak platformudur**; Android buradan mirror edilir. Bu yüzden burada verilen
davranış, renk, Firestore alan adı ve Remote Config anahtarı kararları Android'i de bağlar.
Android tarafının kuralları `Vocabulary Forest Android/CLAUDE.md` içindedir.

---

## 1. Dosya iskeleti ve MARK düzeni

Her dosya aynı sırayla okunur. Bu düzen projede tutarlıdır ve **yeni dosyalarda da korunur** —
tip gövdesi şişirilmez, sorumluluklar extension'lara bölünür.

**Data/servis katmanı iskeleti:**

```swift
import Foundation
import Combine

enum XError: Error { }              // varsa, en üstte

protocol XProtocol: AnyObject { }   // protokol her zaman tipten ÖNCE

// MARK: - CONSTANTS

private extension X {
    enum Constants { }
}

final class X {

    // MARK: - PROPERTIES

    private let dependency: DependencyProtocol

    // MARK: - INIT

    init(dependency: DependencyProtocol) {
        self.dependency = dependency
    }
}

// MARK: - PROTOCOL CONFORMANCE

extension X: XProtocol { }          // public API burada

// MARK: - HELPERS

private extension X { }             // yardımcılar burada
```

**SwiftUI iskeleti** (mevcut örnek: `VocabularyForest/UI/Main/Forest/ForestUI.swift`):

```
import ...
protocol XUIProtocol { }
// MARK: - CONSTANTS       → private extension X { enum Constants { } }
// MARK: - VIEW            → struct X: View { var body }
// MARK: - UI COMPONENTS   → private extension X { }
// MARK: - HELPERS         → private extension X { }
// MARK: - PROTOCOL CONFORMANCE → extension X: XUIProtocol { }
#Preview { }
```

**Kurallar:**
- **MARK biçimi tektir: `// MARK: - BÜYÜK HARF`.** `// MARK: - Private Downloader` gibi karışık
  yazım yeni kodda kullanılmaz. Kullanılan başlıklar: `PROPERTIES`, `DEPENDENCIES`, `INIT`,
  `CONSTANTS`, `VIEW`, `BODY`, `UI COMPONENTS`, `HELPERS`, `PRIVATE HELPERS`,
  `PROTOCOL CONFORMANCE`, `ACTIONS`, `PREVIEW`.
- MARK'ın altına **bir boş satır** bırakılır.
- **`final class` gövdesinde yalnızca stored property'ler ve `init` bulunur.** Metotlar
  extension'lara taşınır: protokol implementasyonu `extension X: XProtocol`, iç yardımcılar
  `private extension X`. Tip gövdesine metot yazmak yeni kodda kabul edilmez.
- Dosya adı ana tipin adıdır; dosya başına tek ana sorumluluk.

---

## 2. Sabitler her zaman extension içinde

**Sabitler tip gövdesine yazılmaz.** Dosyanın üstünde, `// MARK: - CONSTANTS` altında ayrı bir
extension'da yaşar (mevcut örnekler: `PlantManager.swift:24`, `AnimalManager.swift:27`,
`ForestUI.swift:23`).

```swift
// MARK: - CONSTANTS

private extension PlantManager {
    enum Constants {
        static let anchorPointX: CGFloat = 0.5
        static let firstFrameIndex: Int = 0
    }
}
```

**Kurallar:**
- Tip dışından erişilmesi gerekmiyorsa extension `private` olur; gerekiyorsa `internal` bırakılır.
- İsim **`Constants`** (çoğul). `Constant` tekil biçimi eski kodda kalmıştır, yeni kodda kullanılmaz.
- Enum `case`'siz namespace olarak kullanılır — `struct` veya `class` değil, örneklenemesin diye.
- **Sihirli sayı ve sihirli string yasak.** Kod içinde doğrudan `0.5`, `"version_"`, `5.0` yazılmaz;
  anlamlı isimle Constants'a taşınır.
- Birden çok tipin paylaştığı sabitler `UI/Constants/` altında dosya seviyesinde bir `enum`'a konur
  (mevcut örnek: `BattleConstant.swift`, `GameConstant`).
- Renk, metin ve boyut sabitleri buraya **yazılmaz** — onların yeri bölüm 4 ve 5.

---

## 3. Mimari: protokol odaklı ve SOLID

Proje protokol odaklıdır. Her servis, repository ve manager bir protokolün arkasındadır; bağımlılık
somut tipe değil protokole verilir.

**SOLID karşılıkları — bu proje özelinde:**

| İlke | Bu projede anlamı |
|---|---|
| **S** — Tek sorumluluk | Bir tip tek bir işi yapar. `RewardAssetHydrationService` indirmeyi yönetir; task sıralama/iptal mantığı ayrı bir tipe (`AssetHydrationQueue`) çıkar. 300+ satırlık servisler bölünür. |
| **O** — Açık/kapalı | Yeni ödül türü, yeni chest, yeni asset kaynağı eklemek `switch` gövdelerini düzenlemekle değil, protokol/enum'a yeni case + veri ekleyerek çözülür. Uzak konfigürasyondan gelen veri koda gömülü `if id.contains("gold")` gibi tahminlerle yorumlanmaz. |
| **L** — Yerine geçebilirlik | Protokolü uygulayan her tip (gerçek veya `Mock*`) çağıranı bozmadan geçebilmeli. Implementasyona özel yan etkiler protokol sözleşmesinin dışına taşmaz. |
| **I** — Arayüz ayrımı | Şişkin protokol yazılmaz. Çağıranın ihtiyacı `RewardAssetDownloaderProtocol` ise ona tüm repository verilmez. |
| **D** — Bağımlılığın tersine çevrilmesi | Üst katman alt katmana değil protokole bağlıdır. ViewModel `Firestore`, `NSManagedObjectContext` veya `URLSession` almaz. |

**Kurallar:**
- **Bağımlılıklar `init` üzerinden enjekte edilir.** Sınıf içinde `Firestore.firestore()`,
  `UserDefaults.standard`, `FileManager.default` doğrudan çağrılmaz — protokol arkasından gelir.
- Grafiğin kurulduğu **tek yer `Extensions/Configure/AppDependencyConfigurer.swift`**; kayıt
  `DC.shared.register(type: .singleInstance(x), for: XProtocol.self)` ile yapılır. Tipler kendi
  bağımlılığını konteynerden **kendi başına çözmez** (service locator yasak); yalnızca
  coordinator/configurer katmanı `resolve` çağırır.
- **Katman sınırları:**
  - `UI/` → SwiftUI view + ViewModel. CoreData/Firestore'a doğrudan dokunmaz.
  - `Data/Local` → CoreData, dosya sistemi, `UserDefaults`.
  - `Data/Network` → Firebase, API, Remote Config, asset indirme.
  - `Extensions/` → konfigürasyon, modifier, yardımcılar.
  - `Packages/` (`CoreAPI`, `DependencyContainer`, `Domain`, `Router`) → yerel SPM paketleri;
    uygulama koduna bağımlı olamazlar.
- **ViewModel'ler `BaseViewModel`'den türer**, state `@Published` ile yayılır. Deployment target
  **iOS 16.6** olduğu için `@Observable` (iOS 17+) **kullanılamaz** — `ObservableObject` + Combine
  kalır.
- **Hata sessizce yutulmaz.** `try?` ve boş `catch` yalnızca gerçekten "best effort" olan ve
  yorumla gerekçelendirilmiş yerlerde kullanılır; aksi halde hata yukarı taşınır veya loglanır.
- **`Resource<T>`** (`Data/Base/Resource.swift`) senkron veri katmanı sonuçlarının standart dönüş
  tipidir; yeni kodda ad-hoc tuple/optional dönüşleri icat edilmez.
- Zaman, rastgelelik ve cihaz durumu iş mantığına gömülmez; test edilebilir olması için protokol
  arkasından gelir.

---

## 4. Minimal kod

**En iyi kod yazılmayan koddur.** Her satır sonradan okunacak, taşınacak ve Android'e mirror
edilecektir.

**Kurallar:**
- **Önce ara, sonra yaz.** Aynı işi yapan bir yardımcı zaten var mı (`Extensions/`, `UI/Helpers/`,
  `Data/Util/`) diye bakılır; varsa yeniden yazılmaz.
- **Tekrar eden `switch` blokları veriye indirgenir.** Aynı enum üzerinde renk/metin/boyut döndüren
  beş ayrı `switch` yerine tek bir palet/model tipi yazılır.
- **Spekülatif genelleme yapılmaz.** "İleride lazım olur" diye protokol, generic veya konfigürasyon
  noktası eklenmez; ikinci kullanım ortaya çıkınca soyutlanır.
- **Ölü kod bırakılmaz:** yorum satırına alınmış bloklar, kullanılmayan `import`, erişilmeyen
  `private` metotlar, deneme amaçlı `print` silinir.
- Yorumlar **"ne" değil "neden"** anlatır. Kodun kendisini tekrar eden yorum yazılmaz; invariant,
  sıralama bağımlılığı ve platform kısıtı gibi kodun söyleyemediği şeyler yazılır.
- **Tüm yorumlar İngilizce.** Türkçe yorum yeni kodda kabul edilmez (kullanıcıya görünen metinler
  bunun dışında — onlar bölüm 5'e tabidir).
- Fonksiyonlar tek ekranı aşmaz; `body` içinde ağır hesap yapılmaz, alt view'lara bölünür.

---

## 5. Dil desteği (lokalizasyon)

Kullanıcının gördüğü hiçbir metin koda gömülmez.

**Kurallar:**
- Metinler `String(localized: "...")` ile gelir; kaynak `Data/Source/Localizable.xcstrings`.
- **String Catalog tek kaynaktır.** Yeni bir anahtar eklendiğinde desteklenen tüm diller doldurulur;
  tek dilde bırakılmış anahtar bırakılmaz.
- **String birleştirme yapılmaz**, `%lld` / `%@` placeholder kullanılır. Çoğul biçimler catalog'un
  plural varyantıyla çözülür, `if count == 1` ile elle seçilmez.
- Tarih/sayı biçimlendirmesi locale-aware API ile yapılır (`formatted()`, `DateFormatter` + locale);
  `"dd/MM/yyyy"` gibi biçim sabitlenmez.
- **RTL uyumu:** `.padding(.leading/.trailing)` ve `.leading/.trailing` hizalama kullanılır;
  `.left/.right` kullanılmaz.
- Log mesajları, Firestore alan adları, Remote Config anahtarları ve CoreData attribute isimleri
  **çeviri kaynağı değildir** — sabit kalır ve Android ile birebir aynıdır.

---

## 6. Renkler ve tema

**Kurallar:**
- **Kod içinde `Color(hex: "#...")` yazmak yasak.** Renk `Data/Source/Assets.xcassets/Colors`
  altındaki adlandırılmış renkten gelir (`.logoGreen`, `.brown500`, `.backgroundSystem`).
- Tek istisna: **uzak konfigürasyondan (Remote Config) gelen** hex değerleri. Bunlar veriden gelir,
  koda gömülmez; eksik olduklarında düşülecek varsayılan palet tek bir yerde tanımlanır.
- **Dark mode zorunlu:** her yeni renk için Assets'te light ve dark varyantı tanımlanır. Tek sabit
  renkle iki temayı idare etmek kabul edilmez.
- Renk isimleri **anlamsal** olur (`SelectedButton`, `BackgroundSystem`), `Green2` gibi değil.
- Android'de karşılığı olan her renk **birebir aynı değerde** olmalıdır (mirror prensibi).

---

## 7. Ekran uyumu

UI hem küçük telefonda hem iPad'de düzgün çalışmak zorundadır.

**Kurallar:**
- Ekran genişliğini varsayan sabit `.frame(width:)` kullanılmaz; `GeometryReader`, oran ve
  `.frame(maxWidth:)` tercih edilir. Sabit boyut yalnızca ikon/avatar gibi gerçekten sabit öğelerde.
- Dikeyde taşabilecek her ekran `ScrollView` içine alınır; CTA küçük ekranda ekran dışında kalmaz.
- Dynamic Type kırılmaya yol açmaz; metin kutuları sabit yükseklikle kilitlenmez.
- Dokunma hedefi minimum 44×44 pt.
- Safe area `.safeAreaInset` / `.ignoresSafeArea` ile bilinçli yönetilir; status bar yüksekliği
  sabit sayı olarak yazılmaz.
- Her yeni ekran için `#Preview` eklenir.

---

## 8. Test

Proje **Swift Testing** kullanır (`import Testing`, `@Suite`, `@Test`, `#expect`) — XCTest değil.
Mevcut testler `VocabularyForestTests/Integration/` altındadır.

**Kurallar:**
- Test edilen tip `sut` olarak adlandırılır ve **protokol tipiyle** tutulur.
- Sahte bağımlılıklar `Mock<Protokol>` adıyla, ilgili protokolü uygulayarak yazılır.
- Suite'ler `@Suite("...", .tags(...))` ile etiketlenir; CoreData'ya dokunanlar in-memory store ile
  çalışır (`init(inMemory: true)`).
- Yeni bir servis veya repository yazılırken **protokolü olmayan, dolayısıyla test edilemeyen tip
  üretilmez.** "Test edilemez ama çalışıyor" kabul edilmez.

---

## 9. Kod okuma ve context yönetimi (token verimliliği)

Ana konuşmanın context'i sınırlı ve pahalı bir kaynaktır. **Context'e giren hiçbir şey çıkmaz** —
okunan her satır sonraki her istekte yeniden ücretlendirilir. Bu yüzden okuma "önce her şeyi al,
sonra ele" değil, "önce daralt, sonra oku" şeklinde yapılır.

### Önce keşfet, sonra oku

Her zaman ucuz olandan pahalı olana doğru gidilir:

```
wc -l / --stat / -l   →   grep -n (dar)   →   Read + offset/limit   →   Read (tam dosya)
```

- **Tam dosya okuma son çaredir.** 700+ satırlık dosyalar (`ForestDataManager.swift` 997,
  `CoreDataManager.swift` 928, `ForestViewModel.swift` 794) baştan sona okunmaz; önce `grep -n` ile
  hedef satır bulunur, sonra `Read` + `offset`/`limit` ile ±30 satır alınır.
- Aramada **her zaman** `--include='*.swift'` verilir ve `head` ile sınırlanır. Filtresiz `grep -r`
  bu repoda binlerce satır lokalizasyon verisi döndürür.

### Asla ham dökülmeyecek dosyalar

| Dosya | Satır | Nasıl okunur |
|---|---|---|
| `Data/Source/Localizable.xcstrings` | ~13.400 | Asla `Read` edilmez. Anahtar kontrolü: `grep -c '"anahtar"' ...` |
| `VocabularyForest.xcodeproj/project.pbxproj` | ~1.000 | Yalnızca hedefli `grep -o` (ör. `SWIFT_VERSION`, `DEPLOYMENT_TARGET`) |
| `*.xcdatamodeld/*/contents` | — | Yalnızca `grep -n '<attribute name="…"'` |
| `Assets.xcassets/**` | — | `find`/`ls` ile isim listesi; içerik okunmaz |

### Diff inceleme

Bekleyen değişiklik incelenirken tüm diff context'e çekilmez:

```bash
git diff HEAD --stat -- '*.swift'                    # önce kapsam
git diff HEAD -- 'path/to/one/File.swift'            # sonra dosya dosya
git diff HEAD -U0 -- '*.swift' | grep -E '^\+.*TODO' # veya hedefli tarama
```

Üretilmiş/veri dosyaları (`*.xcstrings`, `*.pbxproj`, `contents`) diff kapsamından **pathspec ile
dışlanır**; bunlar tek başına diff'in %90'ını oluşturabilir.

### Komut çıktısı disiplini

- **Derleme çıktısı ham dökülmez:**

```bash
xcodebuild -project VocabularyForest.xcodeproj -scheme VocabularyForest -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|warning:|BUILD" | head -30
```

- Sayı yeterliyse içerik değil sayı istenir: `grep -rc` / `| wc -l`.
- Bağımsız komutlar **tek mesajda paralel** çağrılır; her tur ek gecikme ve ek context demektir.

### Düzenleme disiplini

- **Düzenlenen dosya doğrulamak için tekrar okunmaz.** `Edit` başarısız olsaydı hata dönerdi;
  harness dosya durumunu zaten takip eder.
- Aynı değişiklik birden çok yerde tekrar ediyorsa tek tek değil `replace_all` ile yapılır.
- Aynı dosyada birden çok küçük düzenleme varsa dosya bir kez okunur, sonra arka arkaya `Edit` edilir.

### Alt-ajan ne zaman?

| Durum | Karar |
|---|---|
| Dosya yolu belli, 1-3 dosya | Doğrudan `Read` — spawn maliyeti tasarruftan büyük |
| Tek sembolün nerede geçtiği | Doğrudan `Grep` |
| "Bu özellik nerede yapılmış?", kapsam belirsiz, çok dizine yayılı | `Explore` alt-ajanı |
| Çok dosyaya yayılan refactor öncesi etki analizi | Alt-ajan; çıktıyı `dosya:satır` olarak iste |

Alt-ajana **çıktı formatı** açıkça yazılır ("şu 4 başlıkta özetle", "dosyanın tamamını dökme").
Aynı konuda devam edilecekse yeni ajan açılmaz — mevcut ajana `SendMessage` ile devam edilir; yeni
ajan sıfırdan başlar ve aynı context'i yeniden üretir.

---

## 10. Commit öncesi kontrol listesi

- [ ] Dosya iskeleti bölüm 1'deki sıraya uyuyor mu; `final class` gövdesinde metot kaldı mı?
- [ ] MARK'lar `// MARK: - BÜYÜK HARF` biçiminde mi?
- [ ] Sabitler `// MARK: - CONSTANTS` altında extension'da mı; kodda sihirli sayı/string kaldı mı?
- [ ] Yeni bağımlılıklar protokol üzerinden mi geliyor, `init`'ten mi enjekte ediliyor?
- [ ] Kod içinde hardcoded renk (`Color(hex:)`) veya hardcoded kullanıcı metni kaldı mı?
- [ ] Yeni string'ler `Localizable.xcstrings`'e tüm dillerde eklendi mi?
- [ ] Light ve dark tema kontrol edildi mi?
- [ ] Küçük telefon ve iPad'de düzen bozulmuyor mu; `#Preview` eklendi mi?
- [ ] Türkçe yorum, deneme amaçlı `print` ve ölü kod temizlendi mi?
- [ ] CoreData modeli değiştiyse **yeni model versiyonu** eklendi mi? (Yerinde düzenleme migration'ı
      kırar ve kullanıcının yerel verisini sildirir — bkz. `CoreDataManager.recoverFromStoreLoadFailure`.)
- [ ] Build başarılı mı?
- [ ] Android'e mirror edilmesi gereken davranış/renk/anahtar değişikliği var mı?
