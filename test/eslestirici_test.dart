import 'package:flutter_test/flutter_test.dart';
import 'package:kadro/features/becayis/domain/eslesme.dart';
import 'package:kadro/features/becayis/domain/eslestirici.dart';
import 'package:kadro/features/becayis/domain/ilan.dart';

Ilan ilan(
  String id,
  String il,
  List<String> hedef, {
  String kurum = 'SB',
  String sinif = 'Sağlık Hizmetleri',
  String unvan = 'Hemşire',
  String? kullanici,
  bool zincir = true,
  bool tik = false,
}) =>
    Ilan(
      id: id,
      kullaniciId: kullanici ?? 'u$id',
      kurumId: kurum,
      sinif: sinif,
      unvan: unvan,
      mevcutIl: il,
      hedefIller: hedef,
      zincirIzni: zincir,
      maviTik: tik,
    );

void main() {
  const e = Eslestirici();

  group('ikili eşleşme', () {
    test('karşılıklı istekler eşleşir, kurum + sınıf + unvan aynıysa skor 90', () {
      final r = e.bul([
        ilan('a', 'İzmir', ['Ankara']),
        ilan('b', 'Ankara', ['İzmir']),
      ]);
      expect(r, hasLength(1));
      expect(r.single.tip, EslesmeTipi.ikili);
      expect(r.single.skor, 90);
      expect(r.single.uyarilar, isEmpty);
    });

    test('tek yönlü istek eşleşme üretmez', () {
      final r = e.bul([
        ilan('a', 'İzmir', ['Ankara']),
        ilan('b', 'Ankara', ['Bursa']),
      ]);
      expect(r, isEmpty);
    });

    test('farklı kurum veya farklı sınıf eşleşmez', () {
      expect(
        e.bul([
          ilan('a', 'İzmir', ['Ankara']),
          ilan('b', 'Ankara', ['İzmir'], kurum: 'MEB'),
        ]),
        isEmpty,
      );
      expect(
        e.bul([
          ilan('a', 'İzmir', ['Ankara']),
          ilan('b', 'Ankara', ['İzmir'], sinif: 'Genel İdare Hizmetleri'),
        ]),
        isEmpty,
      );
    });

    test('aynı sınıfta farklı unvan yasal olarak eşleşir ama uyarı ve düşük skor alır', () {
      final r = e.bul([
        ilan('a', 'İzmir', ['Ankara'], unvan: 'Hemşire'),
        ilan('b', 'Ankara', ['İzmir'], unvan: 'Ebe'),
      ]);
      expect(r, hasLength(1));
      expect(r.single.skor, 70);
      expect(r.single.uyarilar, hasLength(1));
    });

    test('aynı kullanıcının iki ilanı birbiriyle eşleşmez', () {
      final r = e.bul([
        ilan('a', 'İzmir', ['Ankara'], kullanici: 'x'),
        ilan('b', 'Ankara', ['İzmir'], kullanici: 'x'),
      ]);
      expect(r, isEmpty);
    });

    test('hedef sırası skoru etkiler', () {
      final r = e.bul([
        ilan('a', 'İzmir', ['Bursa', 'Ankara']), // Ankara ikinci tercih: 0.5
        ilan('b', 'Ankara', ['İzmir']), // birinci tercih: 1.0
      ]);
      expect(r.single.skor, 85); // 50 + 20 + 20 * 0.75
    });

    test('iki tarafın da mavi tiki varsa +10', () {
      final r = e.bul([
        ilan('a', 'İzmir', ['Ankara'], tik: true),
        ilan('b', 'Ankara', ['İzmir'], tik: true),
      ]);
      expect(r.single.skor, 100);
    });

    test('il adı büyük/küçük harf ve Türkçe harf farkından etkilenmez', () {
      final r = e.bul([
        ilan('a', 'Iğdır', ['İZMİR']),
        ilan('b', 'izmir', ['IĞDIR']),
      ]);
      expect(r, hasLength(1));
    });

    test('kurum ek kuralı false dönerse eşleşme çıkmaz', () {
      const sert = Eslestirici(ekKurallar: [_hicbirini]);
      final r = sert.bul([
        ilan('a', 'İzmir', ['Ankara']),
        ilan('b', 'Ankara', ['İzmir']),
      ]);
      expect(r, isEmpty);
    });
  });

  group('3\'lü zincir', () {
    List<Ilan> uclu() => [
          ilan('a', 'İzmir', ['Ankara']),
          ilan('b', 'Ankara', ['Bursa']),
          ilan('c', 'Bursa', ['İzmir']),
        ];

    test('A→B→C→A çevrimi bir kez bulunur, skor 80', () {
      final r = e.bul(uclu());
      expect(r, hasLength(1));
      expect(r.single.tip, EslesmeTipi.zincir);
      expect(r.single.ilanlar.map((i) => i.id), ['a', 'b', 'c']);
      expect(r.single.skor, 80); // 50 + 20 + 20 - 10
    });

    test('liste sırası değişse de aynı çevrim tek kez döner', () {
      final l = uclu();
      final r = e.bul([l[2], l[0], l[1]]);
      expect(r, hasLength(1));
      expect(r.single.id, e.bul(uclu()).single.id);
    });

    test('zincir izni vermeyen ilan zincire alınmaz', () {
      final r = e.bul([
        ilan('a', 'İzmir', ['Ankara']),
        ilan('b', 'Ankara', ['Bursa'], zincir: false),
        ilan('c', 'Bursa', ['İzmir']),
      ]);
      expect(r, isEmpty);
    });
  });

  group('filtre ve sıralama', () {
    test('ilanId verilirse yalnızca o ilanı içeren eşleşmeler döner', () {
      final r = e.bul([
        ilan('a', 'İzmir', ['Ankara']),
        ilan('b', 'Ankara', ['İzmir']),
        ilan('c', 'Bursa', ['Konya'], kurum: 'MEB'),
        ilan('d', 'Konya', ['Bursa'], kurum: 'MEB'),
      ], ilanId: 'c');
      expect(r, hasLength(1));
      expect(r.single.icerir('d'), isTrue);
      expect(r.single.icerir('a'), isFalse);
    });

    test('ikili eşleşmeler zincirlerden önce gelir', () {
      final r = e.bul([
        ilan('a', 'İzmir', ['Ankara']),
        ilan('b', 'Ankara', ['İzmir']),
        ilan('x', 'İzmir', ['Ankara'], kurum: 'MEB', tik: true),
        ilan('y', 'Ankara', ['Bursa'], kurum: 'MEB', tik: true),
        ilan('z', 'Bursa', ['İzmir'], kurum: 'MEB', tik: true),
      ]);
      expect(r, hasLength(2));
      expect(r.first.tip, EslesmeTipi.ikili);
      expect(r.last.tip, EslesmeTipi.zincir);
    });
  });
}

bool _hicbirini(Ilan a, Ilan b) => false;
