# Taşın Altı — Ekonomi ve Denge

## Kaynaklar

- Ana mineraller ve nadir izotoplar derinlik tablosundan açılır.
- Her kaynakta kimlik, Türkçe ad, tür, derinlik, satış değeri, ağırlık, nadirlik ve tarif kullanımı bulunur.
- Üretim kaynak miktarı ve kargo yükünü birlikte günceller.
- Para bakiyesi negatif olamaz. Rezerv miktarı mevcut adedi aşamaz.
- Earth kaynak eşikleri Mr. Mine Wiki ilerleyişidir: Red Diamond 80 km, Blue Obsidian 93 km, Californium 305 km. Eski oyuna özel 100/150/200 km kaynak açılımı kaldırıldı.
- Einsteinyum/Fermiyum I–III yalnızca reaktör enerjisi harcanarak üretilir; normal tarama bunları düşürmez.

## Temel formüller

| Sistem | Kural |
|---|---|
| İlk vardiya | `GameState.newGame` yeni kaydı `0` kasa ve `0` madenciyle başlatır; ilk kaynak garantili yüzey kömür yığınıdır. İlk madenci 50 kasa tutar ve ilk satıştan sonra alınabilir. |
| İşçi işe alma | İlk on toplam ekip üyesinin maliyeti Mr. Mine tablosundaki sırayı izler: `50, 500, 2.000, 10.000, 25.000, 75.000, 150.000, 500.000, 3M, 10M`; bu projede onuncudan sonraki küresel ekip için `2×` büyüme kullanılır. |
| Sondaj geliştirme | Sondaj seviye 2 `150` kasa; seviye 3 `3.500` kasa + `20` kömür + `3` bakır + `1` gümüş. Kaynak tarifi rezervleri harcamaz. |
| Sondaj montajı | Uç `100 W`, fan `50 W`, motor `5 W` tabanından başlar. Güç `(fan + uç + motor tabanı) × motor çarpanı` ile bulunur; motor çarpanı seviye başına `1,5×` büyür. Oyundaki metre/sn hızına dönüşüm `1 + ln(güç / 155) × 0,30`, üst sınır `6×` olarak dengelenmiştir. |
| Erken blueprint fiyatları | 2–13. seviye uç/fan/motor para fiyatları Mr. Mine Wiki blueprint tablosuyla eşlenmiştir. Kaynak tarifleri aynı cevher sırasını korur, mevcut küçük ambar ölçeğine göre küçültülmüştür. |
| Montaj ilerleyişi | 6–9. seviye şemalar 50 km, 10–13. seviyeler 225 km, sandıktan çıkan 14–17. ve 21–23. seviye şemalar bu projede ilgili derinlikten sonra malzemeyle üretilir. Robot Mk II 24–26. seviyeleri 1.257 km'de; Robot Mk III 37–40. seviyeleri 2.039 km'de açar. Uç/fan/motor için 43 seviye bulunur. |
| Vardiya yöneticisi | Kademe I: 100 km'de 2 yapı malzemesi + 100 Kızıl Elmas; II: 150 km'de 10 yapı malzemesi + 10 Mavi Obsidyen; III: 300 km'de 50 yapı malzemesi + 25 Kaliforniyum + 50 Petrol. Her kademe kaynak kilidi ve rezervleri gözetir. |
| Petrol pompası | Yeraltı şehrinde başlangıç hızı 0,2 varil/sn, depo 100 varildir. Her yükseltme hızı ×1,6, depoyu +150 varil artırır; maliyet mevcut seviye ×10.000 kasa, üst sınır 50. Seviye 1 petrolü varil başına 500 kasaya satabilir veya 5 petrolü 2 yapı malzemesine işleyebilir. Depo Dünya envanterinde tutulur. |
| Yükseltme maliyeti | Sekiz katalog ailesinin her biri 100 seviyelidir; sondajın erken fiyat/tarif istisnaları ve diğer ailelerin büyümesi `UpgradeCatalog` içinde kayıtlıdır. |
| Kazı işçileri | Her açık kilometre kuyusunda kalan kazı ekibi kendi üretim yuvalarından kaynak toplar. Taban aralık 4 saniyedir; işçi eğitimi ve uzman bonusları aralığı kısaltır. |
| Cevher yığınları | Yeni kayıtta yalnızca öğretici kömür yığını garantilidir. Derinlik 100 m'yi geçince, kapasite dolu değilken drill ilerleyişinde metre başına `%0,045` olasılıkla yeni yığın doğar; konumu son 100 m içinde ve kaya cebinden seçilir. Mr. Mine'ın dünya ve ilk açılma eşikleri uygulanır; daha yeni mineraller daha yüksek ağırlık alır, wiki'deki Earth/Ay zengin bölgeleri ayrıca ağırlık kazanır. Normal yığın 5 vuruş sürer ve her vuruş sabit cevher verir. Açık katlar yığınla doldurulmaz. |
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

Wiki gözleminde işe alım maliyetleri ilk on işçi için sabit tabloyu izler. Sondaj seviye 2 yalnızca para ister; sonraki seviyeler para ve birden çok cevher gerektirir. Bu oyunda kaynak tarifleri küçük başlangıç ambarına ölçeklenmiştir. Yığınların beş vuruş ve olasılıklı doğma davranışı kaynak sistemi izler; `%0,045` metre başı olasılık bu projede daha seyrek tıklanabilir damar üretmek için seçilmiştir.

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
