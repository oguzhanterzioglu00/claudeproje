/// Giriş yöntemi.
enum GirisSaglayici {
  eposta('E-posta'),
  google('Google'),
  apple('Apple');

  const GirisSaglayici(this.etiket);

  final String etiket;
}

/// Oturum açmış kullanıcı hesabı. Kişisel profil bilgileri (statü, kurum vb.)
/// ayrıdır; bkz. `Profil`.
class Hesap {
  const Hesap({required this.id, required this.saglayici, this.eposta = '', this.ad = ''});

  final String id;
  final GirisSaglayici saglayici;

  /// Google/Apple örnek girişlerinde boş olabilir.
  final String eposta;
  final String ad;

  bool get sifreliHesap => saglayici == GirisSaglayici.eposta;

  Map<String, Object?> toJson() => {'id': id, 'saglayici': saglayici.name, 'eposta': eposta, 'ad': ad};

  /// Bozuk kayıtta hata fırlatmaz; okunamıyorsa null döner.
  static Hesap? fromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'];
    if (id is! String || id.isEmpty) return null;
    final saglayici = GirisSaglayici.values.where((s) => s.name == j['saglayici']).firstOrNull;
    if (saglayici == null) return null;
    return Hesap(
      id: id,
      saglayici: saglayici,
      eposta: j['eposta'] is String ? j['eposta'] as String : '',
      ad: j['ad'] is String ? j['ad'] as String : '',
    );
  }
}

/// Giriş/kayıt kuralları.
abstract final class HesapKurali {
  static final _epostaDeseni = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static bool epostaGecerli(String s) => _epostaDeseni.hasMatch(s.trim());

  /// Şifre uygunsa null, değilse kullanıcıya gösterilecek açıklama.
  static String? sifreHatasi(String s) {
    if (s.length < 8) return 'Şifre en az 8 karakter olmalı';
    if (!s.contains(RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşü]'))) return 'Şifrede en az bir harf olmalı';
    if (!s.contains(RegExp(r'\d'))) return 'Şifrede en az bir rakam olmalı';
    return null;
  }
}
