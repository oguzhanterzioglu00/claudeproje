# Hesap, giriş ve profil fotoğrafı

Bu belge, uygulamadaki hesap katmanının bugünkü durumunu ve gerçek arka uç bağlanırken yapılacakları anlatır.

## 1. Bugünkü durum (örnek sürüm)

- **Akış:** tanıtım (yalnızca ilk kez) → giriş/hesap oluştur → 4 adımlı profil kurulumu → "hazırlanıyor" animasyonu → ana sayfa. Kod: `lib/features/kabuk/uygulama_akisi.dart`.
- **Hesap servisi:** `KimlikServisi` arayüzü; şimdilik `YerelKimlikServisi` uygular. Hesaplar **yalnızca cihazda** tutulur, sunucuya hiçbir şey gitmez. Şifreler düz metin değil, tuzlu PBKDF2-HMAC-SHA256 özetiyle saklanır. Giriş hatası "hesap yok" ile "şifre yanlış"ı ayırt ettirmez.
- **Google / Apple ile giriş:** **gerçek değil.** Düğmeler çalışır ama kullanıcıya bunun örnek olduğu söylenir ve örnek bir hesap açılır. Ekranda "ÖRNEK" rozeti vardır.
- **Şifre değiştirme:** mevcut şifre doğrulanır; yeni şifre en az 8 karakter, harf ve rakam içermelidir ve eskisinden farklı olmalıdır. Google/Apple hesaplarında şifre alanı yoktur.
- **Şifremi unuttum:** yalnızca e-posta biçimini denetler; örnek sürümde e-posta gönderilmez (ekranda belirtilir).
- **Çıkış / hesabı silme:** profil ve fotoğraf hesap kimliğine göre ayrı saklanır (aynı telefonda iki hesap birbirinin verisini görmez). Hesabı silme hesabı, profili ve fotoğrafı cihazdan siler.
- **Profil fotoğrafı:** kamera veya galeriden (`image_picker`), 720 px'e küçültülerek ve en çok 1,5 MB olarak **yalnızca cihazda** saklanır. Fotoğraf yoksa adın baş harfleri gösterilir.

## 2. Arka uç bağlanırken yapılacaklar

1. `KimlikServisi`'ni gerçek bir kimlik sağlayıcıyla uygula (ör. Firebase Auth, Supabase Auth ya da kendi sunucu). `OturumDeposu` ve ekranlar değişmez.
2. **Google ile giriş:** OAuth istemci kimlikleri (Android SHA-1, iOS URL şeması) ve onay ekranı yapılandırması gerekir.
3. **Apple ile giriş:** Apple Developer hesabı, "Sign in with Apple" yeteneği ve Services ID gerekir. **Apple kuralı:** iOS uygulaması Google gibi üçüncü taraf girişi sunuyorsa Apple ile girişi de sunmak zorundadır (Uygulama İnceleme 4.8).
4. Düğme görselleri sağlayıcıların **resmî varlıkları ve yönergeleriyle** değiştirilmelidir (şimdiki Google "G" ve Apple simgesi sadeleştirilmiş çizimlerdir).
5. **Hesap silme:** mağaza kuralları (özellikle Apple 5.1.1(v)) gereği uygulama içinden hesabı silmek zorunludur; sunucuda da kalıcı silme (KVKK silme hakkı) uygulanmalıdır. `KimlikServisi.hesabiSil` bunun için vardır.
6. **Şifre sıfırlama:** sunucu tarafında zaman sınırlı, tek kullanımlık bağlantı e-postası; yanıtta hesabın var olup olmadığı belli edilmemelidir.
7. **Oturum güvenliği:** jetonlar `flutter_secure_storage` gibi güvenli depoda tutulmalı; `shared_preferences` yalnızca gizli olmayan verilere uygundur.
8. **KVKK:** aydınlatma metni ve kullanım koşulları veri sorumlusunun (Ayas Yazılım) KVKK sayfalarındaki bilgilerle dolduruldu (`lib/features/ayarlar/yasal_metinler.dart`). Sunucu tabanlı özellik eklenirken bu metinler (aktarım, saklama, yurt dışı) güncellenmelidir. Profil ve fotoğrafın sunucuyla eşitlenmesi ancak açık rızayla yapılmalıdır.
9. Fotoğraf sunucuya yüklenecekse boyut/tür denetimi, virüs taraması ve silme (hesapla birlikte) tanımlanmalıdır.

## 3. Bilinen sınırlar

- Hesaplar cihazlar arasında eşitlenmez; telefon değişince kaybolur.
- Şifremi unuttum ve Google/Apple girişi örnektir (bkz. §1).
- Tanıtım "görüldü" bilgisi cihazdadır; uygulama verisi silinirse yeniden görünür.
