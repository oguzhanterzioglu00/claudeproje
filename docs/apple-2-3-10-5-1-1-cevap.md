# Apple 1.0 (5) incelemesi: 2.3.10, 5.1.1(v), 4 (Sign in with Apple) — cevap (14 Ekim 2026)

Apple 13/14 Ekim'de 4.3/4.2.6 itirazını kabul edip incelemeyi sürdürdü, ardından üç ayrı bulgu bildirdi.
Düzeltmeler build 6'da (commit 362b49a, `--build-name=1.0.0`) ve ASC ekran görüntülerinde.

| Madde | Bulgu | Düzeltme |
|---|---|---|
| 2.3.10 | Ekran görüntülerinde iOS dışı durum çubuğu / gezinme tuşları | Android çubukları kırpıldı; iOS durum çubuğu + Dynamic Island + ana ekran göstergesi (`tool/ios_magaza_gorselleri.py`), 1290x2796. Arayüzdeki "App Store / Google Play" ifadeleri nötrleştirildi |
| 5.1.1(v) | İlan ve sohbet için kayıt/giriş zorunlu | "Hesap açmadan devam et" (misafir modu); hesap Profil'den isteğe bağlı; kurulumda ad isteğe bağlı, "Şimdilik atla" |
| 4 (HIG) | Apple düğmesinde Apple'ın indirilmemiş logosu; SIWA sonrası ad/e-posta isteniyor | Düğme Apple'ın yerel `ASAuthorizationAppleIDButton`'ı; Profil'deki Lucide elma ikonu kaldırıldı; ad zorunlu değil |

## Resolution Center cevabı (gönderilecek metin)

```
Hello App Review Team,

Thank you for the review. We addressed all three points in a new build (1.0.0, build 6) and in the App Store metadata:

1. Guideline 2.3.10 - Accurate Metadata. We replaced all screenshots. They no longer include non-iOS status bar or navigation bar images, and the app UI no longer refers to other platforms.

2. Guideline 5.1.1(v) - Account-based features. Registration is no longer required. On the first screen users can tap "Hesap açmadan devam et" (Continue without an account) and use every feature, including the job postings, job alarms and the legal-rights assistant, without signing in or providing personal data. An account is optional (Profile > Account) and is used only to back up and move data between devices. In the first-run setup the name is optional and the whole setup can be skipped ("Şimdilik atla").

3. Guideline 4 - Sign in with Apple. The button is now Apple's native ASAuthorizationAppleIDButton (system artwork and localized text). After Sign in with Apple the app no longer requires a name or an e-mail address; those fields are optional.

The demo account remains available in App Review Information. Thank you.

Oğuzhan Terzioğlu — Ayas Yazılım
```
