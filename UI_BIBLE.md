# Taşın Altı — Arayüz Kılavuzu

## Cihaz ve kullanım

- Android/iOS ana deneyimi yalnızca portre yöndedir; yön değişimi oyunu döndürmez.
- Tek elle kullanım: ana eylem ve sık kullanılan kontroller ekranın alt yarısında, başparmak erişiminde; önemli kontrol üst köşeye konmaz.
- Kaydırma, basma ve sürükleme tek parmakla yapılır. Küçük kontrol alanı en az 48 mantıksal piksel olmalıdır.
- Geniş ekran Flutter çalıştırması geliştirme ve önizleme içindir; mobil düzen sözleşmesinin yerine geçmez.

## Ekran hiyerarşisi

Portre düzeni:

1. Üst kaynak şeridi: kasa, kargo doluluğu, derinlik ve basınç; yatay kaydırılabilir.
2. Yüzey karakolu: altı bina tek kadraja sığar; bina adları sprite'ın üstüne oturan tabelalardadır.
3. Maden sahnesi: görünür katlar ve güncel biyom; bir parmakla dikey kaydırma.
4. Sabit alt eylem alanı: büyük **KAZI** düğmesi ile kısa yollar; eylem alanı galeri çiziminin üstünü örtmez.

Uygulama yalnızca dikey ekran yönünü destekler. Diğer sistemler ekran yüksekliğini aşmayan, kaydırılabilir alt sayfa veya ekran içi sekme olarak açılır.

## Bileşenler

- Ana arka plan: `ink`; paneller: `panel`; seçili kart: `panelRaised`.
- Çerçeve ince bakır; ana buton kehribar, başarılı/üretim durumu teal, tehlike mercan.
- Başlık kısa, iri ve gerektiğinde büyük harf; uzun Türkçe metin yerel Flutter fontunda kalır.
- Sayılar sabit genişlikte basılır. Binlik ayırıcı Türkçe nokta, ölçü etiketi `m` veya `km` kullanır.
- Kilitli sistemin yanında kilit nedeni ve gereken derinlik açıkça yazılır.
- Rezerv, doluluk, nadirlik ve tehlike yalnızca renkle anlatılmaz; metin/ikon da görünür.

## Etkileşim ve erişilebilirlik

- Etkileşimli kartta hover, basılı, odak ve disabled durumu vardır. Dokunmada kısa ses/ölçek/renk geri bildirimi kullanılır.
- Ekran okuyucu düğme adını ve sonucunu duyar; odak sırası görsel okuma sırasını izler.
- Satış ve prestij gibi geri dönüşsüz eylemden önce açık özet gösterilir. Satış rezervi atlamaz.
- Zamanlayıcılar `mm:ss` ve uzun süre için saat gösterir; tamamlanan eylem görünür bildirim üretir.

## Panel davranışı

- Sistem paneli oyun state'inden gerçek değer okur, gerçek eylem yazar ve kapatıldığında oyun durumu korunur.
- Küçük telefonlarda panel ekran yüksekliğini aşmaz; panel içeriği kaydırılır ve kapat düğmesi sabit kalır.
- Ambar, ticaret, görev, sefer, araştırma ve muhafız ekranları aynı boş/yükleniyor/hazır durum dilini paylaşır.
- Sabit alt eylem alanı safe area içinde kalır.
