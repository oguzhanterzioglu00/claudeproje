import 'package:flutter/services.dart';

/// Testlerde gerçek Sora ve Figtree ölçüleriyle çizim yapmak için gömülü
/// yazı tiplerini yükler. Yüklenmezse test varsayılan "Ahem" yazısını kullanır
/// (her harf kare) ve yerleşim hataları gerçek dışı çıkar.
Future<void> pusulaYazilariniYukle() async {
  Future<void> yukle(String aile, List<String> dosyalar) async {
    final yukleyici = FontLoader(aile);
    for (final d in dosyalar) {
      yukleyici.addFont(rootBundle.load('assets/fonts/$d'));
    }
    await yukleyici.load();
  }

  await yukle('Sora', [
    'Sora-Medium.ttf',
    'Sora-SemiBold.ttf',
    'Sora-Bold.ttf',
    'Sora-ExtraBold.ttf',
  ]);
  // Lucide ikonları paket yazı tipiyle gelir; testte de yüklenmezse kare görünür.
  final lucide = FontLoader('packages/lucide_icons_flutter/Lucide')
    ..addFont(rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'));
  await lucide.load();
  await yukle('Figtree', [
    'Figtree-Regular.ttf',
    'Figtree-Medium.ttf',
    'Figtree-SemiBold.ttf',
    'Figtree-Bold.ttf',
  ]);
}
