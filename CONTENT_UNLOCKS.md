# Taşın Altı — İçerik ve Kilit Açılımları

Derinlik eşikleri metre cinsindedir. Dünya, Ay ve Titan cevher açılımları Mr. Mine Wiki `Materials` tablosundaki ilerleyişi izler; kilometre başına kaya görünümü bu oyunun sanat düzenidir.

| Derinlik | Kilit / olay | Oyuncuya açılan eylem |
|---:|---|---|
| 5.000 m | İlk vardiya | Dört garantili kömür damarını beşer kez vur; cevheri satıp ilk madenciyi işe al |
| 100 m'den sonra | Olasılıklı cevher doğumu | Derinlikte açılmış minerallerden biri, son 100 m içinde ve rastgele kaya cebinde belirir; her başarılı vuruş cevher verir, beşinci vuruşta tükenir |
| Her 1.000 m | Yeni kuyu satırı | Derinlik eşiğinde yeni satır ve işçi yuvaları açılır; katlar baştan yığınla doldurulmaz |
| 10.000 m | Uzman madenciler | Jeolog, sondaj mühendisi, kâşif veya muhafız uzmanı seç |
| 15.000 m | Tüccar | Cevher takası yap |
| 45.000 m | Mağara | Bir veya daha fazla dron ata; haritalı, güvenli ya da derin rotadan birini seç; kaya, çamur ve radyasyon tehlikelerini aş |
| 50.000 m | Bilim ekibi ve gizli frekans | Bilim insanı ata, kalıntı kazısı başlat |
| 100.000 m | Sandık toplayıcı ve yönetici I | Sandık topla; Kızıl Elmas ve yapı malzemesiyle çevrimdışı vardiyayı 12 saate çıkar |
| 150.000 m | Yönetici II | Çevrimdışı vardiyayı 24 saate çıkar |
| 225.000 m | Eski sondaj robotu | Robot parçası ve yapı malzemesi onarımı |
| 300.000 m | Yeraltı yerleşkesi | Petrol pompasını geliştir; depodaki petrolü sat ya da yapı malzemesine işle; vardiya yöneticisi III'ü aç |
| 303.000 m | Mücevher ocağı | Beş tarif arasında 100 puan üretim iş yükü dağıt |
| 305.000 m | Kaliforniyum ve yeraltı cephaneliği | Nadir damarı işle; muhafız savaşlarına gir ve sondaj parçası kazan |
| 400.000 m | İlk Dünya muhafızı | Zayıf nokta açıp aktif saldırı yap |
| 501.000 m | Derin çekirdek | Bilim insanı veya kaynak fedası sonrası kalıcı parça kazan |
| 700.000 m | Sandık sıkıştırıcı | Düşük kalite sandıkları birleştir |
| 1.032.000 m | Ay | Farklı kaya paleti, kaynaklar ve muhafız |
| 1.047.000 m | Ay Ticaret İstasyonu | Ay kaynaklarında %25 daha yüksek takas getirisi |
| 1.133.000 m | Reaktör | Yakıt/soğutma ızgarasını yönet, enerji üret ve altı ileri izotopu sentezle |
| 1.135.000 m | Buff laboratuvarı | Süreli etki üret |
| 1.257.000 m | Sondaj Robotu Mk II | Sondaj ucu, fan ve motorun 24–26. şemalarını geliştir |
| 1.782.000 m | Ay kuyusunun sonu | Uzay geçiş katmanı başlar; Ay cevherleri sona erer |
| 1.814.000 m | Titan | Titan dünyası, ilk kalay damarı ve son muhafızlar |
| 1.829.000 m | Titan Ticaret İstasyonu | Titan kaynakları için takas bonusu açılır |
| 2.039.000 m | Sondaj Robotu Mk III | İleri Titan montaj şemaları açılır |
| 2.566.000 m | Titan son katmanı | Titan son derinlik başarımını aç |

Canlı yeni vardiya `GameState.newGame` ile 5 km'de, 0 kasa ve 0 madenciyle başlar; başlangıç katındaki garantili kömür damarları ilk satış ve işe alım için kullanılır, ilk madenci 50 kasaya alınır. İlk beş görev cevher çıkarma, satış, işe alım, sondaj yükseltmesi ve otomatik matkap ilerleyişini öğretir. Derinlik görevleri bu 5 km başlangıcına göre sayılır; eski kayıtların ilerleyişi korunur. İlk on madenci için işe alım maliyetleri kaynak tablosundaki sırayı izler; sonraki alımlarda bu projeye özgü maliyet eğrisi sürer. Yöneticisiz çevrimdışı üretim yoktur. Yönetici kademeleri sırasıyla %25/12 saat, %50/24 saat ve %100/48 saat sağlar. Sondaj ucu, fan ve motor 43. seviyeye kadar gelişir. 6–9. seviyeler 50 km, 10–13. seviyeler 225 km, sandık kaynağındaki 14–17. seviye şemalar bu projede 100 km eşiğinden sonra tarifle üretilebilir; 21–23. seviyeler Ay'da malzeme karşılığı açılır. Robot Mk II 24–26. seviyeleri 1.257 km'de; Robot Mk III 37–40. seviyeleri 2.039 km'de açar.

## Tıklanabilir cevher damarları ve katman görünümü

- Earth damarları kaynak eşiklerini izler: kömür 0 km; bakır 4; gümüş 13; altın 17; platin 21; elmas 30; koltan 45; painit 60; siyah opal 79; kızıl elmas 80; mavi obsidyen 93; kaliforniyum 305 km. Yeni kayıttaki garantili ilk yığın kömürdür. Önceki 0–10 ve 10–50 km bantları kaldırıldı; bu eski bantlarla uyuşmayan tükenmemiş kayıt damarları temizlenir.
- Yeni damar doğumu, sondaj ilerledikçe metre başına `%0,045` olasılıkla denenir. Damar, son 100 m içinden rastgele bir derinlik/kat seçer; eşikten sonra bu aralıkta eşik altı bir doğum noktası seçilirse eski kaynaklar da kısa süre daha çıkabilir. Her katta aynı anda en fazla dört tükenmemiş damar bulunur. İlk yüzey vardiyasına ayrıca beş vuruşluk garantili kömür damarı eklenir.
- Aday cevherler etkin dünya ve ilk açılma derinliğine göre seçilir. Yeni kaynaklar daha yüksek başlangıç ağırlığı alır; Earth ve Ay'ın Wiki'de tanımlı zengin aralık/eşiklerinde o kaynağın ağırlığı projeye özgü olarak dört katına çıkar. Titan için zenginlik aralığı tanımlanmadığından ek çarpan kullanılmaz.
- Dünya 1.000 km'de, Ay 1.782 km'de biter; 1.000–1.032 km ve 1.782–1.814 km aralıkları uzay geçişleridir. Titan 1.814 km'de başlar. Ay cevherleri: karbon 1.032, demir 1.041, alüminyum 1.042, magnezyum 1.125, titanyum 1.211, silisyum 1.333, prometyum 1.462, neodimyum 1.562, iterbiyum 1.605 km. Titan cevherleri: kalay 1.814, kükürt 1.854, lityum 1.878, manganez 2.015, cıva 2.142, nikel 2.242, aleksandrit 2.317, benitoit 2.414, kobalt 2.500 km.
- Görsel kat her 1.000 m'de bir tekrar eder. Her katta dört galeri, komşu katlar arasında da eşit 250 m görsel aralıkla hizalanır; duvar dokusu ardışık katlarda dünya koordinatına göre kesintisiz devam eder. Yeni kaya setine geçiş tam kat sınırında olur. Mevcut görsel çeşitler Earth taş/demir/kristal, Ay bazalt/kristal, Titan buz/kehribardır. Wiki dünya ve kaynak ilerleyişini tanımlar ama kilometre başına kaya çizimi takvimi vermez; bu doku sıralaması projeye ait görsel yorumdur.

## Veri kuralları

- Mineral, izotop, görev, yükseltme, muhafız, dünya ve kilometre taşı kataloğu denge ayarına uygun olmalıdır.
- Sekiz yükseltme ailesinde 100'er seviye; maliyet, ad ve etki açıklamasıyla `UpgradeCatalog` içinde tanımlıdır.
- Kazı/taşıma/tarama/ayıklama ekip rolleri ve 1–4 öncelik sırası kayda yazılır; yeni atama en düşük öncelikli görevden çalışan alır.
- Yeni kaynak satırında kimlik, Türkçe ad, tür, alt/üst derinlik, satış değeri, ağırlık, rarity ve tarif kullanımı bulunur.
- Görevler anlam ve cümle bakımından birbirinden ayrılır. Yalnızca bir sayıyı değiştirerek kopyalanan görev kabul edilmez.
- Kilit açılması state'e tek kez yazılır. Eşik atlandığında aradaki tüm açılımlar sırayla uygulanır.
- Dünya değiştirme veya çekirdek yenileme açıkça anlatılmadan kaynak/durum silinmez.
