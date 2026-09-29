import 'dart:convert';
import 'dart:typed_data';

import 'package:pusula/features/profil/data/fotograf_deposu.dart';

/// Geçerli 1x1 PNG (Image.memory testlerde çözümleyebilsin diye).
final Uint8List ornekPng = base64.decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// Kamera ve galeri yerine sabit sonuç veren kaynak; çağrıları sayar.
class SahteFotografKaynagi implements FotografKaynagi {
  SahteFotografKaynagi({this.sonuc, this.hata});

  final Uint8List? sonuc;
  final FotografHatasi? hata;
  int kameraCagrisi = 0;
  int galeriCagrisi = 0;

  @override
  Future<Uint8List?> cek() async {
    kameraCagrisi++;
    if (hata != null) throw hata!;
    return sonuc;
  }

  @override
  Future<Uint8List?> galeridenSec() async {
    galeriCagrisi++;
    if (hata != null) throw hata!;
    return sonuc;
  }
}
