# Taşın Altı — Sanat Kılavuzu

## Görsel yön

Özgün, ayrıntılı el boyaması-piksel arası sanat; sıcak endüstriyel maden ile soğuk, yabancı jeoloji arasında kontrollü renk geçişi. Yandan kesit/ortografik okuma kullan. Sprite'lar belirgin piksel kenarlı, geniş panoramalar dokulu boyama hissinde olabilir; kontur, ışık, ölçek ve palet ortak kalır. Parlak neon, emoji, fotogerçekçi 3B, rastgele gradyan ve birbirinden kopuk sprite stilleri kullanılmaz.

## Kamera ve katmanlar

- Telefon kadrajı yalnızca portre yönde oynanır. Dikey katman, yüzey karakolu ve kuyu aynı ekranda okunaklı kalır.
- Saha sahnesinde yüzey, kuyu/asma kafes, kaya duvarı, yatay galeri, cevher, karakter/makine, ışık ve HUD ayrı katmanlardır.
- Maden zemini/duvarı oyun alanının sınırları içinde kırpılır. Kuyu çizgisi yüzey asansörü ile aynı merkez eksenini korur.
- Karakter ve makineler galeri zeminine oturur. Bilerek uçan dron dışında hiçbir karakter boşlukta yüzmez.
- Cevher damarları kaya duvarına gömülü görünür; boşlukların ortasında bağımsız sprite olarak durmaz.
- Ekran dışı katlar matematiksel olarak simüle edilir; yalnızca görünür katlar çizilir.

## Renk paleti

| Rol | Renk |
|---|---|
| Ana arka plan / `ink` | `#071B23` |
| Panel / `panel` | `#0C2632` |
| Yükseltilmiş yüzey | `#123543` |
| Kaya | `#3A3534` |
| Bakır çerçeve | `#B86632` |
| Lamba ve ana eylem | `#F0A52E` |
| Açık metin | `#F4E8CC` |
| Yardımcı metin | `#A6B3B3` |
| Üretim | `#21C4B6` |
| Nadir damar | `#42D7E5` |
| Geç oyun kristali | `#AE62E8` |
| Tehlike | `#E8755B` |

Yeni dünya varlıkları kendi biome renklerine sahip olabilir; ışık ve siyah seviye ana oyunun paletinden kopmamalıdır.

## Malzeme ve çizgi

- Atlas sprite'larının oranı korunur ve nearest-neighbor filtresiyle çizilir; panorama dokusu `BoxFit.cover` ile kırpılır, ezilmez.
- Doku küçük kaya taneleri, çatlak ve kir gösterir; katman geometrisi veya galeri kirişinin yerine geçmez.
- Siluetlerde koyu kahverengi/teal dış hatlar, tek yönden gelen kehribar yerel ışık kullanılır.
- Cevher, sandık ve boss nadirliği renk yanında şekil, etiket veya pırıltı ritmiyle de anlatılır.
- Kaynak PNG'ler korunur; kırpılmış türevler ayrı dosyalarda kalır.

## Karakter ve makine ölçeği

- İnsan silueti madenci kaskı, okunaklı gövde ve koyu botlarla çizilir.
- Karakter genişliği aynı galerideki cevher düğümünün yaklaşık yarısıdır; makine ondan belirgin büyük olabilir.
- Sondaj burgusu kaya yüzeyine değer. Asansör rayı dikey ve kesintisiz kalır.
- Bir animasyon, varlığın siluetini ve piksel keskinliğini bozmamalıdır.

## Animasyon

- Madenci: kısa kazma darbesi, bekleme ve küçük gövde ağırlık değişimi.
- Kuyu madencisi: `miner-mining-cycle.png` içindeki sekiz hazırlık, kaldırma, darbe ve toparlanma karesi. Kareler arasında yalnızca poz değişir; bot tabanı tüm döngü boyunca galeri zeminine değmelidir.
- Taşıyıcı: yavaş iki adımlı salınım, az miktarda toz.
- Dron: küçük hover hareketi ve aralıklı tarama ışığı.
- Sondaj: düşük genlikli titreşim, seyrek kıvılcım/toz; sürekli yüksek yoğunlukta partikül yok.
- Sandık ve nadir buluntu: kısa görünme/bounce, ışık halkası; göz yormayan süre.
- Animasyonlar uygulama arka planda veya görünür alan dışında iken durur.

## Mevcut kaynaklar

`ASSET_CATALOG.md` atlas haritası ve kırpma kurallarının kaynağıdır. `assets/concepts/tasin-alti-main-screen.png` kompozisyon referansıdır; ekranın kendisi oyun içine düz resim olarak konulmaz. Ay ve Titan için `moon-outpost-panorama.png` ile `titan-outpost-panorama.png` özgün arka planları üretildi. Yeni dünya arka planları bu kılavuzdaki kontur, palet, ışık ve sahne oranına uymalıdır.

## Derin maden katları

Maden sahnesi, derinlikle açılan 1 km'lik oynanış katlarından kurulur ve liste görünümünde yalnızca ihtiyaç olduğunda çizilir. Duvar dokusu 100 km'de bir ana değişim yapar; ara renk varyantı 50 km'de değişir. Dünya, Ay ve Titan duvar dokuları ayrı dosyalardır. `depth-biomes-tileset.png` yalnızca görsel ilham kaynağıdır ve çalışma zamanında biyom üretmek için kullanılmaz.
