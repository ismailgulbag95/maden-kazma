# Taşın Altı

Flutter tabanlı, Android/iOS telefonlarda yalnızca portre yönde tek elle oynanabilen; yüzeyde maden işletmesi ve yeraltında derinlik keşfi sunan idle mining oyunu.

## Proje belgeleri

- Oynanış kaynakları: [SOURCES.md](SOURCES.md)
- Üç ilk görsel yön: [DESIGN_OPTIONS.md](DESIGN_OPTIONS.md)
- Seçilen A yönünün güncel oyun ekranı: [tasin-alti-main-screen.png](assets/concepts/tasin-alti-main-screen.png)
- Üretilen sprite atlasları: [ASSET_CATALOG.md](ASSET_CATALOG.md)
- Eksiksiz Flutter uygulama yönergesi: [AGENT_IMPLEMENTATION_PROMPT.md](AGENT_IMPLEMENTATION_PROMPT.md)
- Görsel sistem: [design-system/tasin-alti/MASTER.md](design-system/tasin-alti/MASTER.md)
- Ürün tasarımı: [GAME_DESIGN.md](GAME_DESIGN.md)
- Derinlik ve ekonomi: [PROGRESSION.md](PROGRESSION.md), [ECONOMY.md](ECONOMY.md)
- Görsel ve teknik sözleşmeler: [ART_BIBLE.md](ART_BIBLE.md), [UI_BIBLE.md](UI_BIBLE.md), [CONTENT_UNLOCKS.md](CONTENT_UNLOCKS.md), [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md)

## Görsel yön

Seçilen A seçeneği, sıcak piksel sanatı ve tıklanabilir yüzey yerleşkesiyle güncellendi. Asansör, atölye, ambar, ticaret, araştırma ve sefer garajı ayrı oyun hedefleridir. Yeraltı sahnesi, görevler, kaynak kapasitesi ve yükseltmeler aynı ana ekranda görünür.

## Çalıştırma

Flutter 3.47 veya Dart 3.13 ile:

```sh
flutter pub get
flutter devices
flutter run -d ANDROID_DEVICE_ID
```

Android/iOS ve Windows/macOS/Linux hedefleri için Flutter platform iskeletleri depodadır. Web kaydı tarayıcı depolamasını, yerel uygulamalar sürümlü JSON dosyasını ve kurtarılabilir son geçerli yedeği kullanır. Yönetici olmadan çevrimdışı üretim yapılmaz; üç yönetici kademesi üretimi %25/%50/%100 hızında en çok 12/24/48 saat sürdürür.

Değişiklikleri doğrulamak için `flutter analyze` ve `flutter test` çalıştır. iOS derlemesi Xcode yüklü bir macOS ortamı gerektirir.

## Oynanış

- Yüzeydeki altı yapı tıklanabilir: asansör, atölye, ambar, ticaret, araştırma ve sefer garajı.
- Cevher düğümlerine dokunup kırılma çubuğunu ilerlet veya büyük **KAZI** düğmesini kullan; madenciler kuyuyu otomatik ilerletir.
- Atölyede madencileri kazı, taşıma, tarama ve ayıklama işlerine dağıt. Sekiz yükseltme ailesi 100'er seviye içerir.
- Ambar kapasitesi dolunca kazı durur. Kaynakları seçerek ya da kısmen sat; kilitle, rezerv tut veya kargo eşiğinde otomatik satışı aç.
- Derinlik ilerledikçe 50 mineral, 42 doğal izotop, reaktörle sentezlenen altı ileri izotop, yeni biyomlar, mağara dronları ve rota seçimi, bilim insanları, kalıntılar, Ay ve Titan katmanları açılır.
- Mağaralarda kaya, çamur, radyasyon ve 300 km sonrasında lav tehlikeleri; 300 km'de ise geliştirilebilir petrol pompası, petrol satışı ve yapı malzemesi işleme açılır.
- Atölyede sondaj ucu, soğutma fanı ve motor ayrı ayrı geliştirilir; geç Ay safhasında Robot Mk II son üç şemayı açar. Reaktör yuvalarında yakıt/soğutma dengesi kurulur.
- Her gün üç değişen hedef ve her hafta bir ödüllü kilometre taşı; kuyuda ödülü alınmayı bekleyen yedi rastgele olay bulunur.
- 112 özgün ana görev; tüccar teklifleri, temel/altın/derin sandıklar, geliştirilebilir toplayıcı, kuyruklu sıkıştırıcı, katman rezonansı, bilimsel kazı, beş mücevher tarifi, altı Dünya bossu ve üçer Ay/Titan muhafızı, ayrıca kalıcı çekirdek döngüsü bulunur.
- Kalıntılar üç yuvaya kadar kuşanılır ve kazı, satış, kapasite, görev, sefer, rezonans ve boss hesaplarını etkiler.
- Bilim insanları kendi nitelik ve seviyeleriyle seçilip keşfe gönderilir. Yaralanınca süreli dinlenir; ikinci yaralanma ölüme yol açar ve nadir canlandırma mührüyle geri döner.
- Sekiz farklı özel madenci yeteneği, katta elle yerleştirme veya beş dakikalık gezici çalışma ve hurdayla seviye geliştirme sunar. Keşif dronlarının özgün hareketli sprite atlası mağara seferlerinde kullanılır.

## Uygulama yapısı

- `lib/domain/models/`: kayıt edilebilir oyun durumu, mineral ve görev kataloğu.
- `lib/domain/simulation/game_engine.dart`: zamandan bağımsız üretim, kazı, ekonomi, sefer, boss ve kilometre taşı kuralları.
- `lib/app/game_controller.dart`: çevrimdışı ilerleme, otomatik kayıt ve arayüz eylemleri.
- `lib/data/`: yerel JSON ve web kayıt adaptörleri.
- `lib/ui/`: geniş ve dar ekran oyun yerleşimi, bina panelleri ve sprite atlas çizimi.
- `assets/packs/`: özgün karakter, bina, cevher, biyom, kuyu, mağara ve boss atlasları; panorama ve doku varlıkları.
