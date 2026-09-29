import 'eslesme.dart';
import 'ilan.dart';

/// Kurum bazlı ek kural: iki ilan bu kurala göre eşleşebilir mi?
/// Örn. Sağlık Bakanlığı'nda aynı hizmet grubu, MEB'de aynı alan.
typedef KurumKurali = bool Function(Ilan a, Ilan b);

/// Becayiş eşleştirme motoru (saf Dart, platformdan bağımsız).
///
/// Hukuki asgari (657 sayılı Kanun md. 73): aynı kurum, aynı sınıf, farklı yer.
/// Bunun üstündeki koşullar [ekKurallar] ile kurum bazında eklenir. Nihai karar
/// her zaman atamaya yetkili amirindir; motor yalnızca aday üretir.
class Eslestirici {
  const Eslestirici({this.ekKurallar = const []});

  final List<KurumKurali> ekKurallar;

  /// [a], [b]'nin bulunduğu ile yer değiştirmek istiyor ve bu anlamlı mı?
  bool _kenar(Ilan a, Ilan b) {
    if (a.id == b.id || a.kullaniciId == b.kullaniciId) return false;
    if (a.grup != b.grup) return false;
    if (normalize(a.mevcutIl) == normalize(b.mevcutIl)) return false;
    if (!a.hedefliyor(b.mevcutIl)) return false;
    return ekKurallar.every((k) => k(a, b));
  }

  /// Tüm ilanlar arasındaki eşleşmeleri bulur. [ilanId] verilirse yalnızca o
  /// ilanı içerenler döner. Sonuç: önce ikili, sonra zincir; her grupta skor
  /// azalan.
  List<Eslesme> bul(List<Ilan> ilanlar, {String? ilanId}) {
    final gruplar = <String, List<Ilan>>{};
    for (final i in ilanlar) {
      gruplar.putIfAbsent(i.grup, () => []).add(i);
    }

    final sonuc = <Eslesme>[];
    for (final grup in gruplar.values) {
      // Çıkan kenarlar: a -> b, "a, b'nin yerine gitmek istiyor".
      final cikan = <Ilan, List<Ilan>>{
        for (final a in grup) a: [for (final b in grup) if (_kenar(a, b)) b],
      };

      // İkili: a -> b ve b -> a. Her çifti bir kez üret (id sırasıyla).
      for (final a in grup) {
        for (final b in cikan[a]!) {
          if (a.id.compareTo(b.id) < 0 && cikan[b]!.contains(a)) {
            sonuc.add(_olustur(EslesmeTipi.ikili, [a, b]));
          }
        }
      }

      // 3'lü zincir: a -> b -> c -> a. Her çevrimi, en küçük id'li ilandan
      // başlatarak bir kez üret.
      for (final a in grup) {
        if (!a.zincirIzni) continue;
        for (final b in cikan[a]!) {
          if (!b.zincirIzni || a.id.compareTo(b.id) >= 0) continue;
          for (final c in cikan[b]!) {
            if (!c.zincirIzni || c.id == a.id) continue;
            if (a.id.compareTo(c.id) >= 0) continue;
            if (cikan[c]!.contains(a)) {
              sonuc.add(_olustur(EslesmeTipi.zincir, [a, b, c]));
            }
          }
        }
      }
    }

    final secilen =
        ilanId == null ? sonuc : sonuc.where((e) => e.icerir(ilanId)).toList();

    secilen.sort((x, y) {
      if (x.tip != y.tip) return x.tip == EslesmeTipi.ikili ? -1 : 1;
      final s = y.skor.compareTo(x.skor);
      return s != 0 ? s : x.id.compareTo(y.id);
    });
    return secilen;
  }

  Eslesme _olustur(EslesmeTipi tip, List<Ilan> ilanlar) {
    final n = ilanlar.length;
    final farkliUnvan =
        ilanlar.map((i) => normalize(i.unvan)).toSet().length > 1;

    // Her kenar için tercih puanı: hedef listesinde ne kadar öndeyse o kadar iyi.
    var tercih = 0.0;
    for (var k = 0; k < n; k++) {
      final giden = ilanlar[k];
      final hedef = ilanlar[(k + 1) % n]; // ikilide karşılıklı olur
      final sira = giden.hedefSirasi(hedef.mevcutIl);
      tercih += 1 - sira / giden.hedefIller.length;
    }
    tercih /= n;

    var skor = 50.0; // kurum + sınıf: yasal asgari
    if (!farkliUnvan) skor += 20;
    skor += 20 * tercih;
    if (ilanlar.every((i) => i.maviTik)) skor += 10;
    if (tip == EslesmeTipi.zincir) skor -= 10;

    return Eslesme(
      tip: tip,
      ilanlar: ilanlar,
      skor: skor.round().clamp(0, 100).toInt(),
      uyarilar: [
        if (farkliUnvan) 'Unvanlar farklı: kurum uygun bulmayabilir.',
      ],
    );
  }
}
