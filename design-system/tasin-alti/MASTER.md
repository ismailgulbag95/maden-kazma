# Taşın Altı — Görsel Sistem

Bu dosya seçilmiş oyun ekranını ve sprite paketlerini uygulama arayüzüne dönüştürür. Kaynak: `assets/concepts/tasin-alti-main-screen.png` ve `ASSET_CATALOG.md`. Piksel sanatı, yeraltı keşfi ve rahat okunur maden işletmesi UI'si ürünün görsel sözleşmesidir.

## Renk belirteçleri

| Belirteç | Renk | Kullanım |
|---|---|---|
| `ink` | `#071B23` | Ana arka plan |
| `panel` | `#0C2632` | HUD ve bina panelleri |
| `panelRaised` | `#123543` | Seçili/üst yüzey kartı |
| `rock` | `#3A3534` | Maden zemini, taş katmanları |
| `copper` | `#B86632` | Bakır çerçeve ve sıcak ikincil vurgu |
| `amber` | `#F0A52E` | Ana eylem, etkileşim vurgusu, lamba ışığı |
| `cream` | `#F4E8CC` | Başlık ve ana metin |
| `muted` | `#A6B3B3` | Yardımcı metin |
| `teal` | `#21C4B6` | Üretim/ilerleme göstergesi |
| `cyan` | `#42D7E5` | Nadir cevher ve tarama |
| `violet` | `#AE62E8` | Geç oyun kristalleri |
| `danger` | `#E8755B` | Yüksek basınç/tehlike |

## Tipografi ve simge kullanımı

- Ekran başlıklarında kalın, kısa ve piksel estetiğine yakışan büyük harfler kullan. Gövde metni, sayısal değer ve uzun Türkçe adlar yerel Material yazı tipinde kalmalı; dış font ağına bağımlılık ekleme.
- Bütün sayı alanlarında sabit genişlikli rakam seç. Değişen sayılar etiket genişliğini oynatmasın.
- Yapı, işçi, cevher ve eşya simgeleri `assets/packs/` sprite atlaslarından gelsin. Kayıt, ayar ve geri gibi genel kontroller Material ikonlarıyla çizilsin; emoji kullanma.
- Metin bitmap'e gömülmez. Kontrastlı metin Flutter üzerinden çizilir ve erişilebilir etiketi olan gerçek bir butonun yanında görünür.

## Yerleşim ve etkileşim

- Geniş ekranda 16:9 maden komuta görünümü: dar derinlik şeridi, merkezde yüzey yerleşkesi ve maden şaftı, sağda yükseltme/görev kartları, üstte kaynak göstergeleri, altta ana eylemler.
- Dar ekranda HUD yatay kaydırılabilir, bina sırası erişilebilir, yan kartlar sekme/alt sayfa biçimine dönüşür. Sabit alt eylem alanı safe area dışında kalmaz.
- Dört ve sekiz dp aralık ritmi kullan; kartlar arası hiyerarşi için 12/16/24 dp. Panel köşeleri 8–12 dp; çizgi/bakır çerçeve ince kalır.
- Tıklanabilir binalar hover/focus/pressed/disabled durumlarını açıkça gösterir. En az 48 dp hedef alanı, belirgin klavye odağı, kısa etiket ve semantik açıklama sağlar.
- Etkileşim hızlı, yerel ve anlamlıdır. Ekran hareketleri üretim/keşif odağını çalmaz; uygulama arka plandayken animasyon çalışmaz.

## Doku ve kaya katmanları

- Sürekli mağara duvarı için yalnızca opak, kenarları eşleşen `cave-wall-tile.png` malzemesini kullan. `ImageShader` ile tekrar et; `TileMode.mirror` dikişleri gizler ve doku ressamı kendi sahne dikdörtgenine `clipRect` uygular.
- `depth-biomes-tileset.png` bir materyal dokusu değildir. Hücreleri ayrı, alfa kenarlı kaya bloklarıdır; duvarı doldurmak için tekrarlanmaz. Tek blok, biyom kartı veya dekor olarak en-boy oranını koruyarak çizilir.
- Görsel katman sırası: koyu renk/ışık zemini → kaya malzemesi → derinliğe göre hafif biyom renk tonu → galeri kaya dudağı ve taşıyıcı kirişleri → cevher damarları/dekor → karakter ve etkileşim işaretleri. Arka plan dokusu zemin geometrisi yerine kullanılamaz.
- Pixel-art sprite'ları kaynak en-boy oranıyla ve `FilterQuality.none` ile çizilir. Materyal döşeme boyutu sabit dünya ölçüsünde kalır; görünüm alanına esnetilmez. Her özel ressam çizim yaptığı alanı kırpar; yüzey, HUD ve mağara birbirinin alanına taşmaz.
- Katman değiştikçe renk ve küçük taş ayrıntısı değişebilir; kaya tanelerinin boyutu, kontrastı ve perspektifi sabit kalır. Büyük cevher kümeleri dokunun içine gömülmüş ayrı sahne öğeleridir.

## Kalite ve performans

- Ana metin kontrastını en az 4.5:1 hedefle. Durumu yalnızca renkle anlatma; ad ve simgeyi de göster.
- Geniş neon parıltı, ağır bulanıklık veya tüm sahneyi animasyonla yeniden boyama kullanma.
- Sprite'lar nearest-neighbor filtresiyle çizilir; kaynak PNG'ler korunur. Aynı atlas tek sefer yüklenip paylaşılır.
- Oyun sahnesinin zaman adımları state'i günceller; `CustomPainter` yalnızca paint aşamasında çizer. Etkileşimler semantik Flutter butonlarıyla erişilebilir kalır.

## Arama notu

Yerel UI/UX veritabanı piksel sanat stilini eşleştirdi, fakat döndürdüğü neon kırmızı/mavi palet ve hero-odaklı sayfa yapısı bu oyun ekranına uymadı. Renk, yoğunluk ve yerleşim kararı kullanıcı tarafından seçilen görsele dayalıdır. Flutter stack aramasında doğrulanabilen rehber typed route argument kullanımıdır; paneller enum/typed parametre üzerinden açılır.
