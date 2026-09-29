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
- `tool/simge_uret_test.dart` — uygulama simgelerini logodan üretir: `flutter test tool/simge_uret_test.dart`
- `lib/features/profil/` — tanıtım kaydırması, 3 adımlı ilk kurulum, profil ve statü (cihazda saklanır)
- `lib/features/ana_sayfa/` — profil odaklı ana sayfa ve Gündem bölümü
- `lib/features/maas/` — memur maaş motoru ve ekranı
- `lib/features/becayis/` — Becayiş modülü (`domain/` eşleştirme motoru)
- `lib/features/asistan/`, `ilanlar/`, `haberler/` — Hakkım ne?, kamu ilanları, Gündem (şimdilik örnek servislerle)
- `test/` — birim ve widget testleri
- `docs/becayis-spec.md`, `docs/maas-spec.md`, `docs/asistan-ve-haber-spec.md` — ürün ve arka uç şartnameleri (hukuki dayanak dahil)

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

## Yayın öncesi yapılacaklar

- Paket kimliği (`tr.com.ayasyazilim.pusula`) onaylanmalı; mağazada kalıcıdır.
- Becayiş mevzuat teyidi ve hukuk/KVKK görüşü: `docs/becayis-spec.md` §1.1 ve §8.
- Maaş motorundaki vergi/SGK/asgari ücret parametreleri ikincil kaynaklıdır; resmî kaynakla doğrulanmalı (`docs/maas-spec.md`).
- Ödeme, doğrulama, asistan, ilan ve haber servisleri şimdilik örnektir; arka uç bağlanmadan yayınlanmamalı.
- Android ve iOS klasörleri repoda; gerçek cihaz/emülatörde `flutter run` ve mağaza imzalama (Android anahtar deposu, iOS sertifikaları) henüz denenmedi. Web klasörü eklenmedi; kod tabanı ayrı bir kopyada `flutter build web --release` ile başarıyla derlendi.
