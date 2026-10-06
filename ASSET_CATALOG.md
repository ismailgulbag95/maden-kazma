# Taşın Altı — Görsel Varlık Kataloğu

Seçilen ana ekran konsepti, PNG sprite atlasları, tekrarlanabilir materyaller ve sahne görselleri proje içine eklendi. Sprite atlasları/karakterler alfa kanallı tekil varlıklardır; mağara duvarı ve kuyu rayı farklı tekrar kurallarına sahiptir. Hücreleri uygulamadan önce görsel üzerinde inceleyin; sprite sınırlarını doku sınırlarıyla karıştırmayın. Oyun ekranı sanat yönetimi referansıdır; statik ekran resmi olarak uygulamaya yapıştırılmamalıdır.

## Oyun ekranı

| Dosya | Kullanım |
|---|---|
| [tasin-alti-main-screen.png](assets/concepts/tasin-alti-main-screen.png) | Seçilen piksel sanat stili, yüzey yerleşkesi, altı tıklanabilir yapı, HUD, derinlik şeridi ve yeraltı sahnesi için ana kompozisyon referansı. |
| [option-a-tasin-alti.png](assets/concepts/option-a-tasin-alti.png) | Bina yerleşkesinden önceki A yönü konsepti. |

## Görsel paketler

| Dosya | İçerik | Dosya türü / kullanım |
|---|---|---|
| [surface-buildings-sheet.png](assets/packs/surface-buildings-sheet.png) | Asansör kulesi, atölye, ambar, ticaret noktası, araştırma gözlemevi, sefer garajı | 3 × 2 yapı |
| [crew-machines-sheet.png](assets/packs/crew-machines-sheet.png) | Madenciler, jeolog, teknisyen, yardımcı robot, derinlik uzmanı, sondaj aracı, cevher arabası, keşif dronu | 3 × 3 karakter/makine |
| [miner-mining-cycle.png](assets/packs/miner-mining-cycle.png) | Galeri madencisi için hazırlık, kazmayı kaldırma, darbe, toparlanma ve bekleme pozlarından oluşan ayrıntılı döngü | Şeffaf 4 × 2, sekiz kare; maden galerisinde bot tabanları zemine sabitlenerek oynatılır |
| [resources-treasure-sheet.png](assets/packs/resources-treasure-sheet.png) | Cevherler, kristaller, izotop, külçe, petrol, yapı malzemesi, para, sandıklar, kalıntı ve plan | 4 × 4 eşya ikonu |
| [cave-wall-tile.png](assets/packs/cave-wall-tile.png) | Referansla eşleştirilmiş kesintisiz mağara duvarı için opak, 512 × 512 px kaya malzemesi | Ayna tekrarlı materyal dokusu; sahne dikdörtgeni içinde kırp |
| [mine-earth-iron-wall.png](assets/packs/mine-earth-iron-wall.png) | Derin Dünya katları için demir zengini, kızıl kahverengi kaya duvarı | Tekil üretim dokusu; 100 km ana biyom değişimlerinde kullanılır |
| [mine-earth-crystal-wall.png](assets/packs/mine-earth-crystal-wall.png) | Dünya'nın daha derin katları için mor ve camgöbeği kristal damarları içeren kaya duvarı | Tekil üretim dokusu; 100 km ana biyom değişimlerinde kullanılır |
| [mine-moon-basalt-wall.png](assets/packs/mine-moon-basalt-wall.png) | Ay madeni için koyu bazalt, gri tabakalar ve soğuk mavi damarlar | Tekil üretim dokusu; Ay dünyasında 100 km aralıklarla değişir |
| [mine-moon-crystal-wall.png](assets/packs/mine-moon-crystal-wall.png) | Ay'ın derin katları için geniş bazalt plakalar ve ince kristal çatlakları | Tekil üretim dokusu; Ay dünyasında 100 km aralıklarla değişir |
| [mine-titan-ice-wall.png](assets/packs/mine-titan-ice-wall.png) | Titan madeni için lacivert ve teal buz-kaya katmanları | Tekil üretim dokusu; Titan dünyasında 100 km aralıklarla değişir |
| [mine-titan-amber-wall.png](assets/packs/mine-titan-amber-wall.png) | Titan'ın derin katları için kehribar hidrokarbon damarları ve koyu arduvaz | Tekil üretim dokusu; Titan dünyasında 100 km aralıklarla değişir |
| [mine-edge-rock-tile.png](assets/packs/mine-edge-rock-tile.png) | Maden galerilerinin yan sınırları için dikey tekrar eden kahverengi kaya dokusu | Her kat boyunca dikişsiz dikey döşe; sağ kenarda yatay aynala, Ay ve Titan'da hafif renk uygula |
| [mine-unmined-ground-cap.png](assets/packs/mine-unmined-ground-cap.png) | Önceki, merkezde tümsek oluşturan taban taslağı | Artık kullanılmıyor; yerine merkezde oyuk bırakan yeni tasarım geldi |
| [mine-dug-ground-cap.png](assets/packs/mine-dug-ground-cap.png) | Delici çevresinde aşağı doğru oyulan kaya ve toprak foreground'u | Yalnız etkin/en alt katta kullan; merkezdeki şeffaf kanal delici ucunu açıkta bırakır |
| [surface-outpost-panorama.png](assets/packs/surface-outpost-panorama.png) | Dağ/orman ufku ve gökyüzünden oluşan geniş yüzey arka planı | Yüzey şeridinde `BoxFit.cover`; binalar ve zemin ayrı ön katmandır |
| [moon-outpost-panorama.png](assets/packs/moon-outpost-panorama.png) | Ay üssü için özgün krater ufku ve Dünya manzarası | Ay açıldığında karakol arka planında kullan; bina/zemin ayrı katmandır |
| [titan-outpost-panorama.png](assets/packs/titan-outpost-panorama.png) | Titan üssü için özgün turuncu atmosfer ve mavi buz ufku | Titan açıldığında karakol arka planında kullan; bina/zemin ayrı katmandır |
| [elevator-shaft-repeat.png](assets/packs/elevator-shaft-repeat.png) | Karanlık dikey kuyu boşluğu, sürekli raylar, merdiven traversleri ve fenerler | Merkezdeki dar kuyu şeridinde orta kaynak bölgesini dikey ayna tekrarla; kabin ayrı çizilir |
| [mine-elevator-car.png](assets/packs/mine-elevator-car.png) | Maden kasalı, çelik kafesli asansör kabini | İlk yeraltı galerisinde merkez kuyu hattına hizalı, tabanı ilk platforma oturacak şekilde çiz |
| [deep-drill-rig.png](assets/packs/deep-drill-rig.png) | Aşağı bakan dikey burgulu sondaj aracı ve operatörü | Aktif en alt galeride kazılmamış zemin bandına girer; `ContinuousDrillRig` titreşim/kıvılcım döngüsü verir |
| [depth-biomes-tileset.png](assets/packs/depth-biomes-tileset.png) | Farklı jeolojik malzemeler için görsel ilham | Üretim arka planı değildir; biyom dokuları tekil kaya varlıklarından seçilir |
| [cave-creatures-guardians.png](assets/packs/cave-creatures-guardians.png) | Mağara canlıları ve üç derinlik muhafızı | 3 × 2 yaratık |
| [guardian-bosses-sheet.png](assets/packs/guardian-bosses-sheet.png) | Altı büyük özgün boss taslağı | 3 × 2 boss |
| [guardian-bosses-worlds-sheet.png](assets/packs/guardian-bosses-worlds-sheet.png) | Ay ve Titan'a özgü altı büyük muhafız | Şeffaf 3 × 2 boss atlası; hücreler `AtlasSprite` ile çizilir |
| [ui-icon-sheet.png](assets/packs/ui-icon-sheet.png) | Kazı, asansör, ambar, ticaret, görev, plan, araştırma, keşif, mağara, kristal, sandık ve savunma ikonları | 4 × 4 arayüz ikonu |
| [scientist-portraits-atlas.png](assets/packs/scientist-portraits-atlas.png) | Bilim insanı kadrosu için sekiz farklı kâşif portresi | Şeffaf 4 × 2 karakter atlası; kartta nadirlik ışığı, yaralanma/ölüm rozeti ve hafif nefes animasyonuyla kullanılır |
| [special-workers-atlas.png](assets/packs/special-workers-atlas.png) | Sekiz özel madenci yeteneğine uygun özgün işçi portreleri | Şeffaf 4 × 2 karakter atlası; yetenek kimliğiyle eşlenir ve atölye kartında hafif hareket eder |
| [support-drones-atlas.png](assets/packs/support-drones-atlas.png) | Kaya Gezgini, Gök Feneri, Demir Mıknatıs ve Can Desteği keşif dronları; alt sıra hasarlı durumlar | Şeffaf 4 × 2 animasyon atlası; mağara seçiminde ve yüzen dron animasyonunda `AtlasSprite` ile kullanılır |

## Uygulama notları

- `cave-wall-tile.png` kesintisiz mağara duvarı malzemesidir. Arka planı `ImageShader` ve `TileMode.mirror` ile doldur; doku alanını `clipRect` ile sınırla. Alfa boşluklu kaya sprite'larını duvar dokusu gibi döşeme veya tek bir kaya görselini tüm sahneye germek doğru değildir.
- Maden, derinlik boyunca tembel oluşturulan 1 km oynanış katlarına ayrılır. Duvar dokusu 100 km ana biyom aralıklarında değişir; her 50 km'de hafif renk varyantı uygulanır. Dünya, Ay ve Titan kendi duvar dokularını kullanır. `depth-biomes-tileset.png` bu üretim dokularını türetmek için kullanılmaz.
- `mine-edge-rock-tile.png` her galerinin iki dış kenarında aynı dikey fazdan devam eder; sağ şerit yatay aynalanır. `mine-dug-ground-cap.png` yalnız aktif en alt galeride, merkezde oyuk kalacak ve sondaj ucu görünecek şekilde önde çizilir.
- `cave-wall-tile-v1.png` önceki, daha sık taneli taslağı saklar; oyun ekranında kullanılmaz. Güncel duvar dokusu `cave-wall-tile.png` dosyasıdır.
- `depth-biomes-tileset.png` döşenebilir bir texture değildir: her hücre ayrı bir kaya bloğu illüstrasyonudur ve şeffaf kenar boşlukları vardır. `AtlasSprite` ile tek nesne olarak, oranını koruyarak çiz. Pixel-art sprite'larında komşu atlas hücrelerinden renk örneklemesini azaltmak için `FilterQuality.none` kullan.
- `crew-machines-sheet.png` tek pozlu karakter/makine atlasıdır. `AnimatedCrewSprite` mevcut çizimi küçük gövde hareketleriyle canlandırır ve göreve uygun efekt ekler: madenci darbeli kazı/kıvılcım, sondajcı titreşimli ışın, jeolog/robot tarama halkaları, tamirci kıvılcımı, kâşif kafa lambası, taşıma ekibi toz izi ve dron hover taraması. Yüzeyde atölye, ambar, asansör, ticaret, araştırma ve sefer binalarına farklı ekip rolleri atanır.
- `miner-mining-cycle.png` yalnızca kuyu madencilerinde kullanılır. Sekiz karelik kazma döngüsü, atlas hücresinin altındaki boşluk kareye göre kırpılarak oynatılır; böylece ayakta duruş ve çömelme karelerinde bot tabanları aynı galeri çizgisinde kalır.
- `elevator-shaft-repeat.png` yalnızca kuyu iç ray/boşluk katmanıdır; cave texture veya galeri zemini yerine geçmez. Kaynağın merkezdeki raylı bölgesini al, doğal en-boy oranını koruyarak kuyu genişliğine ölçekle ve yalnızca dikey eksende ayna tekrarla. `mine-elevator-car.png` bu sabit ray katmanının önünde, ilk galeride durur.
- `deep-drill-rig.png` dikey aşağı bakan sondaj ekibidir. Sabit ekrandaki son galeri çizgisinin altına iner; burgunun ucu `mine-dug-ground-cap.png` içindeki oyukta görünür. Derinlik değiştikçe araç en alt galeride çalışmayı sürdürür.
- Yüzeyde `surface-outpost-panorama.png` arka katmandır. Asansör binası ekranın yatay merkezine ve kuyu eksenine hizalanır; diğer tıklanabilir yapılar aynı zemin çizgisine oturur. Panorama, zemin platformu, bina sprite'ları ve karakterler ayrı render katmanlarıdır.
- Zemin malzemesi, kaya silueti/galeri platformu, cevher damarı, dekor ve ışık ayrı çizim katmanlarıdır. Doku malzeme detayını verir; seviye geometrisinin yerine geçmez.
- Sprite atlaslarının köşe pikselinde alfa kanalı 0 olarak doğrulandı; kaya materyali opaktır.
- Kaynak PNG'leri koruyun; kırpılmış ve ölçeklenmiş türevleri ayrı dosyalarda saklayın.
- Metinleri bitmap içine çizmek yerine Flutter metniyle üretin; Türkçe karakter, ölçekleme ve erişilebilirlik korunur.
- Yapı, ikon ve cevher görselleri için bir Dart varlık kataloğu tutun. Ekran koordinatlarına göre görünmez dokunma alanı kullanıp görsel boyutundan bağımsız etkileşim sağlayın.
- Görseller özgün prototip varlıklarıdır; referans oyunun görsellerini, marka işaretlerini veya karakterlerini eklemeyin.
