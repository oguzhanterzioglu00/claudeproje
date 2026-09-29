/// 657 sayılı Kanun md. 102-103'e göre yıllık izin hakkı hesabı.
///
/// Kanun: hizmeti 1 yıldan 10 yıla kadar (10 yıl dahil) olanlara 20 gün, 10 yıldan
/// fazla olanlara 30 gün; cari yıl ile bir önceki yıl hariç, önceki yıllara ait
/// kullanılmayan izin hakları düşer. Zorunlu hâllerde gidiş-dönüş için en çok ikişer gün eklenebilir.
///
/// Hangi sürelerin "hizmet yılı"na sayıldığı kanunun dışındaki düzenlemelere ve kurum
/// uygulamasına bağlıdır; bu hesap kullanıcının girdiği hizmet yılına göre bir tahmindir.
class IzinSonucu {
  const IzinSonucu({
    required this.yillikHak,
    required this.devreden,
    required this.buYilKullanilan,
    required this.hizmetYiliYetersiz,
  });

  /// Bu yıl için kanundaki yıllık izin süresi (gün); hizmet 1 yıldan azsa 0.
  final int yillikHak;

  /// Geçen yıldan devreden (kullanılmamış) gün.
  final int devreden;
  final int buYilKullanilan;

  /// Hizmet süresi 1 yıldan az: kanundaki süreler uygulanmaz.
  final bool hizmetYiliYetersiz;

  int get toplamHak => yillikHak + devreden;

  /// Kullanılabilecek kalan gün; fazla kullanılmışsa negatif.
  int get kalan => toplamHak - buYilKullanilan;

  /// Zorunlu hâllerde gidiş ve dönüş için eklenebilecek en çok gün (2 + 2).
  static const gidisDonusEnFazla = 4;
}

abstract final class IzinHesaplayici {
  static const enFazlaGun = 30;

  /// [hizmetYili] tamamlanmış hizmet yılı.
  static int yillikHak(int hizmetYili) {
    if (hizmetYili < 1) return 0;
    return hizmetYili <= 10 ? 20 : 30;
  }

  /// [gecenYildanKalan]: geçen yıl hakkından kullanılmayan gün. Geçen yılın hakkını
  /// aşamaz (o yıl hakkı [hizmetYili] - 1 yıla göre bulunur); ondan önceki yıllardan
  /// kalanlar kanunen düştüğü için sorulmaz.
  static IzinSonucu hesapla({
    required int hizmetYili,
    required int gecenYildanKalan,
    required int buYilKullanilan,
  }) {
    final hak = yillikHak(hizmetYili);
    final gecenYilHak = yillikHak(hizmetYili - 1);
    final devreden = gecenYildanKalan.clamp(0, gecenYilHak).toInt();
    return IzinSonucu(
      yillikHak: hak,
      devreden: devreden,
      buYilKullanilan: buYilKullanilan < 0 ? 0 : buYilKullanilan,
      hizmetYiliYetersiz: hizmetYili < 1,
    );
  }
}
