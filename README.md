# Kadro

Memurun cebindeki maaş, ilan, becayiş ve haber asistanı. Flutter ile yazılıyor.

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

- `com.example` paket adı (`android/app/build.gradle`, iOS bundle id) gerçek kimlikle değiştirilmeli.
- Becayiş mevzuat teyidi ve hukuk/KVKK görüşü: `docs/becayis-spec.md` §1.1 ve §8.
