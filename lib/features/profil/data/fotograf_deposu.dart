import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/depolama.dart';

/// Kullanıcıya gösterilebilir fotoğraf hatası.
class FotografHatasi implements Exception {
  const FotografHatasi(this.mesaj);

  final String mesaj;

  @override
  String toString() => mesaj;
}

/// Fotoğrafın nereden alınacağı. Gerçek uygulama kamera/galeriyi kullanır,
/// testler sahte kaynak verir.
abstract interface class FotografKaynagi {
  /// Kullanıcı vazgeçerse null döner.
  Future<Uint8List?> cek();
  Future<Uint8List?> galeridenSec();
}

/// `image_picker` ile kamera ve galeri. Görüntü seçim sırasında 720 px'e küçültülür
/// (saklama boyutu ve gizlilik için gereğinden büyük fotoğraf tutulmaz).
class ImagePickerFotografKaynagi implements FotografKaynagi {
  const ImagePickerFotografKaynagi();

  Future<Uint8List?> _al(ImageSource kaynak) async {
    try {
      final dosya = await ImagePicker().pickImage(
        source: kaynak,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      return dosya == null ? null : await dosya.readAsBytes();
    } catch (_) {
      throw FotografHatasi(kaynak == ImageSource.camera
          ? 'Kameraya erişilemedi. Ayarlardan kamera iznini kontrol et.'
          : 'Galeriye erişilemedi. Ayarlardan fotoğraf iznini kontrol et.');
    }
  }

  @override
  Future<Uint8List?> cek() => _al(ImageSource.camera);

  @override
  Future<Uint8List?> galeridenSec() => _al(ImageSource.gallery);
}

/// Profil fotoğrafının cihazdaki tek kaynağı. Fotoğraf yalnızca bu cihazda saklanır.
class FotografDeposu extends ChangeNotifier {
  FotografDeposu(this._depo, {this.anahtar = 'profil_foto_v1'});

  /// Saklanabilecek en büyük fotoğraf (bayt).
  static const enBuyukBoyut = 1500000;

  final AnahtarDeger _depo;
  final String anahtar;

  Uint8List? _foto;
  bool _yuklendi = false;

  Uint8List? get foto => _foto;
  bool get yuklendi => _yuklendi;

  Future<void> yukle() async {
    try {
      final metin = await _depo.oku(anahtar);
      _foto = metin == null ? null : base64.decode(metin);
    } catch (_) {
      _foto = null; // bozuk kayıt
    }
    _yuklendi = true;
    notifyListeners();
  }

  Future<void> ayarla(Uint8List bayt) async {
    if (bayt.isEmpty) throw const FotografHatasi('Fotoğraf okunamadı');
    if (bayt.length > enBuyukBoyut) throw const FotografHatasi('Fotoğraf çok büyük; daha küçük bir tane seç');
    _foto = bayt;
    notifyListeners();
    await _depo.yaz(anahtar, base64.encode(bayt));
  }

  Future<void> kaldir() async {
    _foto = null;
    notifyListeners();
    await _depo.sil(anahtar);
  }
}
