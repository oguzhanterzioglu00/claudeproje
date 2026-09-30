# Yayın raporu — Kamu Pusulası 1.0.0 (30 Eylül 2026)

Dal: `claude/exciting-ramanujan-zjb7kh`. Ayrıntılı adımlar ve form yanıtları: `docs/yayin-listesi.md`.

## Yapılanlar (Claude, bu oturum)

- **Kod ve test:** `flutter analyze` temiz, 349 test geçiyor. Sürüm `1.0.0+1`, paket `tr.com.ayasyazilim.pusula`.
- **Sahte içerik kapatıldı:** Becayiş (uydurma kişi + sahte ödeme) ve Google/Apple girişi mağaza sürümünde kapalı.
  Becayiş sekmesi "Yakında" der. Açmak için `lib/main.dart` içindeki `becayisAcik` ve `sosyalGiris` varsayılanları.
- **Resmî kurum izlenimi:** "Bağımsız uygulamadır, resmî kurum uygulaması değildir" notu Ayarlar, Giriş ve Koşullar'da.
- **Yasal metinler:** Aydınlatma metnine GitHub'dan akış indirildiği (IP adresi) eklendi; yer tutucu yok.
- **Mağaza imzası:** `android/app/build.gradle.kts` imza bilgisi (dosya ya da ortam değişkeni) varsa mağaza anahtarını,
  yoksa debug anahtarını kullanır. `.github/workflows/release.yml` imzalı `.aab` üretir (elle çalıştırılır).
- **Gizlilik / koşullar / hesap silme sayfaları:** Uygulamadaki metinlerden otomatik üretilir
  (`tool/yasal_html_uret.dart`, web iş akışına bağlı). Adresler, web derlemesi bittikten sonra:
  `https://oguzhanterzioglu00.github.io/claudeproje/gizlilik.html`, `.../kosullar.html`, `.../hesap-silme.html`.
- **Doküman:** Mağaza formu yanıtları, mağaza metni taslağı, bilinen sınırlar → `docs/yayin-listesi.md`.
- **CI'da bulunan hata düzeltildi:** İlk release denemesi `isMinifyEnabled` satırı yüzünden derlenmiyordu, satır kaldırıldı.

## Kalanlar (sen, Claude PC ile)

Sırayla; her adımın ayrıntısı `docs/yayin-listesi.md` içinde.

1. **Yükleme anahtarı üret ve sakla** (Claude burada üretmedi; anahtarı ve şifreyi başkası görmemeli):
   `keytool -genkeypair -v -keystore upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000`
   Dosyayı ve şifreyi parola yöneticisine yedekle.
2. **GitHub Secrets ekle:** `ANDROID_KEYSTORE_BASE64` (`base64 -w0 upload-keystore.jks`), `ANDROID_KEYSTORE_PASSWORD`,
   `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.
3. **İmzalı paketi al:** Actions → "Android Release (AAB)" → Run workflow → `kamu-pusulasi-aab`'yi indir.
4. **Play Console:** Uygulama oluştur (paket kimliği `tr.com.ayasyazilim.pusula`), Play App Signing açık, `.aab`'yi yükle.
   Gizlilik URL'si ve hesap silme URL'sini gir (yukarıdaki adresler). Veri güvenliği: "veri toplanmıyor".
   Hedef kitle 18+, içerik derecelendirme anketi, mağaza metni, ekran görüntüleri (Becayiş ekranı olmasın).
5. **Kendi telefonunda son deneme:** Yeni APK'yı kur; uygulama kapalıyken ilan bildirimi geliyor mu (bir gün bekle),
   giriş ekranında Google/Apple yok mu, Becayiş "yakında" mı.
6. **TÜRKPATENT:** "Kamu Pusulası" adı için marka sorgusu.
7. **iOS (istersen sonra):** Mac'te Xcode ile arşivle, TestFlight'ta dene. iOS derlemesi hiç denenmedi; iOS'ta
   uygulama kapalıyken bildirim yok, mağaza metnine "anlık bildirim" yazma.

## Bilerek yapılmayanlar / sonraya

Becayiş, Google/Apple girişi ve ödeme (arka uç gerek); çökme raporu ve FCM push (yasal metni değiştirir);
iOS arka plan bildirimi; Kariyer Kapısı'ndan son başvuru tarihi (API sandbox ve runner'dan erişilemiyor).
