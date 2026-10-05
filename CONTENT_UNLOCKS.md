# Taşın Altı — İçerik ve Kilit Açılımları

Derinlik eşikleri metre cinsindedir. Eşikler tek katalogdan okunur; UI içindeki metin bu tablodan türetilir.

| Derinlik | Kilit / olay | Oyuncuya açılan eylem |
|---:|---|---|
| 0 m | İlk vardiya | Garantili kömür yığınını beş kez elle vur, cevheri sat, ilk 50 kasalık madenciyi işe al |
| 100 m'den sonra | Olasılıklı cevher doğumu | Derinlikte açılmış minerallerden biri, son 100 m içinde ve rastgele kaya cebinde belirir; her başarılı vuruş cevher verir, beşinci vuruşta tükenir |
| Her 1.000 m | Yeni kuyu satırı | Derinlik eşiğinde yeni satır ve işçi yuvaları açılır; katlar baştan yığınla doldurulmaz |
| 10.000 m | Uzman madenciler | Jeolog, sondaj mühendisi, kâşif veya muhafız uzmanı seç |
| 15.000 m | Tüccar | Cevher takası yap |
| 45.000 m | Mağara | Bir veya daha fazla dron ata; haritalı, güvenli ya da derin rotadan birini seç; kaya, çamur ve radyasyon tehlikelerini aş |
| 50.000 m | Bilim ekibi ve gizli frekans | Bilim insanı ata, kalıntı kazısı başlat |
| 100.000 m | Sandık toplayıcı ve yönetici I | Sandık topla; Kızıl Elmas ve yapı malzemesiyle çevrimdışı vardiyayı 12 saate çıkar |
| 150.000 m | Mavi Obsidyen ve yönetici II | Kaynağı saklayıp çevrimdışı vardiyayı 24 saate çıkar |
| 200.000 m | Kaliforniyum | Nadir damarı sat veya daha ileri yönetici kademesi için ayır |
| 225.000 m | Eski sondaj robotu | Robot parçası ve yapı malzemesi onarımı |
| 300.000 m | Yeraltı yerleşkesi | Petrol pompasını geliştir; depodaki petrolü sat ya da yapı malzemesine işle; vardiya yöneticisi III'ü aç |
| 303.000 m | Mücevher ocağı | Beş tarif arasında 100 puan üretim iş yükü dağıt |
| 305.000 m | Yeraltı cephaneliği | Muhafız savaşları ve sondaj parçası ödülleri |
| 400.000 m | İlk Dünya muhafızı | Zayıf nokta açıp aktif saldırı yap |
| 501.000 m | Derin çekirdek | Bilim insanı veya kaynak fedası sonrası kalıcı parça kazan |
| 700.000 m | Sandık sıkıştırıcı | Düşük kalite sandıkları birleştir |
| 1.032.000 m | Ay | Farklı kaya paleti, kaynaklar ve muhafız |
| 1.047.000 m | Ay Ticaret İstasyonu | Ay kaynaklarında %25 daha yüksek takas getirisi |
| 1.133.000 m | Reaktör | Yakıt/soğutma ızgarasını yönet, enerji üret ve altı ileri izotopu sentezle |
| 1.135.000 m | Buff laboratuvarı | Süreli etki üret |
| 1.257.000 m | Sondaj Robotu Mk II | Sondaj ucu, fan ve motorun 24–26. şemalarını geliştir |
| 1.782.000 m | Titan | Buz katmanı, kaynaklar ve son muhafız |
| 1.814.000 m | Titan etki alanı | Metan ve hidrojen kaynakları açılır |
| 2.566.000 m | Titan son katmanı | Titan son derinlik başarımını aç |

Yöneticisiz çevrimdışı üretim yoktur. Yönetici kademeleri sırasıyla %25/12 saat, %50/24 saat ve %100/48 saat sağlar. Sondaj bileşenlerinin ilk 23 seviyesi temel atölye şemalarıdır; üst üç seviye Robot Mk II ve Ay malzemesi ister.

## Veri kuralları

- Mineral, izotop, görev, yükseltme, muhafız, dünya ve kilometre taşı kataloğu denge ayarına uygun olmalıdır.
- Sekiz yükseltme ailesinde 100'er seviye; maliyet, ad ve etki açıklamasıyla `UpgradeCatalog` içinde tanımlıdır.
- Kazı/taşıma/tarama/ayıklama ekip rolleri ve 1–4 öncelik sırası kayda yazılır; yeni atama en düşük öncelikli görevden çalışan alır.
- Yeni kaynak satırında kimlik, Türkçe ad, tür, alt/üst derinlik, satış değeri, ağırlık, rarity ve tarif kullanımı bulunur.
- Görevler anlam ve cümle bakımından birbirinden ayrılır. Yalnızca bir sayıyı değiştirerek kopyalanan görev kabul edilmez.
- Kilit açılması state'e tek kez yazılır. Eşik atlandığında aradaki tüm açılımlar sırayla uygulanır.
- Dünya değiştirme veya çekirdek yenileme açıkça anlatılmadan kaynak/durum silinmez.
