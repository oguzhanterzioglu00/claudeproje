import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/profil.dart';

/// Profilin kalıcı saklanması. Şimdilik yalnızca cihazda; arka uç bağlanınca
/// açık rıza ve KVKK aydınlatmasıyla eşitleme eklenir.
abstract interface class ProfilKaydi {
  Future<Profil?> yukle();
  Future<void> kaydet(Profil profil);
  Future<void> sil();
}

/// Testler ve geçici kullanım için bellek içi kayıt.
class BellekProfilKaydi implements ProfilKaydi {
  BellekProfilKaydi([this._profil]);

  Profil? _profil;

  @override
  Future<Profil?> yukle() async => _profil;

  @override
  Future<void> kaydet(Profil profil) async => _profil = profil;

  @override
  Future<void> sil() async => _profil = null;
}

/// `shared_preferences` ile cihazda saklar. Bozuk kayıt sessizce yok sayılır
/// (kullanıcı profilini yeniden girer); uygulama çökmez.
class YerelProfilKaydi implements ProfilKaydi {
  const YerelProfilKaydi();

  static const anahtar = 'profil_v1';

  @override
  Future<Profil?> yukle() async {
    final prefs = await SharedPreferences.getInstance();
    final metin = prefs.getString(anahtar);
    if (metin == null) return null;
    try {
      final j = jsonDecode(metin);
      if (j is Map<String, Object?>) return Profil.fromJson(j);
    } catch (_) {
      // bozuk kayıt
    }
    return null;
  }

  @override
  Future<void> kaydet(Profil profil) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(anahtar, jsonEncode(profil.toJson()));
  }

  @override
  Future<void> sil() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(anahtar);
  }
}
