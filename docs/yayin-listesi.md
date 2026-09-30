# Yayın listesi (Google Play / App Store)

Son kontrol: 30 Eylül 2026. Sürüm `1.0.0+1`. Bu sürümde **Becayiş ve Google/Apple girişi kapalıdır** (arka uç ve
gerçek giriş/ödeme yok); `PusulaUygulamasi(becayisAcik: false, sosyalGiris: false)` varsayılanıdır.
Açmak için arka uç bağlandıktan sonra `lib/main.dart` içindeki iki varsayılanı `true` yapmak yeterlidir.

## 1. Android: imzalı paket (.aab)

1. Yükleme anahtarı üret (bir kez; **dosyayı ve şifreyi güvenli yerde sakla**, kaybedersen güncelleme yapamazsın):
   `keytool -genkeypair -v -keystore upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000`
2. GitHub → Settings → Secrets and variables → Actions → şu dört secret'ı ekle:
   - `ANDROID_KEYSTORE_BASE64`: `base64 -w0 upload-keystore.jks` çıktısı
   - `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` (örn. `upload`), `ANDROID_KEY_PASSWORD`
3. Actions → **Android Release (AAB)** → Run workflow → `kamu-pusulasi-aab` çıktısını indir.
4. Play Console → Uygulama oluştur → Üretim → Yeni sürüm → `.aab`'yi yükle. **Play App Signing'i açık bırak.**
   Uygulama kimliği: `tr.com.ayasyazilim.pusula` (yüklendikten sonra değiştirilemez).

Yerelde imzalamak istersen `android/key.properties` (git'e girmez): `storeFile`, `storePassword`, `keyAlias`, `keyPassword`.

## 2. iOS

- Bundle ID `tr.com.ayasyazilim.pusula`. Derleme macOS + Xcode ister (bu depoda CI'da iOS derlemesi **yok** ve iOS'te
  hiç denenmedi); ilk arşivi kendi Mac'inde alıp TestFlight'ta dene.
- iOS'ta uygulama kapalıyken ilan/Resmî Gazete bildirimi yoktur (yalnızca açıkken kontrol). Mağaza açıklamasında
  "anlık bildirim" vaat etme.
- Gizlilik: kamera ve galeri izin metinleri `Info.plist` içinde Türkçe hazır.

## 3. Mağaza formları için yanıtlar

- **Veri güvenliği (Play) / Gizlilik etiketleri (Apple):** Uygulama ad, e-posta, statü, kurum, maaş bilgileri ve
  fotoğrafı yalnızca cihazda tutar; geliştirici sunucusuna göndermez → "Veri toplanmıyor / paylaşılmıyor".
  İlan ve haber akışı GitHub'dan indirilir (IP adresi GitHub tarafından görülür); kendi sunucumuz yok.
  Analitik, reklam, çökme raporu SDK'sı **yok**.
- **Hesap silme:** Uygulama içinde Profil → "Hesabımı ve verilerimi sil". Hesaplar yalnızca cihazdadır; Play'in
  istediği "web'den silme" adresi için `ayasyazilim.com.tr` altında bir sayfa (ya da destek e-postası) göster.
- **Gizlilik politikası URL'si (zorunlu):** Aydınlatma Metni'nin (`lib/features/ayarlar/yasal_metinler.dart`) web
  hâlini `ayasyazilim.com.tr` altında yayınla ve adresi her iki mağazaya gir. **Bu adres olmadan yayın yapılamaz.**
- **Hedef kitle:** 18+ (kamu çalışanları); çocuklara yönelik değil.
- **İçerik derecelendirme:** Şiddet, kumar vb. yok; kullanıcı içeriği paylaşımı yok (becayiş kapalı).
- **Devlet/kamu uygulaması beyanı:** Uygulama bağımsızdır, resmî kurum uygulaması **değildir**. Başvuru metninde ve
  ekran görüntülerinde kurum logosu/arması kullanma. (Uygulama içinde: Ayarlar → Hakkında, Giriş, Kullanım Koşulları.)
- **İzinler:** İnternet, bildirim (Android 13+), yeniden başlatınca arka plan işini sürdürme, kamera/galeri
  (yalnızca profil fotoğrafı). Tam zamanlı alarm izni **istenmez**.

## 4. Mağaza metni (taslak)

- **Ad:** Kamu Pusulası — **Kısa açıklama (80):** Kamu çalışanı için maaş hesabı, hakların ve güncel kamu ilanları.
- **Uzun açıklama:** Memur, sözleşmeli (4/B) ve işçi statüsündeki kamu çalışanları için: maaş hesaplama (memur ve
  brütten nete), kaynağı gösterilen "Hakkım ne?" mevzuat asistanı, Kariyer Kapısı ilanları, Resmî Gazete'den
  kamu personelini ilgilendiren maddeler, isteğe bağlı yeni ilan bildirimi. Verilerin yalnızca telefonunda kalır.
  *Bağımsız bir uygulamadır; hiçbir kamu kurumunun resmî uygulaması değildir.*
- Ekran görüntüleri: Ana sayfa, Maaş, Asistan, İlanlar (en az 2, telefon). **Becayiş ekranı ekleme** (kapalı).

## 5. Bilinen sınırlar (dürüst liste)

- Hesap ve profil yalnızca cihazdadır; telefon değişince/uygulama silinince kaybolur. Bunu açıklamaya yaz.
- İlan ve haber akışı GitHub Actions ile 15 dakikada bir güncellenir; GitHub gecikme yapabilir, uzun süre depo
  etkinliği olmazsa zamanlanmış iş devre dışı kalabilir (Actions sekmesinden kontrol et).
- Kariyer Kapısı RSS'inde son başvuru tarihi yok; ilan kartı "son gün bilinmiyor" der.
- Android arka plan kontrolü pil tasarrufu nedeniyle gecikebilir; anlık (saniyelik) bildirim değildir.
- Asistan yalnızca resmî metinden birebir alıntı yapar; doğrulayamadığımız rakamları (iptal edilen hastalık izni
  gün sayısı, kıdem tazminatı tavanı, sözleşmeli disiplin/aylıksız izin ayrıntısı) **vermez**. Maaş katsayıları
  yıl/dönem değişince güncellenmelidir.
- Kullanıcı sayısı arttığında çökme raporu ve sunucu tabanlı bildirim (FCM) gerekir; ikisi de yasal metinleri
  değiştirir.
