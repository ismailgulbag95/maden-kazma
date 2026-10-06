# Taşın Altı — Oyun Tasarımı

## Ürün hedefi

Taşın Altı, oyuncunun bir maden karakolunu yönetip giderek daha derin jeolojik katmanları açtığı özgün bir idle keşif oyunudur. İlerleme yalnızca para ve sayılardan oluşmaz: derinlik yeni kaynak, ortam, karşılaşma, iş ve karar açar. İlham alınan tür örüntüleri korunur; Mr. Mine'ın adı, karakteri, dili, görsel varlığı ve özel dengesi kullanılmaz.

## Oyuncu ve cihaz

- Birincil hedef Android ve iOS telefonlardır.
- Telefon arayüzü yalnızca portre yönde çalışır ve tek elle, başparmak erişiminde kullanılacak biçimde düzenlenir.
- Oyun Türkçe, çevrimdışı ve hesap/reklam/ödeme bağımlılığı olmadan çalışır.
- Büyük ekran Flutter hedefleri derleme ve tasarım önizlemesi için kullanılabilir; mobil yerleşimin davranış sözleşmesini değiştirmez.

## Ana döngü

1. Yeni vardiya sıfır kasa ve işe alınmış işçi olmadan başlar. Oyuncu yüzeyde çıkan ilk kömür yığınına birkaç kez tıklar; her başarılı vuruş kaynak verir, hasar görünür ve tükenen yığın sahneden kaybolur.
2. Oyuncu cevheri satar ve ilk madenciyi işe alır. İlk madenci saniyede bir kaynak üretmez; her açık 1 km kuyuda kendi vardiya yuvasında düzenli kaynak toplar.
3. Açık kuyuların üretimi tek ambarda birleşir. Ambar dolunca işçiler ve sondaj bekler; satış yeniden yer açar.
4. Oyuncu gelirini işçi sayısı ve sondaj geliştirmeleri arasında paylaştırır. İleri sondaj şemaları kasa yanında cevher de ister.
5. KAZI eylemi derinliği ilerletir; her 1 km eşiğinde yeni bir kuyu satırı ve işçi yuvaları görünür. Derinlik 100 m'yi geçince biyomuna uygun minerallerden rastgele yığınlar belirir; metre başına olasılık %0,4'tür ve bir katta aynı anda en fazla dört yığın bulunur. Satırlar açılırken topluca doldurulmaz.
6. Oyuncu sandık, rezonans, sefer, kalıntı ve muhafız gibi etkin hedefleri değerlendirir.

Idle üretim temel ilerlemeyi sağlar. Etkin oyuncu sahadaki yığınlara vurarak her seferinde cevher alır, KAZI ile kuyuyu ilerletir ve satış/yükseltme kararlarını verir. İlk yüzey kömürü öğretici amaçla garantilidir. Sonraki yığınlar derinlik ilerledikçe olasılıkla, son 100 m içindeki uygun katta ve rastgele bir kaya cebinde belirir; derinlikte açılan yeni mineraller daha sık seçilir. Normal yığın beş başarılı vuruşta kırılır, her vuruşta pay verir. Yığınların konumu, doğduğu derinlik, cevheri ve hasarı kayıtla korunur; tükenen yığınlar sahneden silinir.

Her yerel gün üç farklı, ödüllü hedef; her pazartesi bir haftalık kilometre taşı sunulur. Kuyuda ortalama 2,5–5 dakikada bir altına hücum, göçük tünel, zengin damar, kayıp kâşif, gezgin tüccar, kadim oda veya yaratık yuvası olayı belirir. Olay çevrimdışı vardiyada oluşmaz; oyuncu ödülü alana kadar görünür kalır.

Atölyedeki işçiler kazı, taşıma, tarama ve ayıklama görevlerine dağıtılabilir. Dört görev için 1–4 öncelik sırası, yeni atama sırasında hangi düşük öncelikli işten çalışan alınacağını belirler. Yükseltme kataloğunda sekiz aile ve aile başına 100 seviye vardır.

Bilim insanlarının nadirliği, seviyesi ve bir özel niteliği başarı olasılığını ve süreyi etkiler. Derinlik açıldıkça kısa ve uzun keşif seferleri seçilir. Başarısız sefer yaralanmaya yol açabilir; aynı bilim insanının ikinci yaralanması ölümcüldür. İyileşen bilim insanı yeniden göreve dönebilir; nadir canlandırma mührü ölen bir kişiyi geri getirir.

Bilim ekibinin portreleri ve sekiz özel madencinin yetenek portreleri özgün, alfa kanallı atlaslardan çizilir. Kartlardaki yumuşak hareket, nadirlik ışığı ve durum rozeti portreleri arayüzde canlı tutar.

Özel madenciler sekiz yetenekten birini taşır; nadirlik ve seviye etkilerini büyütür. Oyuncu açık dünya ve katlardaki yerini seçebilir veya beş dakikada bir kat değiştirmesine izin verebilir. Fazla kopyalar hurdaya dönüşür; hurda seviye yükseltmede kullanılır.

## Sistem ilkeleri

- Derinlik içerik açar; yeni dünyalar önceki kayıt ve kalıcı yükseltmeleri silmez.
- Kaynak kapasitesi gerçek bir sınırdır. Hiçbir ödül veya üretim kayıtlı kapasiteyi aşırmaz; taşan ganimet beklemede kalır ya da oyuncuya açıkça bildirilir.
- Rezerv kaynaklar toplu satış ve takasta korunur.
- Otomatik satış ayarlara göre sessizce çalışır; satış ve aç/kapat bildirimleri oyun eylem çubuğunu kapatmaz.
- Geçici yanlış karar kalıcı kaynak kaybı yaratmaz. Rezonans hatası yalnızca mevcut diziyi sıfırlar.
- Her bina gerçek oyun durumunu okuyup en az bir sonuç doğuran eylem sunar.
- Prestij sıfırlayacağı ve koruyacağı durumu oyuncuya önceden gösterir; onaysız uygulanmaz.

## İçerik katmanları

| Katman | Ana deneyim |
|---|---|
| İlk vardiya | Garantili kömür yığını, derinlikle gelen rastgele cevher yığınları, vuruş başına ödül, satış, ilk madenci ve sondaj yatırımı |
| İlk kilometre taşları | Sondaj, yeni cevher, uzman ve tüccar |
| Keşif | Rota ve dron seçimi, bilim insanı kazısı, rezonans, kalıntılar ve mücevher dövme |
| Yeraltı yerleşkesi | Geliştirilebilir petrol pompası, petrol satışı/işleme, döküm, silah ve muhafızlar |
| Günlük vardiyalar | Üç dönüşümlü hedef, haftalık ödül ve kısa maden olayları |
| Derinlik çekirdeği | Kaynak fedası ve kalıcı meta ilerleme |
| Yeni dünyalar | Ay ve Titan'a özgü ortamlar, kaynaklar ve muhafızlar |

Atölyede sondaj ucu, fan ve motor ayrı seviyelerde gelişir; geç Ay safhasında Robot Mk II üst şemaları açar. Reaktör oyuncunun modül yerleşimine göre ısı dengesi kurar ve ileri izotop üretir. Buff Laboratuvarı üç sürekli etkiyi reaktör enerjisi karşılığında çalıştırır. Yönetici yokken çevrimdışı üretim olmaz; üç kademe %25, %50 ve %100 hızla 12, 24 ve 48 saatlik vardiya sağlar.

Tam kilometre taşları ve hedeflenen açılma ritmi [PROGRESSION.md](PROGRESSION.md) içindedir. Ekonomi denklemleri [ECONOMY.md](ECONOMY.md) içindedir.

## Dikey dilim kabul ölçütü

- Yeni kayıtta oyuncu ilk 30 saniyede kazı, satış ve yükseltme sırasını anlayabilmeli.
- İlk görevler yığını kırma, cevheri satma, ilk işçiyi işe alma ve sondajı geliştirme sırasını eylem içinde öğretmeli.
- 20 katmanlık ilk bölümde en az dört kaynak, sınırlı ambar, yükseltilebilir sondaj, sandık, görev ve yeni bir aktif etkileşim olmalı.
- Kaydet/yükle, yönetici kademesine bağlı %25/%50/%100 çevrimdışı üretim, 12/24/48 saatlik sınırlar ve bozuk kayıt yedeği çalışmalı.
- Android/iOS portre ekranlarında kritik kontroller tek elle erişilebilir olmalı.

## Kaynak ve kapsam disiplini

Özgün ana ekran referansı `assets/concepts/tasin-alti-main-screen.png`; seçilen sanat yönü piksel sanatı A'dır. Uygulama içindeki görsel/oynanış gereksinimleri `AGENT_IMPLEMENTATION_PROMPT.md` ve [CONTENT_UNLOCKS.md](CONTENT_UNLOCKS.md) ile eşlenir. Tasarım hedefi, çalışan davranışla doğrulanmadan tamamlandı sayılmaz.
