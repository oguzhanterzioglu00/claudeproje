import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/features/becayis/data/becayis_deposu.dart';
import 'package:pusula/features/becayis/domain/ilan.dart';

class _Kaynak implements BecayisIlanKaynagi {
  _Kaynak(this.ilanlar, {this.hata = false});

  final List<Ilan> ilanlar;
  final bool hata;
  Ilan? kaydedilen;
  bool kapatildi = false;

  @override
  Future<List<Ilan>> getir() async {
    if (hata) throw Exception('ağ');
    return List.of(ilanlar);
  }

  @override
  Future<void> kaydet(Ilan ilan) async {
    if (hata) throw Exception('ağ');
    kaydedilen = ilan;
  }

  @override
  Future<void> kapat() async {
    if (hata) throw Exception('ağ');
    kapatildi = true;
  }
}

Ilan _ilan(String id, String il, List<String> hedef) => Ilan(
  id: id,
  kullaniciId: id,
  kurumId: 'saglik-bakanligi',
  kurumAdi: 'Sağlık Bakanlığı',
  sinif: 'Sağlık Hizmetleri',
  unvan: 'Hemşire',
  mevcutIl: il,
  hedefIller: hedef,
  gorunenAd: id == 'ben' ? 'Sen' : 'A. Kullanıcı',
);

BecayisDeposu _depo(_Kaynak kaynak) => BecayisDeposu(
  benim: _ilan('ben', 'İzmir', const []),
  digerleri: const [],
  kisiler: const {},
  epostam: '',
  ilanKaynagi: kaynak,
  iletisimOzelligiAktif: false,
  dogrulamaAktif: false,
  yayinda: false,
);

void main() {
  test(
    'uzak ilanları yükler, kendi ilanını ayırır ve eşleşmeyi hesaplar',
    () async {
      final kaynak = _Kaynak([
        _ilan('ben', 'İzmir', const ['Ankara']),
        _ilan('diger', 'Ankara', const ['İzmir']),
      ]);
      final depo = _depo(kaynak);

      expect(await depo.yenile(), isTrue);
      expect(depo.yayinda, isTrue);
      expect(depo.digerleri.single.id, 'diger');
      expect(depo.eslesmeler, hasLength(1));
    },
  );

  test('ilanı kaynağa yazar ve kapatabilir', () async {
    final kaynak = _Kaynak([]);
    final depo = _depo(kaynak);

    expect(
      await depo.ilanYayinla(hedefIller: const ['Ankara'], zincirIzni: false),
      isTrue,
    );
    expect(kaynak.kaydedilen?.hedefIller, const ['Ankara']);
    expect(depo.yayinda, isTrue);

    expect(await depo.ilanKapat(), isTrue);
    expect(kaynak.kapatildi, isTrue);
    expect(depo.yayinda, isFalse);
  });

  test(
    'ağ hatasında ilanı açmaz ve kullanıcıya anlaşılır hata verir',
    () async {
      final depo = _depo(_Kaynak([], hata: true));
      expect(
        await depo.ilanYayinla(hedefIller: const ['Ankara'], zincirIzni: false),
        isFalse,
      );
      expect(depo.yayinda, isFalse);
      expect(depo.hata, contains('yayınlanamadı'));
    },
  );
}
