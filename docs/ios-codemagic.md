# iOS: Codemagic ile derleme, TestFlight ve App Store incelemesi

Mac gerekmez. Derleme `codemagic.yaml` dosyasındaki `ios-testflight` iş akışıyla yapılır.

## 1. Bir kez yapılacak kurulum
1. **App Store Connect → Uygulamalar → +** : Yeni uygulama, bundle ID `tr.com.ayasyazilim.pusula` (App ID Apple
   Developer'da hazır, Sign In with Apple açık).
2. **App Store Connect → Kullanıcılar ve Erişim → Entegrasyonlar → App Store Connect API → anahtar oluştur**
   (rol: *App Manager*). `.p8` dosyası bir kez indirilir; gizlidir, depoya koyulmaz.
3. **Codemagic → Teams → Integrations → App Store Connect**: Issuer ID, Key ID ve `.p8` yüklenir; ad **`Kamu_Pusulasi`**
   olmalı (yaml'daki ad).
4. **Codemagic → Add application**: bu depo (GitHub) seçilir, "codemagic.yaml" ile yapılandırılır.
5. `ios-testflight` iş akışını elle başlat. İlk derlemede imzalama dosyaları otomatik oluşturulur.

## 2. App Store inceleme kontrol listesi (kural numaralarıyla)
| Kural | Durum |
|---|---|
| **4.8 Giriş hizmetleri**: üçüncü taraf girişi (Google) varsa Apple ile giriş de sunulmalı | Var: resmî Apple düğmesi, Google'ın üstünde, aynı boyda. Yalnızca iOS'ta görünür. |
| **5.1.1(v) Hesap silme**: uygulama içinden başlatılabilmeli; Apple ile açılan hesapta Apple jetonu da iptal edilmeli | Silme var (Ayarlar → "Hesabımı ve verilerimi sil"). **Apple jeton iptali ayrı iş**: bkz. §3. |
| **5.1.1 Gizlilik politikası** adresi | `https://oguzhanterzioglu00.github.io/claudeproje/gizlilik.html` (App Store Connect'e yazılır). |
| **2.1 Demo hesabı**: giriş gerektiren uygulamada inceleyiciye çalışan bir hesap verilmeli | Supabase → Authentication → Users → *Add user* ile "Auto Confirm User" işaretli bir test hesabı açılır; e-posta/şifre "App Review Information → Sign-in required" alanına yazılır. Şifreyi sen belirle. |
| **2.3 / 4.0 Örnek içerik** ("ÖRNEK" rozeti, sahte düğme) | Gerçek sürümde yok (Supabase ayarlıyken). Derlemede `SUPABASE_*` tanımları şart. |
| **1.2 Kullanıcı içeriği** | Uygulama kullanıcı içeriği paylaştırmıyor. |
| **Resmî kurum izlenimi** | Giriş ekranı ve metinlerde "resmî bir kurum uygulaması değildir" uyarısı var; mağaza açıklamasında da yer almalı. |
| **Şifreleme beyanı** | `ITSAppUsesNonExemptEncryption = false` (yalnızca standart HTTPS). |

## 3. Apple hesap silme: jeton iptali (yapılacak)
Apple ile giriş yapan kullanıcı hesabını silerken Apple'ın `refresh_token`'ı `https://appleid.apple.com/auth/revoke`
ile iptal edilmelidir. Bunun için Apple'dan **Sign in with Apple anahtarı (.p8)** ve bir Supabase Edge Function gerekir;
.p8 yalnızca Supabase sırlarında (Secrets) durur, istemciye/depoya girmez.

## 4. Notlar
- Google girişi iOS'ta tarayıcıdan (Safari) yapılır ve `tr.com.ayasyazilim.pusula://` şemasıyla uygulamaya döner;
  ayrı bir iOS OAuth istemcisi şart değildir.
- Çalışan bir iPhone'da ilk deneme TestFlight'tan yapılır; Apple/iOS kodu henüz hiç cihazda çalıştırılmadı.
