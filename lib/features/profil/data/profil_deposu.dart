import 'package:flutter/foundation.dart';

import '../domain/profil.dart';
import 'profil_kaydi.dart';

/// Uygulamanın tek profil kaynağı; ekranlar buna dinler.
class ProfilDeposu extends ChangeNotifier {
  ProfilDeposu(this._kayit);

  final ProfilKaydi _kayit;

  Profil? _profil;
  bool _yuklendi = false;

  Profil? get profil => _profil;

  /// Kayıtlı profil okundu mu (açılışta yükleme ekranı için).
  bool get yuklendi => _yuklendi;

  Future<void> yukle() async {
    try {
      _profil = await _kayit.yukle();
    } catch (_) {
      _profil = null;
    }
    _yuklendi = true;
    notifyListeners();
  }

  Future<void> kaydet(Profil profil) async {
    _profil = profil;
    notifyListeners();
    await _kayit.kaydet(profil);
  }

  /// Kullanıcının silme hakkı: profil cihazdan tamamen kaldırılır.
  Future<void> sil() async {
    _profil = null;
    notifyListeners();
    await _kayit.sil();
  }
}
