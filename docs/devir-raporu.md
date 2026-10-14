# Devir raporu — Kamu Pusulası (2 Ekim 2026)

Bu rapor, çalışmayı Claude Code'a devretmek için yazıldı. Önce bunu oku, sonra `docs/yayin-listesi.md` ve
`docs/ios-codemagic.md` dosyalarına bak.

## Proje özeti
- Flutter uygulaması, paket/bundle kimliği `tr.com.ayasyazilim.pusula`, sürüm `1.0.0+1`.
- Depo: https://github.com/oguzhanterzioglu00/claudeproje (yerel klasör `C:\Projeler\claudeproje`, dal
  `claude/exciting-ramanujan-zjb7kh`).
- Arka uç: Supabase (Auth + `hesabi_sil` RPC). iOS derlemesi: Codemagic (`codemagic.yaml`, iş akışı `ios-testflight`).
- Mağaza sürümünde Becayiş ve ödeme kapalı ("Yakında"); Google girişi Android'de çalışır, Apple girişi yalnızca iOS'ta görünür.

## Bu oturumda yapılanlar (HENÜZ COMMIT EDİLMEDİ)
1. **iOS ikonları:** `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` alfa kanalından arındırıldı (RGBA → RGB).
   Sebep: App Store Connect alfa kanallı 1024 ikonu reddeder.
2. **Yalnızca iPhone:** `ios/Runner.xcodeproj/project.pbxproj` içinde `TARGETED_DEVICE_FAMILY = 1` (3 yerde).
   Sebep: iPad ekran görüntüsü zorunluluğunu ve telefon çerçeveli arayüzün iPad'de bozulmasını önlemek.
3. **Yalnızca dikey:** `ios/Runner/Info.plist` içinde iPhone yönleri sadece Portrait. (`~ipad` anahtarı bırakıldı, etkisiz.)
4. **Apple jeton iptali (App Store 5.1.1(v)):**
   - `lib/features/hesap/data/supabase_kimlik_istemcisi.dart`: `hesabiSil()` artık Apple hesabıysa ve iOS'taysa önce
     `_appleJetonunuIptalEt()` çağırır (Apple penceresiyle taze `authorizationCode` alır, `apple-hesap-sil` işlevine yollar);
     başarısızsa hesap silinmez. Sonra `hesabi_sil` RPC çalışır.
   - `lib/features/hesap/data/supabase_kimlik_servisi.dart`: `apple_iptal_hatasi` için Türkçe mesaj eklendi.
   - `supabase/functions/apple-hesap-sil/index.ts` (yeni): JWT'yi doğrular, kodu `refresh_token`'a çevirir, `auth/revoke` çağırır.
   - `docs/ios-codemagic.md` §2 ve §3 güncellendi (kurulum adımları dahil).

## DOĞRULANMADI — Code'da ilk iş
- Bu oturumda Flutter/Dart yoktu: **`flutter analyze` ve `flutter test` çalıştırılmadı.** Özellikle şunlara bak:
  `sb.FunctionException` adı ve `status` alanı, `SignInWithApple.getAppleIDCredential(scopes: const [])`,
  `AuthorizationCredentialAppleID.authorizationCode` (supabase_flutter ^2.18, sign_in_with_apple ^8.2 sürümlerinde).
- `test/supabase_kimlik_test.dart` sahte istemciyle çalışır; arayüz değişmedi, bozulmaması beklenir. Apple silme yolu için
  yeni test yazılabilir (iOS platform kontrolü yüzünden `debugDefaultTargetPlatformOverride` gerekir).
- Edge Function hiç çalıştırılmadı/deploy edilmedi.
- Satır sonları: `git status` ~234 dosyayı değişmiş gösteriyor; bunlar CRLF/LF farkı. Commit öncesi
  `git config core.autocrlf true` (ya da `.gitattributes`) ile gürültüyü temizle, yalnızca gerçek değişiklikleri commit et.
  Bu oturumdaki dosyalar mevcut satır sonu biçimleri korunarak düzenlendi.

## Kullanıcının yapacağı (benim yapamadıklarım; hesaplara erişimim yok)
1. Apple Developer → Keys → "Sign in with Apple" anahtarı oluştur; `.p8` indir; Key ID ve Team ID'yi not al.
2. Supabase CLI (proje ref `ajuhcblicpnosywlssqn`):
   `supabase secrets set APPLE_TEAM_ID=... APPLE_KEY_ID=... APPLE_BUNDLE_ID=tr.com.ayasyazilim.pusula`,
   `supabase secrets set APPLE_PRIVATE_KEY="$(cat AuthKey_XXXX.p8)"`, `supabase functions deploy apple-hesap-sil`.
   `.p8` asla depoya veya sohbete konmaz.
3. Supabase → Authentication → Providers → Apple: açık, Client IDs = `tr.com.ayasyazilim.pusula`.
4. App Store Connect: `tr.com.ayasyazilim.pusula` ile uygulama kaydı; "App Review Information" için Supabase'te
   "Auto Confirm" işaretli demo hesap (e-posta/şifre).
5. Commit + push, sonra Codemagic'te `ios-testflight` iş akışını başlat; TestFlight'ta Apple girişi ve hesap silmeyi dene.

## Bilinen eksikler ve riskler
- **iOS hiç cihazda denenmedi** (Apple girişi, bildirim izni, Google tarayıcı girişi + `tr.com.ayasyazilim.pusula://` dönüşü).
- **iOS arka plan ilan kontrolü yok** (workmanager yalnızca Android). Mağaza metninde "anlık bildirim" denmemeli.
- `flutter_local_notifications` iOS'ta uygulama açıkken bildirim göstermek için `AppDelegate` içinde
  `UNUserNotificationCenter` delegesi gerekebilir; sürümünüzde eklenti bunu kendisi yapıyorsa gerek yok. TestFlight'ta doğrula.
- **Gizlilik manifesti** (`PrivacyInfo.xcprivacy`) uygulama düzeyinde yok; eklentiler kendi manifestlerini getiriyor ama
  Apple uyarı verirse eklemek gerekir (`project.pbxproj`'a kaynak olarak eklenmeli; Mac olmadan dikkatli yapılmalı).
- `in_app_purchase` bağımlılığı var ama kullanılmıyor (Becayiş ödemesi sahte servis). Kullanılmayacaksa kaldırılabilir.
- `codemagic.yaml` içindeki Supabase URL/publishable key ve Google Web istemci kimliği herkese açık değerlerdir (sorun değil);
  gizli anahtar yoktur.
- Becayiş ve ödeme için arka uç yok; açmak `lib/main.dart` varsayılanlarına (`becayisAcik`) ek olarak sunucu işi gerektirir.
- TÜRKPATENT marka sorgusu ve Play Console işleri hâlâ bekliyor (`docs/yayin-raporu.md`).

## Önerilen sıra (Code için)
1. `git config core.autocrlf true`, `flutter pub get`, `flutter analyze`, `flutter test`; hataları düzelt.
2. Değişiklikleri commit et (ikon, plist/pbxproj, Apple jeton iptali, doküman), push et.
3. Kullanıcı Apple/Supabase adımlarını bitirince Codemagic derlemesini izle; hata olursa logları oku.
4. TestFlight sonrası: bildirim delegesi, Apple giriş/silme, Google girişi iOS testleri.
