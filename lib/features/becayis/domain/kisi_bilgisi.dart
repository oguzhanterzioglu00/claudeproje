/// Eşleşme ödendikten sonra açılan kişi bilgileri (dilekçe ve iletişim için).
/// Arka uçtan yalnızca yetki varken gelir; istemcide önceden tutulmaz.
class KisiBilgisi {
  const KisiBilgisi({
    required this.tamAd,
    required this.sicilNo,
    required this.telefon,
    required this.eposta,
  });

  final String tamAd;
  final String sicilNo;
  final String telefon;
  final String eposta;
}
