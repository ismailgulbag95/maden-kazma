# Taşın Altı — Ekonomi ve Denge

## Kaynaklar

- Ana mineraller ve nadir izotoplar derinlik tablosundan açılır.
- Her kaynakta kimlik, Türkçe ad, tür, derinlik, satış değeri, ağırlık, nadirlik ve tarif kullanımı bulunur.
- Üretim kaynak miktarı ve kargo yükünü birlikte günceller.
- Para bakiyesi negatif olamaz. Rezerv miktarı mevcut adedi aşamaz.
- Kızıl Elmas, Mavi Obsidyen ve Kaliforniyum sırasıyla 100, 150 ve 200 km'de açılır; satış ve yönetici geliştirmelerinde kullanılır.
- Einsteinyum/Fermiyum I–III yalnızca reaktör enerjisi harcanarak üretilir; normal tarama bunları düşürmez.

## Temel formüller

| Sistem | Kural |
|---|---|
| İlk vardiya | Yeni kayıt `0` kasa ve `0` madenciyle başlar; ilk işe alım için en az bir kaynak satışı gerekir. |
| İşçi işe alma | İlk madenci `50` kasa; ikinci `500` kasa; sonraki alımlar `round(500 × 1,43^(işçi sayısı − 1))` kasa. |
| Sondaj geliştirme | Sondaj seviye 2 `150` kasa; seviye 3 `3.500` kasa + `20` kömür + `3` bakır + `1` gümüş. Kaynak tarifi rezervleri harcamaz. |
| Sondaj montajı | Uç `100 W`, fan `50 W`, motor `5 W` tabanından başlar. Güç `(fan + uç) × motor çarpanı + motor taban gücü × motor çarpanı` ile bulunur; parça gücü toplam sondaj hızına en çok `6×` katkı verir. Parça başı maliyetler 250/150/500 kasa tabanından ve 3,0/2,8/3,5 büyüme oranından hesaplanır. |
| Mk II şemaları | Her parçada 24–26. seviyeler 1.257 km'de açılır ve sırasıyla Helyum Cevheri, Selenit ve yapı malzemesi ister. |
| Vardiya yöneticisi | Kademe I: 100 km'de 2 yapı malzemesi + 100 Kızıl Elmas; II: 150 km'de 10 yapı malzemesi + 10 Mavi Obsidyen; III: 300 km'de 50 yapı malzemesi + 25 Kaliforniyum + 50 Petrol. Her kademe kaynak kilidi ve rezervleri gözetir. |
| Petrol pompası | Yeraltı şehrinde başlangıç hızı 0,2 varil/sn, depo 100 varildir. Her yükseltme hızı ×1,6, depoyu +150 varil artırır; maliyet mevcut seviye ×10.000 kasa, üst sınır 50. Seviye 1 petrolü varil başına 500 kasaya satabilir veya 5 petrolü 2 yapı malzemesine işleyebilir. Depo Dünya envanterinde tutulur. |
| Yükseltme maliyeti | Sekiz katalog ailesinin her biri 100 seviyelidir; sondajın erken fiyat/tarif istisnaları ve diğer ailelerin büyümesi `UpgradeCatalog` içinde kayıtlıdır. |
| Kazı işçileri | Her açık kilometre kuyusunda kalan kazı ekibi kendi üretim yuvalarından kaynak toplar. Taban aralık 4 saniyedir; işçi eğitimi ve uzman bonusları aralığı kısaltır. |
| Cevher yığınları | Yeni kayıtta yalnızca öğretici kömür yığını garantilidir. Derinlik 100 m'yi geçince, kapasite dolu değilken drill ilerleyişiyle olasılıklı yeni yığın doğar; konumu son 100 m içinde ve 1–9 kaya cebinden seçilir. Kaynağı o derinlikte açılmış mineraller belirler; daha yeni açılmış mineraller daha yüksek ağırlık alır. Normal yığın 5 vuruş sürer ve her vuruş sabit bir cevher payı verir. Açık katlar yığınlarla önceden doldurulmaz. |
| Taşıma ekibi | Her taşıyıcı etkin ambar kapasitesine %4 ekler. |
| Tarama ekibi | Her tarayıcı izotop olasılığına 4/1000 ve sandık bulma ihtimaline ek katkı verir. |
| Ayıklama ekibi | Her ayıklayıcı kaynak satışına %2 ekler; toplam rol bonusu en fazla %100'dür. |
| Ekip önceliği | 1–4 sıralaması; yeni görev ataması daha düşük öncelikli rolden bir madenci alır. |
| Uzman maliyeti | `round(420 × 1,70^aynı roldeki uzman sayısı)` kasa |
| Kargo doluluğu | `Σ(kaynak adedi × kaynak ağırlığı) / etkin kapasite` |
| Etkin kapasite | `temel kapasite × (1 + taşıyıcı × 0,04) × kalıntı bonusu × mücevher bonusu` |
| Rezerv dışı satış | `satılan adet × birim değer × satış çarpanı`; kalıntı, yakut ve ayıklayıcı katkıları çarpılır |
| Kısmi satış | Seçilen %10, %25 veya %50; kilitli ve rezerve kaynaklar satış dışı |
| Otomatik satış | Ayarlanan kargo eşiğinin üstündeki farkı en ucuz açık cevherlerden satar; kilit ve rezervi korur |
| Sandık toplayıcı | Her 30 dakikada bir temel sandık; depo başlangıçta 5 sandık, yükseltmeyle büyür |
| Sandık sıkıştırıcı | Kademe 1'de 15 temel → 1 altın ve 6 altın → 1 derin; oranlar 6:1 ve 3:1'e kadar gelişir. Süre, hız ve kuyruk yuvası da yükselir. |
| Çevrimdışı vardiya | Yönetici yokken çevrimdışı üretim olmaz. Kademeler %25/12 saat, %50/24 saat ve %100/48 saat üretim sağlar. |
| Reaktör dengesi | Toplam yakıt/nötron ısısı soğutma kapasitesini aşamaz. Aşılırsa üretim kapanır; denge kurulunca oyuncu yeniden başlatır. Izgara 9/15/25/45/81 yuvaya çıkar. Kademe 2–5, yapı malzemesi, izotop ve 20 bin–1,5 milyon enerji ister. |
| İzotop sentezi | E1/E2/E3 ve F1/F2/F3 üretimi 25/75/180/150/140/320 enerji harcar; gereken derinlik ve ambar boşluğu yoksa enerji düşmez. |
| Buff laboratuvarı | Aşırı yük sondajı 2×, kuantum rezonansı kazı cevherini 3×, dron kalkanı mağara tehlike hasarını engeller. Etkiler 10/15/8 enerji/sn tüketir ve enerji bitince kapanır. |
| Mağara tehlikeleri | Kaya bloğu bir ek yakıtla delinir; çamur yer dronunun adım yakıtını iki katına çıkarır; radyasyon tüm dronlara hasar verir; 300 km'den sonra görülen lav yalnızca yer dronuna hasar verir. Dron kalkanı radyasyon, lav ve çöken tünel hasarını engeller. |
| Geçici rezonans | Başarılı dizi sonrası 5 dakika; `relic_7` ile +1 dakika |
| Günlük hedef | Her yerel günde seçilen 3 hedeften her biri 220–350 kasa verir; ilerleme olay/eylem türü başına kaydedilir |
| Haftalık kilometre taşı | 12 günlük hedef ödülü alındığında 3.500 kasa + 1 çekirdek parçası verir |
| Rastgele maden olayı | İlk olay 2 dakika sonra; sonraki olaylar 150–300 saniye içinde gelir ve ödül derinlikle ölçeklenir |

Başlangıç üretimi, yükseltmeler ve fiyatlar denge verisi olarak tutulur. Büyük yükseltmeler küçük artışları kesintiye uğratmamalı; yeni ekipman, dünya ve kalıcı çekirdek hissedilir güç sıçraması vermelidir.

Referans gözleminde ilk işçi 50 kasa, ikinci 500 kasa; sondaj seviye 2 ise yalnızca para istiyordu. Sonraki sondaj seviyesi para ve birden çok cevher istiyor. Bu oyunda ilk drill yükseltmesinin erken satın alınabilir kalması ve sonraki seviyede satışla geliştirme arasında seçim doğması korunur; çok-kaynaklı tarif küçük başlangıç ambarına ölçeklenmiştir. Yığınların beş vuruş ve olasılıklı doğma davranışı referans gözlemine dayanır; metrede %1 doğma şansı denge için bu projede seçilmiş ayardır.

## Kapasite kuralları

1. Kazı ve otomatik üretim sadece kalan ağırlık kapasitesinin alabileceği tam kaynak adedini ekler.
2. Kapasite dolunca sondaj ve normal madencilik durur; derinlik üretimi ilerlemez.
3. Sandık, sefer ve bilimsel kazı ödülü kapasiteyi aşmaz. Sığmayan ganimet alınmayı bekler ve UI bunu gösterir.
4. Elle ve otomatik satış/takas kilitli veya rezerve kaynakları harcamaz.
5. Ambar yükseltmesi kapasiteyi artırır; asansör yükseltmesi taşıma hızını/kapasitesini ayrı geliştirir.
6. Yığın hasarı kaynak türü başına değil, benzersiz kuyu/yığın kimliğiyle kaydedilir. Her başarılı vuruş kapasiteye sığan vuruş payını verir; son vuruşta yığın sahneden kaybolur.
7. Bir vuruşun cevheri kalan ambar boşluğuna sığmıyorsa hasar ve ödül verilmez. Oyuncu cevher satıp yer açtıktan sonra aynı yığına vurmaya devam edebilir.
8. Eski `oreVeinDamage` kayıt alanı yeni yığınlara uygulanmaz; eski kayıtlar yüklenir ve yeni yığın konum/cevher/hasarları ayrı kaydedilir.

## Rastgele ödül güvenliği

Sandık ve keşif ganimeti yalnızca oyun içi kaynak verir. Ödül ağırlıkları ve nadirlikleri veri tabanlıdır. Ödül state'e bir kez uygulanır; ekranı kapatmak/yenilemek ikinci kez ödül vermez. Rastgele sonuçlar gerçek para veya ödeme içermez.

## Geçici etkiler ve çekirdek

Süreli buff zamanları kayıt edilir ve uygulama kapalıyken gerçek saat ile ilerler. Buff Laboratuvarı etkileri açık kaldıkları her saniye enerji tüketir. Basıncı boşaltma, reaktör enerjisi üretme ve rezonans ayrı kaynak/etki kanallarına sahiptir. Çekirdek fedası öncesi kaybolan kaynak ve korunacak kalıcı state ekranda listelenir; onay sonrasında ödül en az bir parça olur.

## Denge denetimleri

- Üretim hiçbir tick'te etkin kargoyu aşmamalı.
- Satış ve tarif sonrası adetler sıfırın altına düşmemeli.
- Tüm başlangıç görevleri oynanışla erişilebilir olmalı.
- Yeni dünya açmak önceki dünyadaki kaynakları veya kayıtlı yükseltmeleri silmemeli.
- Çevrimdışı hesap yönetici kademesinin yüzde ve 12/24/48 saat sınırında aynı kaynak/kapasite kurallarına uymalı.
