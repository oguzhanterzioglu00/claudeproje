# Supabase kurulumu (gerçek hesaplar: e-posta ve Google)

Uygulama, arka uç olarak **Supabase**'i kullanır (ücretsiz katman yeterlidir). Kod hazırdır; aşağıdaki adımları
**siz** yapıp iki değeri (proje adresi ve yayınlanabilir anahtar) bana ya da derleme komutuna vermeniz gerekir.
Hesap açma, anahtar üretme gibi işlemleri başkası sizin yerinize yapamaz.

## 1. Proje oluştur
1. <https://supabase.com> → **Start your project** → GitHub ya da e-postayla üye ol.
2. **New project**: ad `kamu-pusulasi`, **Region: Central EU (Frankfurt)**, güçlü bir veritabanı şifresi
   (parola yöneticine kaydet).

## 2. SQL betiğini çalıştır
**SQL Editor** → **New query** → `docs/supabase/kurulum.sql` içeriğini yapıştır → **Run**.
(Bu, "Hesabımı ve verilerimi sil" düğmesinin sunucuda çalışması için gereklidir.)

## 3. E-posta girişi
**Authentication → Sign In / Providers → Email**: açık olsun. **Confirm email** açık kalsın (güvenlik için önerilir),
**Minimum password length** = 8.

## 4. Yönlendirme adresi
**Authentication → URL Configuration → Redirect URLs → Add URL**:

```
tr.com.ayasyazilim.pusula://giris-geri-donus
```

(Tarayıcıdan, e-posta bağlantısından ve Google girişinden uygulamaya dönüş bu adresle olur. **Site URL** olarak
`https://oguzhanterzioglu00.github.io/claudeproje/` yazabilirsiniz.)

## 5. Google ile giriş
1. <https://console.cloud.google.com> → proje oluştur (ör. `kamu-pusulasi`).
2. **APIs & Services → OAuth consent screen**: *External*, uygulama adı **Kamu Pusulası**, destek e-postası, geliştirici
   e-postası. **Authorized domains** alanına `supabase.co` ekle. Gizlilik politikası bağlantısı:
   `https://oguzhanterzioglu00.github.io/claudeproje/gizlilik.html`. Yayın durumunu **In production** yap
   (aksi hâlde yalnızca test kullanıcıları girebilir).
3. **Credentials → Create credentials → OAuth client ID → Web application**. **Authorized redirect URIs**:
   `https://<PROJE-REF>.supabase.co/auth/v1/callback` (proje referansı Supabase panelinde Project Settings → General).
4. Oluşan **Client ID** ve **Client secret**'ı kopyala.
5. Supabase → **Authentication → Sign In / Providers → Google**: **Enable**, Client ID ve secret'ı yapıştır → **Save**.

### 5b. Yerel Google girişi (Android) — önerilir
Tarayıcıdan girişte Google ekranında uygulama adı yerine `….supabase.co` görünür. Bunu önlemek için Android'in yerel hesap
seçicisi kullanılır (altta açılan pencere, "Kamu Pusulası" adıyla). Gerekenler:
1. Google Cloud → **Clients → Create client → Android**: paket adı `tr.com.ayasyazilim.pusula`, **SHA-1** parmak izi.
   Geliştirme (debug) anahtarının SHA-1'i: `keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android`.
   **Mağaza sürümü için ayrıca** Play Console → Uygulama bütünlüğü'ndeki *Uygulama imzalama anahtarı* SHA-1'i de aynı
   şekilde yeni bir Android istemcisi olarak eklenmelidir (yoksa mağazadan inen sürümde yerel giriş çalışmaz).
2. Derlemeye **Web** istemcisinin kimliğini verin: `--dart-define=GOOGLE_WEB_CLIENT_ID=<web-istemci-kimliği>.apps.googleusercontent.com`
   (CI'da `GOOGLE_WEB_CLIENT_ID` sırrı). Kimlik gizli değildir; *client secret* uygulamaya hiç konmaz.
3. Verilmezse ya da yerel giriş desteklenmiyorsa Google girişi tarayıcıdan yapılır (yedek yol).

### 5c. Apple ile giriş (yalnızca iOS)
Yerel iOS girişi için **`.p8` anahtarı gerekmez**:
1. developer.apple.com → Identifiers → `tr.com.ayasyazilim.pusula` App ID → **Sign In with Apple** yeteneğini açın.
2. Supabase → Authentication → Sign In / Providers → **Apple** → Enable, **Client IDs** alanına bundle kimliğini yazın:
   `tr.com.ayasyazilim.pusula` → Save. (Secret alanı yerel iOS girişinde boş kalabilir.)
3. Mac'te Xcode → Runner → **Signing & Capabilities → + Capability → Sign in with Apple** (entitlements dosyasını ve proje
   ayarını Xcode kendisi ekler).
4. Düğme yalnızca iPhone/iPad'de görünür; Android'de çıkmaz.

**Mağaza uyarısı (App Store 5.1.1(v)):** Apple ile açılan hesap silinirken Apple'ın jetonunun da iptal edilmesi
gerekir. Bu, Apple'a `authorizationCode` ile istek atıp **client secret (`.p8`)** kullanan bir sunucu işlevi
(Supabase Edge Function) ister ve henüz yazılmadı; iOS mağaza gönderiminden önce yapılmalıdır.
**Bu kod iOS cihazda hiç denenmedi** (yalnızca sahte istemciyle test edildi).

## 6. E-posta gönderimi (önemli)
Supabase'in yerleşik e-posta servisi saatte yalnızca **birkaç** e-posta gönderir (doğrulama ve şifre sıfırlama
e-postaları dahil). Gerçek kullanıcılar için **Project Settings → Authentication → SMTP Settings**'ten ücretsiz bir
SMTP sağlayıcısı bağlayın (ör. Brevo günde 300, Resend ayda 3.000 e-posta). E-posta şablonlarını
**Authentication → Email Templates**'ten Türkçeleştirebilirsiniz.

## 7. Anahtarları al
**Project Settings → API**: **Project URL** ve **Publishable key** (eski adıyla *anon key*). İkisi de istemciye
gömülmek üzere tasarlanmıştır; veriyi koruyan şey anahtarın gizliliği değil, veritabanı kurallarıdır. **service_role /
secret anahtarını asla uygulamaya ya da depoya koymayın.**

## 8. Telefonda dene
```sh
flutter run -d <cihaz-kimliği> --dart-define=SUPABASE_URL=https://XXXX.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```
Anahtarlar verilmezse uygulama cihaz içi **örnek hesapla** açılır ve giriş ekranında "ÖRNEK" etiketi görünür; gerçek
hesaplarda bu etiket yoktur.

## 9. GitHub Actions (APK / web / mağaza paketi)
Depo → **Settings → Secrets and variables → Actions → New repository secret**:
`SUPABASE_URL` ve `SUPABASE_PUBLISHABLE_KEY`. Mağaza paketi iş akışı (`release.yml`) bu sırlar yoksa **derlemeyi
durdurur**: örnek hesaplı bir sürüm yanlışlıkla yayınlanmaz.

## Bilmeniz gerekenler
- **Ücretsiz katman:** 50.000 aylık aktif kullanıcıya kadar yeterli. Bir haftadan uzun süre hiç kullanılmayan ücretsiz
  proje **duraklatılır** (panelden tek tıkla devam ettirilir); kullanıcılar olunca sorun olmaz.
- **KVKK:** hesap bilgileri (e-posta, şifre özeti) AB'deki (Frankfurt) Supabase sunucusunda tutulur; bu yurt dışına
  aktarımdır. Aydınlatma metni buna göre güncellendi (`lib/features/ayarlar/yasal_metinler.dart`); **yayından önce bir
  hukukçuya göstermeniz önerilir.**
- **Apple ile giriş** bu sürümde yok (önce Android). iOS'a geçerken eklenir; Google girişi sunan iOS uygulamaları Apple
  girişini de sunmak zorundadır.
- Profil, kayıtlı ilan ve alarmlar şimdilik yalnızca cihazdadır (yedek koduyla taşınır). Cihazlar arası eşitleme sonraki
  aşamadır.
