// Uygulama simgelerini PusulaLogoRessami'ndan üretir (yeniden çizim, küçültme değil).
//
//   flutter test tool/simge_uret_test.dart
//
// Android (eski + uyarlanabilir ön plan), iOS ve web simgelerini doğrudan proje
// klasörlerine yazar. Simge tasarımı değişince yeniden çalıştırılır.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/logo.dart';

Future<void> _yaz(String yol, int px, PusulaLogoRessami ressam) async {
  final kayit = ui.PictureRecorder();
  final tuval = ui.Canvas(kayit);
  ressam.paint(tuval, ui.Size(px.toDouble(), px.toDouble()));
  final resim = await kayit.endRecording().toImage(px, px);
  final bayt = await resim.toByteData(format: ui.ImageByteFormat.png);
  final dosya = File(yol)..createSync(recursive: true);
  dosya.writeAsBytesSync(bayt!.buffer.asUint8List());
}

void main() {
  test('simgeleri üret', () async {
    // iOS: köşesiz kare, saydamlık yok (sistem köşeleri yuvarlar).
    const ios = PusulaLogoRessami(koseOrani: 0);
    const iosBoyutlar = {
      'Icon-App-20x20@1x.png': 20,
      'Icon-App-20x20@2x.png': 40,
      'Icon-App-20x20@3x.png': 60,
      'Icon-App-29x29@1x.png': 29,
      'Icon-App-29x29@2x.png': 58,
      'Icon-App-29x29@3x.png': 87,
      'Icon-App-40x40@1x.png': 40,
      'Icon-App-40x40@2x.png': 80,
      'Icon-App-40x40@3x.png': 120,
      'Icon-App-60x60@2x.png': 120,
      'Icon-App-60x60@3x.png': 180,
      'Icon-App-76x76@1x.png': 76,
      'Icon-App-76x76@2x.png': 152,
      'Icon-App-83.5x83.5@2x.png': 167,
      'Icon-App-1024x1024@1x.png': 1024,
    };
    for (final e in iosBoyutlar.entries) {
      await _yaz('ios/Runner/Assets.xcassets/AppIcon.appiconset/${e.key}', e.value, ios);
    }

    // Android eski simge (yuvarlatılmış kare) ve uyarlanabilir ön plan (108dp tuval, 66dp güvenli alan).
    const eski = PusulaLogoRessami(koseOrani: 0.22);
    const onPlan = PusulaLogoRessami(arkaplan: false, icerikOlcegi: 0.78);
    const yogunluk = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0};
    for (final e in yogunluk.entries) {
      await _yaz('android/app/src/main/res/mipmap-${e.key}/ic_launcher.png', (48 * e.value).round(), eski);
      await _yaz('android/app/src/main/res/mipmap-${e.key}/ic_launcher_foreground.png', (108 * e.value).round(), onPlan);
    }

    // Web: sekme simgesi, PWA simgeleri ve (tam kare, güvenli alanlı) maskelenebilir simgeler.
    const webSimge = PusulaLogoRessami(koseOrani: 0.22);
    const webMaske = PusulaLogoRessami(koseOrani: 0, icerikOlcegi: 0.9);
    await _yaz('web/favicon.png', 32, webSimge);
    await _yaz('web/icons/Icon-192.png', 192, webSimge);
    await _yaz('web/icons/Icon-512.png', 512, webSimge);
    await _yaz('web/icons/Icon-maskable-192.png', 192, webMaske);
    await _yaz('web/icons/Icon-maskable-512.png', 512, webMaske);
  });
}
