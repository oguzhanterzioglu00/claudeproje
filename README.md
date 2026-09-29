# Pusula

Kamu çalışanının cebindeki maaş, hak, becayiş, ilan ve haber rehberi. Flutter ile yazılıyor.

Uygulama adı çalışma adıdır; mağaza, TÜRKPATENT ve alan adı kontrolü yapılmadan kesinleşmiş sayılmaz. Yedek ad: Basamak. Paket kimliği: `tr.com.ayasyazilim.pusula` (mağazaya ilk yüklemeden önce değiştirilebilir).

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
