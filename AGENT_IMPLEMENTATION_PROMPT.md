# Ajan Promptu — Taşın Altı

Bu belge Taşın Altı'nın işlevsel ve görsel kabul ölçütlerini tanımlar. Depoda çalışan bir Flutter uygulaması vardır; sonraki geliştirmeler mevcut sistemleri koruyup bu ölçütlere göre tamamlamalıdır.

## En güncel kullanıcı kararları

- Android ve iOS sürümleri yalnızca dikey/portre yönde çalışmalıdır. Bu karar, aşağıdaki ilk taslakta geçen 16:9 yatay masaüstü düzenini ve yatay telefon varyantını geçersiz kılar. Telefonda yüzey karakolu, maden ve eylemler dikey akışta üst üste yerleşir; yatay yön veya ayrı yatay telefon tasarımı eklenmez.
- Bilim insanı sefer başarısızlıkları süreli yaralanmaya yol açabilir. İyileşmiş aynı bilim insanı yeniden yaralanırsa ölür; nadir canlandırma eşyasıyla geri döndürülebilir.

## Rol ve hedef

Kıdemli bir Flutter oyun geliştiricisi ve sistem tasarımcısı gibi çalış. Proje, CrazyGames'teki Mr. Mine'dan alınan idle mining, derinlik ilerleyişi ve yönetim döngülerini temel alan; ancak kendi adı, dünyası, karakterleri, metinleri, görsel varlıkları, dengesi ve ek mekaniği bulunan **Taşın Altı** adlı özgün bir maden işletmesi oyunudur.

Depoda Flutter uygulaması, tasarım belgeleri ve görseller bulunur. Değişiklikten önce `README.md`, `SOURCES.md`, `DESIGN_OPTIONS.md`, `ASSET_CATALOG.md` ve `design-system/tasin-alti/MASTER.md` dosyalarını ve ilgili görselleri incele. Mevcut davranışı ve varlıkları koruyarak artımlı ilerle. Bu belgede yanıtı olmayan ve oyunun davranışını belirleyen bir belirsizlikte kullanıcıya sor; rutin uygulama seçimlerinde makul varsayımla ilerle.

## Kaynak oyundan alınacak kapsam

Ana oynanış kaynağı: <https://www.crazygames.com/game/mister-mine>. Ek kaynaklar `SOURCES.md` içinde listelenmiştir. İşlevsel tasarım örüntülerini eksiksiz ele al: elle tıklamalı kazı; otomatik madenci ekibi ve sondaj; kapasite dolduğunda üretimin durması; kaynak satışı ve ticaret; ekipman/yapı yükseltmeleri; derinlikle açılan içerik; sandıklar; 112'den fazla görev; başarımlar; özel yetenekli madenciler; bilim insanları ve kalıntı kazıları; mağara dronları; ticaret teklifleri; gizli karşılaşmalar; boss ve silah sistemi; cevher işleme; reaktör/buff; çoklu dünya ve geç oyun kalıcı ilerlemesi.

Bu kapsamı yeni adlar ve özgün içerikle uygula. Mr. Mine başlığını, logosunu, karakterlerini, oyun içi metinlerini, görev yazılarını veya oyuna özgü görselleri kopyalama. CrazyGames sayfasını oyunun içine gömme; bağlantıyı yalnızca tasarım kaynağı olarak kullan.

## Oyun döngüsü

Oyuncu ilk dakikada yüzey yerleşkesini görür, kaya/cevher damarına tıklayarak maden çıkarır, ilk madenciyi işe alır, madeni asansörle yüzeye taşır ve satış geliriyle sondajı yükseltir. Sonra oyuncu:

1. Elle maden damarlarını ve taş katmanlarını kazar; cevher düğümleri can/ilerleme göstergesiyle kırılır.
2. Madenciler, dronlar ve sondaj otomatik üretim sağlar. Oyuncu ekip kapasitesini ve uzmanlıklarını geliştirir.
3. Asansör/taşıma hızı ve ambar kapasitesi üretim sınırlarını belirler. Kargo yüzde 100 olduğunda üretim durur; ekran bunu açıkça belirtir.
4. Oyuncu kaynak satar, tüccarla takas eder veya yükseltme, üretim, görev ve araştırmada harcar. Satış seçenekleri tümünü sat, seçili sat ve belli rezervi sakla davranışlarını kapsar.
5. Daha güçlü ekipmanla derine iner. Katman, biyom, mineral, sandık, gizli olay, sefer, yapı ve boss kilometre taşları açılır.
6. Bilim insanı kazıları, mağara dronları, kalıntılar, görevler ve boss ganimetleri büyümeyi farklı yollardan hızlandırır.

Başlangıçta oyuncuyu beş adımlı kısa etkileşimli öğretici yönlendir: cevhere tıkla, madenci al, kaynak sat, sondaj yükselt ve bir yüzey binasını aç.

## Yüzey yerleşkesi ve bina etkileşimleri

Seçilen görsel `assets/concepts/tasin-alti-main-screen.png` içindedir. Üstte açık gökyüzü ve dağ silueti altında binaların bulunduğu bir maden üssü; ekranın çoğunda ise merkezi asansör şaftı boyunca uzanan katmanlı yeraltı görünür. Altı bina ayrı, okunaklı ve tıklanabilir hedef olarak çizilsin:

- **Asansör:** kat/derinlik seçimi; kabin hızı, taşıma kapasitesi ve çıkış önceliği yükseltmeleri.
- **Atölye:** sondaj gövdesi, motor, uç ve kargo modülü yükseltmeleri; plan/blueprint üretimi; ileride cevher/taş işleme ve boss silahları.
- **Ambar:** kaynak envanteri, toplam kapasite, kaynak kilidi, otomatik satış eşiği ve saklama rezervleri.
- **Ticaret:** seçerek satış, tümünü sat, gelen tüccar teklifleri, teklif geçmişi ve oyuncunun kabul/red kararı.
- **Araştırma:** bilim insanı kadrosu, kazı görevleri, kalıntı kataloğu, araştırma ağacı ve kalıntı bonuslarının etkinleştirilmesi.
- **Sefer Garajı:** mağara haritası, keşif dronu seçimi, rota/ödül tahmini, sefer başlatma, dönüş sayacı ve dron yükseltmeleri.

Görev panosu ve yükseltmeler sağ HUD kartlarından da erişilebilir olsun. Geç oyunda yeni yapı yuvaları veya görünür kilitli yapılar aç: taş/cevher işleme ocağı, mücevher dövme, reaktör ve derin çekirdek. Her kilitli hedef tıklandığında hangi kilometre taşında ve hangi kaynakla açılacağı anlatılsın.

Binalar dekor değildir. Fare üstüne gelince sıcak ışık/kenarlık vurgusu ve kısa ipucu göster; tıklama veya dokunma, ilgili sistemi açan işlevsel bir pencere/sayfa getirsin. Her ekranda gerçek state kullanan en az bir ana eylem olmalı: üret/sat/yükselt/ata/sefer başlat/ödül al vb. Kapatma ve geri dönüş mevcut oyun durumunu korusun. Klavye ile odak ve Enter/Space etkinleştirmeyi, ekran okuyucu etiketi ve en az 44 mantıksal piksel dokunma hedefini destekle.

## Derinlik, dünya ve kilometre taşı ilerlemesi

- Dikey maden alanı kaydırılabilir olsun; asansör şaftı yüzeyden etkin kazı seviyesine kesintisiz görsel bağ kursun. Sol şerit güncel derinliği, biyom eşiklerini ve açılmış kilometre taşlarını gösterir.
- Dünya/Ay/Titan benzeri üç büyük bölümlü kampanya kullan. Her dünyanın kendi katman paleti, kaynakları, sandıkları, sefer karşılaşmaları ve bossları olsun. Yeni dünya açılması mevcut yükseltmeleri silmesin; dünya değiştirmek ayrı, saklanan üretim akışı olarak çalışsın.
- Aşağıdaki eşikleri tek `MilestoneCatalog`/denge yapılandırmasında tut; kaynaklarla tutarlı birim seç ve HUD'da otomatik `m`/`km` gösterimi yap. Bunlar başlangıç temposu için yaklaşık hedeflerdir; kolayca dengelenebilir olsun: 10 km özel yetenekli madenciler; 15 km tüccar yapısı; 45 km mağara dronları; 50 km bilim insanı/kazı ve ilk gizli karşılaşma; 100 km sandık toplayıcı; 225 km onarılabilir eski robot; 300 km yeraltı yerleşkesi, petrol/işleme, silah ve canavarlar; 500 km civarı kaynak takası ve kalıcı derinlik çekirdeği; 700 km sandık sıkıştırıcı; 1.032 km civarı Ay bölümü; geç Ay/Titan eşiğinde reaktör ve buff laboratuvarı; yaklaşık 1.780 km civarı Titan bölümü.
- Her eşikte oyuncuya kısa bir keşif anı, ödül ve yeni eylem sun. Eşik açılışını yalnızca kilitli menü eklemekle sınırlama.
- Birbirinden farklı en az altı Dünya bossu ve daha derin dünyalara özgü ek boss karşılaşmaları kur. Boss kapışması kısa ve anlaşılır bir aktif mini sistem olsun: belirgin saldırı işareti, tıklanabilir/zamanlı zayıf nokta, ekibin/silahların katkısı ve net ödül. Yenilgi temel kayıt veya kaynakları sıfırlamasın.

## İçerik ve sistemler

- Veri odaklı en az 30 ana mineral ve 27 nadir izotop/özel kaynak türü tanımla. Her kaynağa kimlik, Türkçe ad, biyom/derinlik aralığı, bulunma ağırlığı, satış değeri ve tarif/quest kullanım alanı ver. Görsel atlas dışında tür başına yeni elle çizim gerekmiyorsa renk/varyant ikon eşlemesi kullan.
- Elle madencilik, otomatik işçi sayısı ve hızı, sondaj gücü/hızı, asansör hızı/kapasitesi ve ambar kapasitesini birbirinden ayır; birinin yükseltilmesi diğerlerini anlamsız bırakmasın.
- En az 100 veri tanımlı yükseltme seviyesi/blueprint seçeneği ver. Dört ana aile: sondaj, çalışanlar, asansör/taşıma ve depo; diğer yükseltmeler pazar, tarama, sandık ve seferleri desteklesin. Maliyet artışını merkezi ve sınırlı bir denge formülüyle üret; kaynak yetersizken butonda açık eksik listesi göster.
- En az 112 özgün, Türkçe, veri tanımlı ana görev ve ayrıca başarımlar oluştur. Görev türleri kaynak topla, belirli derinliğe ulaş, yapı aç, yükseltme al, mineral damarı bul, boss yen, sefer tamamla ve kalıntı edin olsun. Görevler önkoşullu zincirler kurup kaynağa uygun ödüller versin; aynı cümlenin sayısını değiştirerek görev üretme.
- Farklı ödül havuzları ve nadirlikleri olan temel, altın ve derin sandıklar; tıklayıp açma geri bildirimi; nadir yükseltme, para, mineral ve kalıntı ödülleri kur. İleride otomatik toplayıcı ve sandık yükseltici açılabilsin. Rastgele ödüller gerçek para/ödeme gerektirmesin.
- Özel rollere sahip madenciler ve az bulunan yetenekli uzmanlar ekle. Bilim insanları süreli kazıya atanabilsin ve farklı kalıntılar bulabilsin; kalıntılar koleksiyonda saklanıp kalıcı pasif etkiler sağlasın.
- Mağara seferlerinde 1+ dronu bir rotaya ata; derinlik, süre, kapasite ve keşif verimi kararlarını göster. Sefer çevrimdışı zamanda da ilerlesin; dönüşte bulunan kaynak ve olayları özetle.
- Tüccar belirli aralıklarla özgün kaynak takasları sunsun. Teklifleri zamanlı olabilir ancak ücretle atlatmayı gerektirmesin; teklif gelmesi küçük bir bildirim olarak gösterilsin.
- Geç oyunda mücevher dövme/işleme, basit boss silahları, canavar ganimeti, reaktör enerjisi ve süreli üretim buffları gerçek oyun state'iyle çalışsın. Kalıcı derinlik çekirdeği bir prestij sistemi olsun: oyuncuya sıfırlanacak/kalacak durum önceden gösterilsin ve onay almadan çalışmasın.
- Gizli karşılaşmalar, cevher damarı, eski robot, fosil odası ve kısa mağara olaylarını kilometre taşlarına veya kontrollü olasılığa bağla; görsel/oyunsal keşif hissi sunsun.

## Yeni mekanik: Katman Rezonansı

Taşın Altı'na özgü, oyunun ana döngüsünü bozmadan elle oynamaya anlam katan bir sistem uygula:

1. Her birkaç derinlik katmanında taranabilir bir mineral dizilimi/jeolojik örüntü oluşsun.
2. Tarayıcı ipucu dizinin tamamını veya bir bölümünü gösterir. Oyuncu doğru damarları sırayla tıklayarak kısa bir rezonans zinciri kurar.
3. Başarılı zincir sonraki birkaç dakika için belirli bir kaynağa üretim, satış değeri veya sandık şansı bonusu verir; bonus ekranda kalan süreyle görünür.
4. Yanlış tıklama yalnızca o denemeyi sıfırlar; ceza, kalıcı kaynak kaybı veya zorunlu bekleme yaratmaz.
5. Araştırma yükseltmeleri daha fazla ipucu, daha uzun kombinasyon ve seçimli bonus açar. Aynı dizi sürekli tekrarlanmasın; desenler derinlik seed'inden üretilebilsin.

Ek yenilikler: ekip üyelerine kazı/taşıma/tarama/ayıklama gibi rol ve öncelik atanabilsin; basınç/ısı sinyalleri yaklaşan kısa jeoloji olayını önceden bildirsin ve oyuncu güvenli havalandırma ile riskli hızlı çıkarım arasında seçim yapsın. Herhangi bir otomatik ayar oyuncunun kaynak kilidi ve saklama rezervine uysun.

## Mimari ve teknik uygulama

- Native Flutter/Dart uygulaması oluştur. Mevcut depo boş iskelettir; makul, bakımı kolay bir klasör yapısı kur.
- Ekran düzenini Flutter widget'larıyla, maden kesitini katmanlı bir `CustomPainter`/uygun 2D sahneyle kur. Oyun ekonomisi veya ilerleme kurallarını widget içine gömme.
- En az şu katmanları ayır: `domain/models` (oyun state'i ve veri modelleri), `domain/services` (kazı, ekonomi, yükseltme, görev, sefer, boss ve offline simülasyonu), `data` (denge kataloğu ve sürümlü kayıt deposu), `state` (tek merkezi `GameController`), `features` (hub, mine, yapı panelleri, görev/quest, sandık/boss/sefer ekranları), `shared` (temalar, ikonlar, ortak bileşenler).
- Tüm yükseltme maliyetleri, derinlik eşikleri ve kaynak tabloları merkezi kataloglarda olsun. Süre simülasyonu `DateTime` farkı/monotonik tick ile kontrollü çalışsın; uygulama arka plana gidince gereksiz timer biriktirmesin.
- Kayıt deposu sürümlü JSON kullanıp yerelde saklasın. Kaynak bakiyesi, envanter, derinlik, binalar, yükseltmeler, görevler, kalıntılar, seferler, boss ilerlemesi ve son aktif zaman kalıcı olsun. Açılışta sınırlı çevrimdışı ilerleme hesapla (varsayılan üst sınır 8 saat); kazanç dökümünü oyuncuya göster. Kayıt bozuksa yedek başlatma/varsayılan state ile kurtar; eski şema sürümü için migrasyon noktası bırak.
- Tek bir simülasyon fonksiyonu veya kontrollü servis tick'i üretim, taşıma ve kapasite kurallarını hesaplasın. Negatif bakiye, iki kez ödül verme, kapasiteyi aşan üretim ve tekrar teslim edilen görev ödülünü engelle.
- Uygulama internet olmadan oynanabilsin. Analitik, hesap, reklam, ödeme veya sunucu servisi ekleme.

## Görsel ve UX uygulaması

- `TAŞIN ALTI` başlığını, koyu teal panelleri, bakır/kehribar ışıkları, turkuaz/viyole kristalleri ve ayrıntılı piksel sanatını `assets/concepts/tasin-alti-main-screen.png` ile eşleştir.
- Ana ekranda: üstte para/kargo/üretim/basınç/derinlik bilgisi; yüzeyde binalar; ortada dikey asansör ve görünen yeraltı katmanları; solda derinlik kilometre taşı şeridi; sağda yükseltme ve görev kartları; altta kolay erişilen ana kazı/ekip/sefer eylemleri.
- Yüzey arka planında `assets/packs/surface-outpost-panorama.png` kullan. Panorama arka planda tam genişliğe yayılır; zemin şeridi, bina sprite'ları ve çalışanlar kendi render katmanlarında kalır. Asansör kulesini yatay ekran merkezine koy ve kuleyi maden kuyusunun tam x eksenine hizala. Diğer beş tıklanabilir binayı bu merkez çevresinde yatay dağıt. Altı yapının da tabanını aynı zemin çizgisine tam oturt; içeride farklı alfa boşluğu olan sprite'ları `Alignment.bottomCenter` ile hizala, havada görünmelerine izin verme.
- Yeraltında ortada gerçek, karanlık bir asansör boşluğu göster. `assets/packs/elevator-shaft-repeat.png` içindeki merkez raylı alanı dar kuyu sütununa kırpıp en-boy oranını koruyarak yalnızca dikey eksende ayna tekrarla; raylar yüzeydeki kuleyle kesintisiz aynı merkezde devam etsin. Bu tekrar eden kuyu arka planı sabit bir sahne katmanıdır; galeri zeminleri, taşıyıcılar ve varlıklar bunun üstüne ayrı çizilir. Kaynak atlas hücrelerini kuyu duvarı olarak tekrarlama.
- `assets/packs/mine-elevator-car.png` kabinini yüzeyin hemen altındaki ilk galeriye yerleştir. Kabin kuyu merkezinde, ilk platforma oturmuş ve duruyor olmalı. `assets/packs/deep-drill-rig.png` aşağı bakan burgulu sondaj ekibini en altta görünen aktif galeride çalıştır; burgusu dikey aşağı bakmalı ve kaya yüzeyine ulaşmalı. Derinlik/kat ilerledikçe ekip yeni aktif alt galeriye geçsin ve kazı animasyonunu kesmeden sürdürsün.
- Her görünen galeride açık bir yürünebilir taban, kiriş ve dikey destek çiz. Madenci/teknisyen sprite'larının bot/teker altı platform çizgisine değsin; karakterleri kat boşluklarında yüzdürme. Bilerek uçan dron dışındaki ekip üyeleri yalnızca galeriler üzerinde dursun. Yeraltı sahnesini kaynak oyundaki gibi katlara ayrılmış işletme kesiti olarak sun: yukarıda sabit kuyu/kabin, katlarda ekip ve cevher, en altta aktif aşağı kazı.
- `assets/packs/` içindeki bütün sprite atlaslarını ve `ASSET_CATALOG.md` eşlemesini incele. Bunları gerçek oyun varlıklarına dönüştür; atlası bütünüyle arka plan olarak yerleştirme. Gereken hücreleri alfa korunacak şekilde sprite'lara kırp ve `pubspec.yaml` içinde bildir. Sabit metni bitmap'e gömme; Flutter metni ile çiz. Kaynak tasarımlarındaki doku/ölçek farklılıklarını renk derecelendirme veya basit Flutter highlight/outline ile ortaklaştır.
- Kaya arka planı için `assets/packs/cave-wall-tile.png` opak 512 × 512 malzeme dokusunu `ImageShader` + `TileMode.mirror` ile kullan; shader'ı yalnızca mağara oyun alanında çiz ve `canvas.clipRect` ile sınırla. Tekrarlı malzeme küçük ayrıntı dokusudur; kaya geometrisi, yatay galeri/taşıyıcı, cevher damarı, ışık ve karakterler ayrı katmanlarda kalır.
- `depth-biomes-tileset.png` tileable bir duvar dokusu değildir: alfa boşluklu bağımsız blok illüstrasyonlarıdır. Bunları arka planı dolduracak şekilde tekrarlama veya en-boy oranını bozarak tüm sahneye germek. Atlas nesnelerini gerçek hücrelerinden çiz; pixel-art için `FilterQuality.none` kullan. Kaynak hücre sınırına filtre taşmasını önle, bütün özel ressamları kendi sahne dikdörtgenlerinde kırp.
- Tekrar deseni görünür oluyorsa doku parçasını sahneye göre büyüt, ayna tekrarı/offset kullan veya ayrı örnekler üret; kontrastı azaltıp üst üste alfa döşemekle çözmeye çalışma. Renkli biyom geçişini materyalin içine karıştırılmış rastgele kareler yerine kontrollü katman tonu, gömülü cevher kümeleri ve yerel ışıkla kur.
- Yerel Android/iOS oyun deneyimi yalnızca portre yönünde ve dikey akışta olsun. Üst kaynak şeridi, yüzey karakolu, maden sahnesi ve alt eylemler tek elle kaydırılabilen katmanlarda üst üste yerleşsin; yatay telefon varyantı sunma. En az 44dp dokunma alanı, ekran okuyucu adları ve masaüstü önizlemesinde klavye/mouse desteği sağla.
- Etkileşimde kısa taş kırılma, cevher pop, sayaç artışı, bina seçilme, kilit açılma ve sandık açılma animasyonları kullan. Hareketler az miktarda performanslı olsun; ağır parçacık yükü oluşturma. Ses varsa kapatılabilir olsun.
- Sıfır state, eğitim durumu, yeterli kaynak olmaması, envanter dolması, kilitli bina, aktif sefer, tamamlanan görev ve boss durumu için okunaklı arayüz tasarla. Tıklanabilir görünen hiçbir unsur işlevsiz kalmasın.

## Tamamlanma koşulları

- Uygulama bu depoda başlatılabilir bir Flutter projesi olarak kalsın; ana ekran mockup'a yakın görünsün ve statik görselden oluşmasın.
- Yeni oyun başlatıldığında oyuncu tıklayarak cevher çıkarsın; madenci işe alsın; satış/yükseltme yapsın; otomatik üretim çalışsın; kargo dolunca üretim durup satışla yeniden başlasın.
- Altı yüzey binasının her biri tıklanınca kendi işlevsel etkileşim ekranını açsın. Daha sonra açılan binalar da gerçek mekanik getirsin.
- Derinlik açılımı, farklı kaynaklar, sandık, quest zinciri, ticaret, bilim insanı kazısı, kalıntı, mağara dronu, özel madenci, boss/weapon, reaktör/buff ve kalıcı çekirdek sistemlerinin her biri oynanabilir işlev taşısın; yalnızca metinli örnek kart olmasın.
- Kaynak ve görev içerikleri veri odaklı olsun; tüm oynanış değerleri tekrar başlatmada ve çevrimdışı ilerleme dönüşünde tutarlı kalsın.
- Katman Rezonansı ve ek yeni mekanikler ana akışa bağlansın; oyuncuya kalıcı ceza yaratmasın.
- Boş `onPressed`, tamamlanmamış ekran, `TODO`, sahte sayaç veya yalnızca dekoratif bina bırakma. Kullanıcıya teslim notunda nelerin tamamlandığını, uygulamayı nasıl başlatacağını ve herhangi bir sınırlama kaldıysa ne olduğunu açıkla.

Yeni geliştirmeleri çalışan uygulamaya uygula; yalnızca bu yönergeyi tekrar özetleyip durma.
