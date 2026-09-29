import 'dart:convert';

import '../hesap/domain/hesap.dart';
import '../profil/domain/profil.dart';

/// KVKK erişim hakkı: kullanıcının cihazdaki kişisel verilerinin okunabilir dökümü.
/// Şifre özeti gibi güvenlik verileri ve fotoğrafın kendisi dahil edilmez.
abstract final class KisiselVeriDokumu {
  static String uret({Hesap? hesap, Profil? profil, bool fotografVar = false, DateTime? zaman}) {
    final harita = <String, Object?>{
      'olusturulma': (zaman ?? DateTime.now()).toIso8601String(),
      'uygulama': 'Kamu Pusulası',
      'not':
          'Bu döküm yalnızca bu cihazda saklanan bilgilerini içerir. Şifre bilgisi ve fotoğraf dosyası dahil değildir.',
      if (hesap != null)
        'hesap': {
          'girisYontemi': hesap.saglayici.etiket,
          if (hesap.eposta.isNotEmpty) 'eposta': hesap.eposta,
          if (hesap.ad.isNotEmpty) 'ad': hesap.ad,
        },
      if (profil != null) 'profil': profil.toJson(),
      'profilFotografi': fotografVar ? 'var (dışa aktarılmadı)' : 'yok',
    };
    return const JsonEncoder.withIndent('  ').convert(harita);
  }
}
