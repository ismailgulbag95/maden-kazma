# Taşın Altı — Teknik Mimari

## Katmanlar

| Katman | Sorumluluk | Mevcut konum |
|---|---|---|
| Domain state ve modeller | Kayıt edilebilir durum, kaynak, görev, başarı | `lib/domain/models/` |
| Simülasyon | Kazı, ekonomi, yükseltme, görev, sefer, boss ve milestone kuralları | `lib/domain/simulation/game_engine.dart` |
| Uygulama state'i | Yükleme, tick, eylem, bildirim, kayıt | `lib/app/game_controller.dart` |
| Kayıt adaptörleri | Mobil/masaüstü atomik JSON dosyası, web yerel saklama | `lib/data/` |
| Arayüz | Karakol, maden kesiti, HUD ve sistem panelleri | `lib/ui/` |
| Görsel katalog | Atlas kırpma, doku, animasyon ve palet | `lib/ui/widgets/`, `assets/packs/` |

## State akışı

UI olayı `GameController` üzerinden tek oyun eylemine dönüşür. `GameEngine` zaman adımı veya eylem sonucu state'i günceller. UI controller değişikliğinde yeniden çizilir. Görünmeyen katmanların üretimi matematiksel olmalı; her işçi için fizik simülasyonu çalıştırılmamalıdır.

## Kaydetme ve çevrimdışı ilerleme

- JSON state şema numarası içerir; yeni alanlar varsayılan değerle okunur, eski sürümler migrasyon noktasından geçirilir.
- Şema 17; dünya kayıtları, sondaj ucu/fan/motor seviyeleri, vardiya yöneticisi kademesi, reaktör yuva modülleri, Buff Lab etkileri ve güvenlik kapanma durumu dahil tüm oynanış state'ini saklar. Eksik yeni alanlar eski kayıtlarda varsayılanla başlar; önceki dünya, ekip, görev ve sefer alanları korunur. Şema 0–2 kayıtları eski derinliklerinden etkin dünyayı çıkarıp diğer dünyaları başlangıç derinliklerinde kurar.
- Dünya geçişi ortak yükseltme, ekip, kasa ve kalıntıları korur. Üretim yalnızca etkin dünyada işler; dünya değiştirildiğinde eski dünyanın kaynak durumu kaydedilir.
- Otomatik satış eşiği kayıtlı ayardır; satış kilidi ve kaynak rezervi hem elle toplu satışta hem otomatik satışta uygulanır. Sandık sıkıştırması tarih damgası ve kalan kuyrukla çevrimdışıyken ilerler.
- Üç günlük hedef yerel tarih değişiminde yenilenir. Haftalık kilometre taşı, alınan günlük ödül sayısını izler. Rastgele maden olayları yalnızca oyun açıkken doğar, kayda yazılır ve oyuncu ödülü alana kadar bekler.
- Sekiz yükseltme ailesi `UpgradeCatalog` içinde 100'er ayrı seviye kaydı taşır. Maden işçileri kazı, taşıma, tarama ve ayıklama görevlerine atanabilir; her görev oyun ekonomisinde ayrı etki üretir.
- Dosya kaydı önce geçici dosyayı tamamlar, önceki geçerli kaydı `.bak` dosyasında korur ve yeni kaydı devreye alır. İşlem yarıda kesilirse açılışta geçerli yedek denenir.
- Bozuk birincil kayıt yedeğe düşer. Yedek okunamazsa varsayılan state ile güvenli açılış ve kullanıcı bildirimi yapılır.
- Son aktif zaman kaydedilir; yöneticisiz üretim olmaz. Yönetici kademeleri çevrimdışı simülasyonu %25/%50/%100 hızla 12/24/48 saat uygular. Reaktör enerjisi ve süreli faaliyetler bu simülasyonda ilerler.
- Görev/sefer/sandık ödülü tekrar uygulanmaz. Negatif kaynak ve kapasite üstü üretim engellenir.

## Veri ve kurallar

Oynanış metin ve dengesi widget içinde tanımlanmaz. Kaynaklar, yükseltme maliyetleri, görevler, kilometre taşları, boss'lar ve dünyalar tekil, doğrulanabilir kataloglarda tutulur. Denge verisi ayrık yapılandırma dosyalarına taşınırken çalışma anı katalogları yükleme tamamlanmadan oyunu başlatmamalıdır.

## Performans

- Maden kesitinin çizimleri görünür alanla kırpılır; uzaktaki derinlikler için ayrı widget ağacı kurulmaz.
- Kayan sahne çizimleri kırpılır; atlas hücreleri doğru kaynak dikdörtgeninden nearest-neighbor ile alınır.
- Görünür olmayan animasyonlar durdurulur; oyun arka planda iken yalnızca state simülasyonu çalışır.
- En fazla 48 saatlik çevrimdışı hesap tek tek render/frame üretmez; oyun kurallarını saniyelik state adımlarında uygular.

## Doğrulama kapısı

Değişiklik sonrası `flutter analyze`, state/ekonomi/save testleri, Android debug APK derlemesi ve portre/yatay telefon boyutlarındaki widget testleri çalıştırılır. iOS derlemesi Xcode gerektirir; Windows ortamında alınamadığı durumda kod ve plist ayarları incelemeyle doğrulanır ve bu sınır teslim notunda belirtilir.
