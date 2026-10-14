# iOS: Codemagic ile derleme, TestFlight ve App Store incelemesi

Mac gerekmez. Derleme `codemagic.yaml` dosyasındaki `ios-testflight` iş akışıyla yapılır.

## 1. Bir kez yapılacak kurulum
1. **App Store Connect → Uygulamalar → +** : Yeni uygulama, bundle ID `tr.com.ayasyazilim.pusula` (App ID Apple
   Developer'da hazır, Sign In with Apple açık).
2. **App Store Connect → Kullanıcılar ve Erişim → Entegrasyonlar → App Store Connect API → anahtar oluştur**
   (rol: *App Manager*). `.p8` dosyası bir kez indirilir; gizlidir, depoya koyulmaz.
3. **Codemagic → Settings → Integrations → Developer Portal**: Issuer ID, Key ID ve `.p8` yüklenir. Şu an **`Codemagic`**
   adlı bir anahtar kurulu (Key `G5GDW7U59W`); yaml'daki `app_store_connect:` değeri bu adla aynı olmalıdır.
4. **Codemagic → Add application**: bu depo (GitHub) seçilir, "codemagic.yaml" ile yapılandırılır.
5. `ios-testflight` iş akışını elle başlat. İlk derlemede imzalama dosyaları otomatik oluşturulur.

## 2. App Store inceleme kontrol listesi (kural numaralarıyla)
| Kural | Durum |
|---|---|
| **4.8 Giriş hizmetleri**: üçüncü taraf girişi (Google) varsa Apple ile giriş de sunulmalı | Var: resmî Apple düğmesi, Google'ın üstünde, aynı boyda. Yalnızca iOS'ta görünür. |
| **5.1.1(v) Hesap silme**: uygulama içinden başlatılabilmeli; Apple ile açılan hesapta Apple jetonu da iptal edilmeli | Silme var (Ayarlar → "Hesabımı ve verilerimi sil"). Apple jeton iptali **kodlandı** (`supabase/functions/apple-hesap-sil`); işlevi yayınlamak ve .p8 sırlarını girmek gerekir: bkz. §3. |
| **5.1.1 Gizlilik politikası** adresi | `https://oguzhanterzioglu00.github.io/claudeproje/gizlilik.html` (App Store Connect'e yazılır). |
| **2.1 Demo hesabı**: giriş gerektiren uygulamada inceleyiciye çalışan bir hesap verilmeli | Supabase → Authentication → Users → *Add user* ile "Auto Confirm User" işaretli bir test hesabı açılır; e-posta/şifre "App Review Information → Sign-in required" alanına yazılır. Şifreyi sen belirle. |
| **2.3 / 4.0 Örnek içerik** ("ÖRNEK" rozeti, sahte düğme) | Gerçek sürümde yok (Supabase ayarlıyken). Derlemede `SUPABASE_*` tanımları şart. |
| **1.2 Kullanıcı içeriği** | Uygulama kullanıcı içeriği paylaştırmıyor. |
| **Resmî kurum izlenimi** | Giriş ekranı ve metinlerde "resmî bir kurum uygulaması değildir" uyarısı var; mağaza açıklamasında da yer almalı. |
| **Şifreleme beyanı** | `ITSAppUsesNonExemptEncryption = false` (yalnızca standart HTTPS). |

## 3. Apple hesap silme: jeton iptali
Apple ile giriş yapan kullanıcı hesabını silerken Apple'ın `refresh_token`'ı `https://appleid.apple.com/auth/revoke`
ile iptal edilmelidir. Kod hazır: uygulama silmeden önce Apple penceresini bir kez daha gösterip taze
`authorizationCode` alır, `supabase/functions/apple-hesap-sil` işlevine gönderir; işlev kodu `refresh_token`'a çevirip
iptal eder, sonra uygulama `hesabi_sil()` ile hesabı siler. İptal başarısızsa hesap silinmez (kullanıcı tekrar dener).

**Bir kez yapılacak kurulum:**
1. developer.apple.com → Certificates, Identifiers & Profiles → **Keys → +** → *Sign in with Apple* işaretle →
   Configure → Primary App ID: `tr.com.ayasyazilim.pusula` → Register → **.p8 dosyasını indir** (bir kez indirilir)
   ve **Key ID**'yi not al. Team ID: Membership details sayfasında.
2. Supabase CLI ile (`supabase login`, `supabase link --project-ref ajuhcblicpnosywlssqn`):
   ```sh
   supabase secrets set APPLE_TEAM_ID=XXXXXXXXXX APPLE_KEY_ID=YYYYYYYYYY APPLE_BUNDLE_ID=tr.com.ayasyazilim.pusula
   supabase secrets set APPLE_PRIVATE_KEY="$(cat AuthKey_YYYYYYYYYY.p8)"
   supabase functions deploy apple-hesap-sil
   ```
   Windows PowerShell'de: `supabase secrets set APPLE_PRIVATE_KEY="$(Get-Content AuthKey_YYYYYYYYYY.p8 -Raw)"`.
   (Dashboard'dan da girilebilir: Edge Functions → Secrets.) .p8 depoya konmaz.
3. Sınama: TestFlight'ta Apple ile giriş yap → Ayarlar → Hesabımı sil. Apple penceresi çıkmalı, ardından hesap silinmeli.
   Hata olursa Supabase → Edge Functions → apple-hesap-sil → Logs'a bak (`apple_token_hatasi` genelde yanlış
   Team/Key ID ya da bundle kimliği demektir).

## 4. Notlar
- Google girişi iOS'ta tarayıcıdan (Safari) yapılır ve `tr.com.ayasyazilim.pusula://` şemasıyla uygulamaya döner;
  ayrı bir iOS OAuth istemcisi şart değildir.
- Çalışan bir iPhone'da ilk deneme TestFlight'tan yapılır; Apple/iOS kodu henüz hiç cihazda çalıştırılmadı.
