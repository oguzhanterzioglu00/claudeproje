# Kamu Pusulası · Maaş hesaplayıcı şartnamesi

Kapsam: 657 sayılı Kanun'a tabi memurun **tahmini** brüt/net maaşı. Sözleşmeli (4/B) ve işçi maaşı sözleşmeye/toplu iş sözleşmesine göre değiştiği için bu sürümde hesaplanmaz; ekran bunu açıkça söyler.

Kod: `lib/features/maas/domain/` (motor) ve `presentation/maas_sayfasi.dart`. Motor saf Dart'tır; katsayılar `MaasParametreleri` ile dışarıdan verilir, motor içinde sabit kodlanmaz.

## 1. Formül

| Kalem | Formül |
|---|---|
| Gösterge aylığı | aylık gösterge (derece, kademe) × aylık katsayı |
| Ek gösterge aylığı | ek gösterge × aylık katsayı |
| Taban aylık | 1000 × taban aylık katsayısı |
| Kıdem aylığı | min(hizmet yılı, 25) × 25 × aylık katsayı |
| Yan ödeme | yan ödeme puanı × yan ödeme katsayısı |
| Özel hizmet tazminatı | oran × (aylık gösterge + ek gösterge) × aylık katsayı |
| Diğer ödemeler | kullanıcı girer (ek ödeme vb.) |
| **Brüt** | toplamları |

SGK matrahı = gösterge + ek gösterge + taban + kıdem + özel hizmet tazminatı. Yan ödeme ve "diğer ödemeler" SGK matrahına girmez.

Kesintiler: emeklilik payı %9 ve genel sağlık sigortası %5 (SGK matrahı üzerinden), damga vergisi binde 7,59 (brüt üzerinden, aylık asgari ücret damga istisnası düşülür), gelir vergisi (kümülatif, asgari ücret istisnası düşülür).

Gelir vergisi: matrah = brüt − emeklilik payı − GSS. Ay *m* için vergi = tarife(m × matrah) − tarife((m−1) × matrah); asgari ücret istisnası aynı yöntemle asgari ücret matrahından hesaplanır ve düşülür (negatifse sıfır).

## 2. Kaynaklar ve doğrulama durumu (araştırma: 29 Eylül 2026)

| Veri | Değer | Kaynak | Durum |
|---|---|---|---|
| Aylık gösterge tablosu | 15 derece × en çok 9 kademe (1. derecede 4, 2.'de 6, 3.'de 8 kademe) | 657 md. 154, I sayılı cetvel: kanun metni (MEB Personel Genel Müdürlüğü PDF'i) ve Sinop Üniversitesi yayını | İki kaynakta 15 satır **birebir aynı**; test ile kilitli |
| Aylık katsayı | 1,575512 | Hazine ve Maliye Bakanlığı mali haklar genelgesi (3 Temmuz 2026), R.G. 5 Temmuz 2026, S. 32999 | İki ikincil kaynakta aynı; birincil metin okunamadı |
| Taban aylık katsayısı | 25,794915 | aynı | aynı |
| Yan ödeme katsayısı | 0,499649 | aynı | tek kaynakta doğrulandı |
| SGK sigortalı payı %9 (malullük/yaşlılık/ölüm) ve GSS %5 | 5510 sayılı Kanun md. 81 (mevzuat.gov.tr birleştirilmiş metin, 7590 sayılı Kanun değişikliğine kadar işlenmiş): "%21'idir. Bunun %9'u sigortalı hissesi"; GSS "%12,5'idir. Bu primin %5'i sigortalı" | **birincil, doğrulandı** | 24/7/2026 tarihli 7590 sayılı Kanun işveren payını %11→%12 yaptı; sigortalı payı değişmedi |
| İşsizlik sigortası sigortalı payı %1 | 4447 sayılı Kanun md. 49 ("%1 sigortalı, %2 işveren ve %1 Devlet payı") | **birincil, doğrulandı** | yalnızca 4/1-(a) kapsamı (işçi, 4/B sözleşmeli); memurda yok |
| SGK prime esas kazanç sınırları | 5510 md. 82: alt sınır asgari ücret, üst sınır alt sınırın 9 katı (2026: 297.270 TL) | **birincil, doğrulandı** | |
| Gelir vergisi dilimleri (ücret) | 190.000 (%15), 400.000 (%20), 1.500.000 (%27), 5.300.000 (%35), üstü %40 | GİB "Gelir Vergisi Tarifesi 2026" (332 Seri No.lu Tebliğ), ücret geliri satırları | **birincil, doğrulandı**; dilim vergi tutarları (28.500 / 70.500 / 367.500 / 1.697.500) testle kilitli |
| Asgari ücret | brüt 33.030 TL, net 28.075,50 TL; işçi kesintisi %15 (SGK %14 + işsizlik %1); damga istisnası 250,70 TL/ay (= 33.030 × 0,00759) | birden çok ikincil kaynak; kesinti oranları birincil kaynakla tutarlı; Temmuz 2026'da ara zam yapılmadığı haberlerden teyit edildi | Ocak 2027'de yeniden belirlenir; motor 33.030 brütten 28.075,50 net'i **tam** üretir (test) |

Kıdem aylığı göstergesi (yılda 25) ve taban aylık göstergesi (1000) bir ikincil kaynağın formül açıklamasından alındı; kanun metniyle teyit edilmeli.

## 3. Varsayımlar ve bilinen sınırlar

- **"Tahmini" etiketi zorunludur.** Bordrodaki net tutar geçerlidir; ekran bunu yazar.
- Aylık tutar yıl boyunca sabit kabul edilir. Temmuz zammı, statü veya kadro değişimi gibi durumlar kümülatif vergiyi etkiler; motor önceki ayların gerçek matrahını bilmez. Aralık ayında vergi düşük çıkması bu yüzdendir.
- Özel hizmet tazminatı matrahı (gösterge + ek gösterge) × katsayı olarak varsayıldı; bu, unvan bazında farklı olabilir.
- Aile/çocuk yardımı, 666 sayılı KHK ek ödemesi, iş güçlüğü/risk zammı, fazla mesai, sendika kesintileri, SGK prim tavanı **hesaba katılmaz**. Kullanıcı bunları "diğer ödemeler"e brüt olarak girebilir.
- Emekli Sandığı kapsamındaki (5434) eski memurlarda kesinti oranları farklı olabilir; motor 5510 oranlarını kullanır (`MaasParametreleri.emeklilikPayi`).
- Ek gösterge, yan ödeme puanı ve tazminat oranı unvana bağlıdır. Kullanıcı bordrosundan girer; uygulama bu değerleri unvandan tahmin etmez (yanlış olabilir).

## 3.1 Sözleşmeli (4/B) ve işçi: brütten nete

`UcretliMaasHesaplayici`, 5510 md. 4/1-(a) kapsamındaki ücretlinin bordrodaki aylık **brüt** ücretinden tahmini net'ini hesaplar (4/B sözleşmeli personel ve işçi aynı kesinti kurallarına tabidir). Brüt ücret kullanıcıdan alınır: sözleşmeli personelin ücreti sözleşmeyle belirlenir (kurum türüne göre ücret tavanı vardır), işçinin ücreti toplu iş sözleşmesine ve kadroya bağlıdır; uygulama bunları tahmin etmez.

Kesintiler: SGK işçi payı %14 ve işsizlik %1 (prime esas kazanç üst sınırı 9 × asgari ücrete kadar), damga vergisi binde 7,59 (asgari ücrete isabet eden 250,70 TL istisna), kümülatif gelir vergisi (matrah = brüt − SGK − işsizlik; asgari ücret gelir vergisi istisnası aynı kümülatif yöntemle düşülür).

Bilinen sınırlar: sendika aidatı, icra/nafaka, özel sağlık sigortası, engelli indirimi, ikramiye ve fazla mesai (tek seferlik kalemler kümülatif vergiyi değiştirir) hesaba katılmaz; aylık brüt yıl boyunca sabit kabul edilir. Akademik personel ve "diğer" statüler için hesap yoktur (ekran bunu açıkça söyler).

## 4. Dönem güncellemesi

Katsayılar Ocak ve Temmuz'da değişir. Yeni dönem için `MaasParametreleri` içine yeni bir sabit eklenir (`donem`, `kaynak`, üç katsayı, gerekiyorsa vergi/asgari ücret değerleri) ve varsayılan gösterilen parametre değiştirilir; motor ve ekran değişmez. Çalışma zamanında uzaktan güncelleme (arka uçtan parametre çekme) ilerisi için önerilir ve imzalı/sürümlü olmalıdır.

## 5. Açık işler

1. Tüm "teyit edilmeli" satırlarının birincil kaynakla doğrulanması (mevzuat.gov.tr, GİB, SGK).
2. ~~Ana sayfadaki net maaş~~ profildeki girdilerle (memur: derece/kademe; sözleşmeli/işçi: brüt ücret) motorlara bağlandı.
3. "Zam farkı" için önceki dönem katsayıları gerekir (Ocak–Haziran 2026 değerleri bu belgede doğrulanmadı).
4. Sözleşmeli (4/B) için kurum bazlı ücret tavanı (ör. mahalli idare sözleşmeli personel tavanları Hazine ve Maliye Bakanlığı genelgesiyle her dönem ilan edilir) ve işçi için kamu işçisi çerçeve protokolü zamları henüz uygulamada yok; kullanıcı bordrodaki brütü girer.
