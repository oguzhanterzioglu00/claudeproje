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

- `lib/core/` — tema ve ortak parçalar
- `lib/features/becayis/` — Becayiş modülü (`domain/` eşleştirme motoru)
- `test/` — birim ve widget testleri
- `docs/becayis-spec.md` — Becayiş ürün ve arka uç şartnamesi (hukuki dayanak dahil)

## Çalıştırma

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

## Yayın öncesi yapılacaklar

- Paket kimliği (`tr.com.ayasyazilim.pusula`) onaylanmalı; mağazada kalıcıdır.
- Becayiş mevzuat teyidi ve hukuk/KVKK görüşü: `docs/becayis-spec.md` §1.1 ve §8.
