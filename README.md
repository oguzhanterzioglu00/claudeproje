# Kamu Pusulası

Kamu çalışanının cebindeki maaş, hak, becayiş, ilan ve haber rehberi. Flutter ile yazılıyor.

**Ad:** Kamu Pusulası. Ana ekran simgesinin altında kısa hali "Pusula" görünür (Android `android:label`, iOS `CFBundleDisplayName`). Kod tarafında paket ve sınıf adları `pusula`/`Pusula` önekiyle gider.

Ad, mağaza, TÜRKPATENT ve alan adı kontrolü yapılmadan kesinleşmiş sayılmaz. Yedek ad: Basamak. Paket kimliği: `tr.com.ayasyazilim.pusula` (kullanıcıya görünmez; mağazaya ilk yüklemeden önce değiştirilebilir).

## Mağaza kartı önerisi

- **App Store:** Ad "Kamu Pusulası"; alt başlık "Memur ve kamu çalışanı rehberi".
- **Google Play:** Başlık "Kamu Pusulası: Maaş & Becayiş" (29 karakter; sınır 30).
- Anahtar kelimeler: maaş hesaplama, becayiş, kadro derecesi, memur, kamu ilanları, haklarım.

Tasarım: "Memur Uygulaması İlk Tasarım" (Claude Artifact). Renkler Ayas Software logosundan, ikonlar Lucide, yazı tipleri Sora ve Figtree.

## Klasörler

- `lib/core/` — tema, logo (`logo.dart`) ve ortak parçalar
- `tool/simge_uret_test.dart` — uygulama simgelerini (yazısız pusula) çizer: `flutter test tool/simge_uret_test.dart`
- `tool/marka_uret.py` — kullanıcının hazırladığı tam logodan (`tool/kaynak/`) uygulama içi görseli (`assets/marka/logo_tam.png`) üretir
- `lib/features/hesap/` — giriş/kayıt, Google ve Apple ile giriş (örnek), şifre değiştirme, hesap silme
- `lib/features/profil/` — tanıtım, 4 adımlı ilk kurulum, profil fotoğrafı, statü (cihazda saklanır)
- `lib/features/ana_sayfa/` — profil odaklı ana sayfa ve Gündem bölümü
- `lib/features/maas/` — memur maaş motoru ve ekranı
- `lib/features/becayis/` — Becayiş modülü (`domain/` eşleştirme motoru)
- `lib/features/asistan/`, `ilanlar/`, `haberler/` — Hakkım ne? (doğrulanmış mevzuat), kamu ilanları (Kariyer Kapısı), Gündem (Resmî Gazete); veri akışı `tool/feed_uret.py` + `.github/workflows/feed.yml` ile 15 dakikada bir derlenir (`docs/asistan-ve-haber-spec.md` §2.1)
- `test/` — birim ve widget testleri
- `docs/becayis-spec.md`, `docs/maas-spec.md`, `docs/asistan-ve-haber-spec.md`, `docs/hesap-spec.md` — ürün ve arka uç şartnameleri (hukuki dayanak dahil)

## Çalıştırma

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

## Telefona kurmak (APK)

Her push'ta GitHub Actions (`.github/workflows/apk.yml`) analiz ve testleri çalıştırıp deneme APK'sı üretir:
GitHub'da **Actions** sekmesi → son çalışma → **Artifacts** → `kamu-pusulasi-apk` indir → zip'i aç →
`app-release.apk`'yı Android telefonda aç (ilk seferde "bilinmeyen kaynaklardan yüklemeye izin ver" gerekir).
Bu APK debug anahtarıyla imzalıdır; yalnızca deneme içindir.

## Tarayıcıda önizleme (APK indirmeden)

Her push'ta `.github/workflows/web.yml` uygulamanın web sürümünü derler ve `gh-pages` dalına yayınlar.
Bilgisayarda telefon boyutlu bir çerçevede, telefon tarayıcısında tam ekran açılır.

**Bir kez yapılacak ayar (GitHub Pages):** repo → Settings → Pages → *Build and deployment* → Source: **Deploy from a branch**,
Branch: **gh-pages** / **(root)** → Save. Adres: `https://<kullanıcı>.github.io/<repo>/` (birkaç dakika sürer).

> Depo **özel (private)** ise GitHub Pages ücretsiz planda çalışmaz. İki seçenek: (1) depoyu herkese açık yapmak, ya da
> (2) ücretsiz Netlify: netlify.com'da hesap aç → *Add new site → Deploy manually* ile boş bir site oluştur →
> Site ID'yi ve (User settings → Applications → Personal access token) jetonunu repoda
> Settings → Secrets and variables → Actions'a `NETLIFY_SITE_ID` ve `NETLIFY_AUTH_TOKEN` adıyla ekle. Sonraki her push'ta site güncellenir.

Yeni sürüm görünmezse sayfayı sert yenile (Ctrl+Shift+R). Web sürümünde kamera/galeri, tarayıcı izinlerine bağlıdır;
gerçek cihaz davranışı için APK kullan.

## Yayın öncesi yapılacaklar

- Paket kimliği (`tr.com.ayasyazilim.pusula`) onaylanmalı; mağazada kalıcıdır.
- Becayiş mevzuat teyidi ve hukuk/KVKK görüşü: `docs/becayis-spec.md` §1.1 ve §8.
- Maaş motorundaki vergi/SGK/asgari ücret parametreleri ikincil kaynaklıdır; resmî kaynakla doğrulanmalı (`docs/maas-spec.md`).
- Ödeme ve doğrulama servisleri şimdilik örnektir. İlan (Kariyer Kapısı RSS) ve haber (Resmî Gazete) akışı gerçektir ama arka uçsuz (GitHub Actions + `feed-data` dalı) çalışır; ilanlarda son başvuru tarihi yoktur, uygulama kapalıyken anlık bildirim için sunucu tarafı push gerekir (`docs/asistan-ve-haber-spec.md` §2.1).
- Hesaplar cihazda tutulur; **Google ve Apple ile giriş gerçek değildir** (örnek hesap açar). Gerçek kimlik sağlayıcı, sağlayıcıların resmî düğme varlıkları ve Kullanım Koşulları/Aydınlatma metinleri hazırlanmadan yayınlanmamalı (`docs/hesap-spec.md`).
- Android ve iOS klasörleri repoda; gerçek cihaz/emülatörde `flutter run` ve mağaza imzalama (Android anahtar deposu, iOS sertifikaları) henüz denenmedi. Web klasörü eklenmedi; kod tabanı ayrı bir kopyada `flutter build web --release` ile başarıyla derlendi.
