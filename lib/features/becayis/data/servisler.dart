/// Uygulama içi satın alma. Gerçek sürümde `in_app_purchase` ile mağaza ödemesi
/// yapılır ve makbuz sunucuda doğrulanır (bkz. docs/becayis-spec.md §4).
abstract interface class OdemeServisi {
  /// [ilanId] için iletişim açma ürününü satın alır; başarılıysa true.
  Future<bool> satinAl(String ilanId);
}

/// Kurumsal e-posta doğrulaması (bkz. docs/becayis-spec.md §5).
abstract interface class DogrulamaServisi {
  /// Yalnızca .gov.tr / .edu.tr adreslerine kod gönderir; geçersiz adreste false.
  Future<bool> kodGonder(String eposta);

  Future<bool> kodDogrula(String eposta, String kod);
}

/// Arka uç ve mağaza bağlanana kadar kullanılan sahte servisler.
class SahteOdemeServisi implements OdemeServisi {
  const SahteOdemeServisi({this.sure = const Duration(milliseconds: 1500), this.basarili = true});

  final Duration sure;
  final bool basarili;

  @override
  Future<bool> satinAl(String ilanId) async {
    await Future<void>.delayed(sure);
    return basarili;
  }
}

class SahteDogrulamaServisi implements DogrulamaServisi {
  const SahteDogrulamaServisi();

  static bool kurumsalMi(String eposta) {
    final e = eposta.trim().toLowerCase();
    return e.contains('@') && (e.endsWith('.gov.tr') || e.endsWith('.edu.tr'));
  }

  @override
  Future<bool> kodGonder(String eposta) async => kurumsalMi(eposta);

  /// Sahte: 6 haneli herhangi bir kod kabul edilir.
  @override
  Future<bool> kodDogrula(String eposta, String kod) async =>
      kurumsalMi(eposta) && RegExp(r'^\d{6}$').hasMatch(kod);
}
