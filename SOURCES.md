# Oynanış Kaynakları

Bu dosya, referans oyun hakkındaki araştırma notlarını ve yeni oyuna aktarılacak sistemleri kaydeder. Kaynaklar fikir ve oynanış analizi içindir; yeni projede kendi marka dili, metinler, çizimler ve içerik kullanılacaktır.

## Ana kaynak

- [Mr. Mine — CrazyGames](https://www.crazygames.com/game/mister-mine)
- Geliştirici: Playsaurus
- Erişim tarihi: 3 Ekim 2026

Sayfanın anlattığı temel döngü elle maden kazmayla başlar; ekip ve teçhizat zaman içinde otomatik üretim sağlar. Derinlik arttıkça yeni kaynaklar, sandıklar, görevler ve boss karşılaşmaları açılır. Depolama kapasitesi dolduğunda üretim durabilir; kaynakların satılması veya yükseltmelerde kullanılması gerekir. Sayfa Dünya, Ay ve Titan bölgelerini; 112 görevden, ekipman yükseltmelerinden ve altı Dünya bossundan söz eder.

## Tamamlayıcı kaynaklar

- [Resmi Mr. Mine sitesi](https://mrmine.com/) — 100'den fazla üretilebilir yükseltme; sandıklar ve kalıntılar; bilim insanı seferleri; cevher dövme; canavarlar; reaktörler; mağara keşfi ve yeni dünyalar.
- [Mr. Mine — Steam mağaza sayfası](https://store.steampowered.com/app/1397920/MrMine/) — otomatik çalışan madenci ekibi, derinlik ilerleyişi, kendine özgü işlevleri olan yapılar, özel yetenekli madenciler, bilim insanları ve sandıklar.
- [Resmi Mr. Mine Blog — ilerleme ve derinlik sistemleri](https://blog.mrmine.com/free-mining-games-mr-mine-idle-clicker-adventure/) — yüzey ve yeraltı yönetiminin iki katmanlı döngüsü; mağara dronları, bilim insanı kazıları, kalıntılar, yeraltı şehri, cevher dövme, çekirdek, reaktör ve dünya açılımlarının derinlik kilometre taşlarına bağlanması.

## Projeye aktarılacak tasarım örüntüleri

1. Elle tıklama, otomatik işçi üretimi ve daha hızlı kazı yapan sondaj arasında aşamalı geçiş.
2. Kazı, asansör, kargo ve ambar kapasitesinin birbirine bağlı olması; dolulukta üretimin durması ve oyuncunun satış/üretim/yükseltme kararı vermesi.
3. Derinlik kilometre taşlarında yeni yapıların, araçların, kaynakların, seferlerin, bossların ve dünyaların açılması.
4. Yüzeyde tıklanabilir yönetim yapıları; yeraltında katmanlı kaynak keşfi.
5. Sandıklar, görevler, başarımlar, bilim insanı kazıları, kalıntı bonusları, mağara dronları, ticaret teklifleri ve boss savaşları.
6. Geç oyunda cevher/taş işleme, silah üretimi, canavar karşılaşmaları, reaktör ve kalıcı ilerleme sistemi.

Kaynakların bazı derinlik eşikleri farklı sürümlerde değişebileceği için projede bütün eşikler tek bir yapılandırılabilir kilometre taşı tablosunda tutulmalıdır. Ayrıntılı uygulama kapsamı [ajan promptunda](AGENT_IMPLEMENTATION_PROMPT.md) bulunur.

## Flutter doku ve atlas araştırması

- [Flutter `ImageShader`](https://api.flutter.dev/flutter/dart-ui/ImageShader/ImageShader.html) — resim tabanlı shader'ın tekrar edilebilir doku için kullanımı.
- [Flutter `TileMode`](https://api.flutter.dev/flutter/dart-ui/TileMode.html) — `repeated` ve `mirror` örnekleme davranışları.
- [Flutter `Canvas.drawImageRect`](https://api.flutter.dev/flutter/dart-ui/Canvas/drawImageRect.html) — atlas hücresinin kaynak dikdörtgeninden hedef dikdörtgene çizilmesi; filtreleme kaynak alanın kenarının dışından örnek alabilir.
- [Flutter `FilterQuality`](https://api.flutter.dev/flutter/widgets/Texture/filterQuality.html) — `none` için nearest-neighbor benzeri örnekleme; piksel-art sprite'larının bulanıklaşmasını önleme.
- [Tiled: Introduction](https://doc.mapeditor.org/en/stable/manual/introduction/) — tile map karoları ile serbest yerleştirilen görsellerin farklı kullanım modelleri.
- [Tiled: Using Terrains](https://doc.mapeditor.org/en/latest/manual/terrain/) — komşu kenarları eşleşen terrain setleriyle katman geçişleri.

Bu araştırmanın projedeki kuralı: tam, opak ve döşenebilir bir kaya malzemesi `ImageShader` ile yalnızca mağara sınırında tekrarlanır; alfa kanallı atlas hücresi ise tekil sprite olarak kırpılıp çizilir. Zemin geometrisi, galeri kirişi, cevher damarı ve ışık kendi katmanlarında kalır.
