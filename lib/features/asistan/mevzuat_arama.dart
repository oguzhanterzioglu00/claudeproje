import 'package:flutter/foundation.dart';

import '../../core/metin.dart';
import 'asistan_servisi.dart';
import 'bilgi_bankasi.dart';

/// Aramada bulunan bir kanun maddesi alıntısı.
@immutable
class AramaSonucu {
  const AramaSonucu({
    required this.konu,
    required this.kaynak,
    required this.parca,
    required this.vurgular,
    required this.puan,
  });

  final BilgiKonusu konu;
  final MevzuatKaynagi kaynak;

  /// Eşleşmenin çevresinden alınan kısa metin parçası (başı/sonu "…" ile kesilmiş olabilir).
  final String parca;

  /// [parca] içindeki eşleşen aralıklar (başlangıç, bitiş); ekranda vurgulanır.
  final List<(int, int)> vurgular;
  final int puan;
}

/// Doğrulanmış mevzuat bilgi bankasında ([BilgiBankasi]) tam metin arama. Yeni içerik üretmez, yalnızca var olan
/// kanun alıntılarını ve madde başlıklarını tarar; Türkçe harf farkını yok sayar ("zabit" ile "zabıt" aynıdır).
abstract final class MevzuatArama {
  static const enFazla = 30;
  static const _cevre = 70;

  /// [kitle] verilirse yalnızca o gruba ve herkese yönelik konular taranır. Tüm sözcükler bulunmalıdır.
  static List<AramaSonucu> ara(String sorgu, {Kitle? kitle, List<BilgiKonusu>? konular}) {
    final sozcukler = aramaAnahtari(sorgu).split(RegExp(r'\s+')).where((s) => s.length >= 2).toSet().toList();
    if (sozcukler.isEmpty) return const [];

    final sonuclar = <AramaSonucu>[];
    for (final k in konular ?? BilgiBankasi.konular) {
      if (k.kapsamDisi) continue;
      if (kitle != null && k.kitle != Kitle.herkes && k.kitle != kitle) continue;
      for (final kaynak in k.kaynaklar) {
        final alinti = kaynak.alinti ?? '';
        final baslikAnahtar = aramaAnahtari(kaynak.baslik);
        // Konu adı da aranır: kanun metni "becayiş" sözcüğünü kullanmaz ama konunun adı "Becayiş"tir.
        final konuAnahtar = aramaAnahtari('${k.baslik} ${k.etiket}');
        final metinAnahtar = aramaAnahtari(alinti);
        final hepsi = '$baslikAnahtar $konuAnahtar $metinAnahtar';
        if (!sozcukler.every(hepsi.contains)) continue;

        var puan = 0;
        for (final s in sozcukler) {
          if (baslikAnahtar.contains(s)) puan += 5;
          if (konuAnahtar.contains(s)) puan += 3;
          puan += s.allMatches(metinAnahtar).length.clamp(0, 5);
        }
        final (parca, vurgular) = _parca(alinti, metinAnahtar, sozcukler);
        sonuclar.add(AramaSonucu(konu: k, kaynak: kaynak, parca: parca, vurgular: vurgular, puan: puan));
      }
    }
    sonuclar.sort((a, b) => b.puan.compareTo(a.puan));
    return sonuclar.take(enFazla).toList();
  }

  /// İlk eşleşmenin çevresinden bir parça ve parçadaki vurgu aralıkları. Normalleştirme uzunluğu değiştirirse
  /// (olağan dışı) vurgu verilmez, parça metnin başından alınır.
  static (String, List<(int, int)>) _parca(String alinti, String anahtar, List<String> sozcukler) {
    if (alinti.isEmpty) return ('', const []);
    if (alinti.length != anahtar.length) {
      return (alinti.length <= 2 * _cevre ? alinti : '${alinti.substring(0, 2 * _cevre)}…', const []);
    }
    var ilk = -1;
    for (final s in sozcukler) {
      final i = anahtar.indexOf(s);
      if (i >= 0 && (ilk < 0 || i < ilk)) ilk = i;
    }
    final bas = ilk <= _cevre ? 0 : _bosluktanSonra(alinti, ilk - _cevre);
    final son = (ilk < 0 ? 2 * _cevre : ilk + _cevre).clamp(0, alinti.length);
    final bitis = son >= alinti.length ? alinti.length : _bosluktanOnce(alinti, son);
    final parca = '${bas > 0 ? '…' : ''}${alinti.substring(bas, bitis)}${bitis < alinti.length ? '…' : ''}';
    final kayma = bas > 0 ? 1 : 0;
    final altAnahtar = anahtar.substring(bas, bitis);
    final vurgular = <(int, int)>[];
    for (final s in sozcukler) {
      for (final m in s.allMatches(altAnahtar)) {
        vurgular.add((m.start + kayma, m.end + kayma));
      }
    }
    vurgular.sort((a, b) => a.$1.compareTo(b.$1));
    return (parca, _birlestir(vurgular));
  }

  static int _bosluktanSonra(String s, int i) {
    final j = s.indexOf(' ', i);
    return j < 0 ? i : j + 1;
  }

  static int _bosluktanOnce(String s, int i) {
    final j = s.lastIndexOf(' ', i);
    return j <= 0 ? i : j;
  }

  static List<(int, int)> _birlestir(List<(int, int)> aralik) {
    final cikis = <(int, int)>[];
    for (final a in aralik) {
      if (cikis.isNotEmpty && a.$1 <= cikis.last.$2) {
        final son = cikis.removeLast();
        cikis.add((son.$1, a.$2 > son.$2 ? a.$2 : son.$2));
      } else {
        cikis.add(a);
      }
    }
    return cikis;
  }
}
