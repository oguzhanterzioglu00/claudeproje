import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/depolama.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/ayarlar/ayarlar_sayfasi.dart';
import 'package:pusula/features/hatirlatici/hatirlatici_servisi.dart';
import 'package:pusula/features/ilanlar/ilan_kaynagi.dart';
import 'package:pusula/features/ilanlar/ilan_modeli.dart';
import 'package:pusula/features/becayis/data/ornek_veri.dart';
import 'package:pusula/features/haberler/haber_kaynagi.dart';
import 'package:pusula/features/ilanlar/yeni_ilan_takibi.dart';
import 'package:pusula/features/kabuk/pusula_kabugu.dart';
import 'package:pusula/features/profil/data/profil_deposu.dart';
import 'package:pusula/features/profil/data/profil_kaydi.dart';
import 'package:pusula/features/profil/domain/profil.dart';

import 'yardimci/yazilar.dart';

class _Kaynak implements IlanKaynagi {
  List<KamuIlani> liste = [];
  bool hata = false;
  int cagri = 0;

  @override
  Future<List<KamuIlani>> getir() async {
    cagri++;
    if (hata) throw Exception('ağ yok');
    return liste;
  }
}

KamuIlani _ilan(String id, {IlanTuru tur = IlanTuru.memur, String kurum = 'X KURUMU', DateTime? son}) => KamuIlani(
  id: id,
  baslik: 'Alım ilanı $id',
  kurum: kurum,
  konum: '',
  tur: tur,
  yayinTarihi: DateTime(2026, 9, 20),
  sonBasvuru: son,
  kaynakAdi: 'Kariyer Kapısı',
  kaynakGuncelleme: DateTime(2026, 9, 29),
);

void main() {
  setUpAll(pusulaYazilariniYukle);

  final simdi = DateTime(2026, 9, 29, 10);

  ({YeniIlanTakibi takip, _Kaynak kaynak, SahteHatirlaticiServisi servis, BellekDepolama depo}) kur({
    bool izin = true,
    BellekDepolama? depo,
  }) {
    final kaynak = _Kaynak()..liste = [_ilan('a'), _ilan('b')];
    final servis = SahteHatirlaticiServisi(izinVerilir: izin);
    final d = depo ?? BellekDepolama();
    return (
      takip: YeniIlanTakibi(kaynak: kaynak, servis: servis, depolama: d, hesapId: 'h1', simdi: () => simdi),
      kaynak: kaynak,
      servis: servis,
      depo: d,
    );
  }

  group('YeniIlanTakibi', () {
    test('varsayılan kapalı; kapalıyken kontrol ağa gitmez ve bildirim yok', () async {
      final k = kur();
      await k.takip.yukle();
      expect(k.takip.tercih.acik, isFalse);
      expect(await k.takip.kontrolEt(), 0);
      expect(k.kaynak.cagri, 0);
    });

    test('açılınca izin istenir, statüye göre türler seçilir, mevcut ilanlar için bildirim gitmez', () async {
      final k = kur();
      await k.takip.yukle();
      expect(await k.takip.ayarla(true, statu: Statu.memur657), isTrue);
      expect(k.servis.izinIstegi, 1);
      expect(k.takip.tercih.turler, {IlanTuru.memur, IlanTuru.sozlesmeli});
      expect(await k.takip.kontrolEt(), 0);
      expect(k.servis.gosterilenler, isEmpty);
    });

    test('sonradan gelen yeni ilan bir kez bildirilir', () async {
      final k = kur();
      await k.takip.yukle();
      await k.takip.ayarla(true, statu: Statu.memur657);
      k.kaynak.liste = [_ilan('c', kurum: 'ABC BAKANLIĞI'), ..._sirasiz(k)];
      expect(await k.takip.kontrolEt(), 1);
      expect(k.servis.gosterilenler.single.baslik, 'Yeni ilan: ABC BAKANLIĞI');
      expect(k.servis.gosterilenler.single.govde, 'Alım ilanı c');
      expect(await k.takip.kontrolEt(), 0, reason: 'aynı ilan ikinci kez bildirilmez');
      expect(k.servis.gosterilenler, hasLength(1));
    });

    test('seçili olmayan türdeki ve süresi dolmuş ilan bildirilmez', () async {
      final k = kur();
      await k.takip.yukle();
      await k.takip.ayarla(true, statu: Statu.memur657); // memur + sözleşmeli
      k.kaynak.liste = [
        ..._sirasiz(k),
        _ilan('isci1', tur: IlanTuru.isci),
        _ilan('diger1', tur: IlanTuru.diger),
        _ilan('eski', son: DateTime(2026, 9, 1)),
        _ilan('soz1', tur: IlanTuru.sozlesmeli, son: DateTime(2026, 10, 10)),
      ];
      expect(await k.takip.kontrolEt(), 1);
      expect(k.servis.gosterilenler.single.govde, 'Alım ilanı soz1');
    });

    test('tür seçimi değişince yeni türdeki ilanlar bildirilir', () async {
      final k = kur();
      await k.takip.yukle();
      await k.takip.ayarla(true, statu: Statu.memur657);
      await k.takip.turAyarla(IlanTuru.isci, true);
      k.kaynak.liste = [..._sirasiz(k), _ilan('isci1', tur: IlanTuru.isci)];
      expect(await k.takip.kontrolEt(), 1);
      await k.takip.turAyarla(IlanTuru.isci, false);
      k.kaynak.liste = [..._sirasiz(k), _ilan('isci2', tur: IlanTuru.isci)];
      expect(await k.takip.kontrolEt(), 0);
    });

    test('çok sayıda yeni ilan tek özet bildirimi olur', () async {
      final k = kur();
      await k.takip.yukle();
      await k.takip.ayarla(true, statu: Statu.memur657);
      k.kaynak.liste = [..._sirasiz(k), for (var i = 0; i < 5; i++) _ilan('n$i', kurum: 'K$i')];
      expect(await k.takip.kontrolEt(), 1);
      expect(k.servis.gosterilenler.single.baslik, '5 yeni kamu ilanı');
      expect(k.servis.gosterilenler.single.govde, 'K0, K1 ve diğerleri');
    });

    test('akış alınamazsa sessizce 0 döner ve görülen ilanlar bozulmaz', () async {
      final k = kur();
      await k.takip.yukle();
      await k.takip.ayarla(true, statu: Statu.memur657);
      k.kaynak.hata = true;
      expect(await k.takip.kontrolEt(), 0);
      k.kaynak
        ..hata = false
        ..liste = [..._sirasiz(k), _ilan('yeni')];
      expect(await k.takip.kontrolEt(), 1);
    });

    test('izin verilmezse açılmaz; kapatınca kontrol durur', () async {
      final red = kur(izin: false);
      await red.takip.yukle();
      expect(await red.takip.ayarla(true, statu: Statu.memur657), isFalse);
      expect(red.takip.tercih.acik, isFalse);

      final k = kur();
      await k.takip.yukle();
      await k.takip.ayarla(true, statu: Statu.isci);
      expect(k.takip.tercih.turler, {IlanTuru.isci, IlanTuru.sozlesmeli});
      await k.takip.ayarla(false);
      expect(await k.takip.kontrolEt(), 0);
    });

    test('tercih ve görülen ilanlar saklanır; tercihiSil hepsini temizler', () async {
      final depo = BellekDepolama();
      final a = kur(depo: depo);
      await a.takip.yukle();
      await a.takip.ayarla(true, statu: Statu.memur657);
      final b = kur(depo: depo);
      await b.takip.yukle();
      expect(b.takip.tercih.acik, isTrue);
      expect(b.takip.tercih.turler, {IlanTuru.memur, IlanTuru.sozlesmeli});
      expect(await b.takip.kontrolEt(), 0, reason: 'görülen ilanlar hatırlanır');

      await b.takip.tercihiSil();
      expect(await depo.oku('ilan_bildirim_v1_h1'), isNull);
      expect(await depo.oku('ilan_gorulen_v1_h1'), isNull);
      expect(b.takip.tercih.acik, isFalse);
    });

    test('bozuk kayıtlı tercih varsayılana döner', () async {
      final depo = BellekDepolama({'ilan_bildirim_v1_h1': '{bozuk', 'ilan_gorulen_v1_h1': '[1'});
      final k = kur(depo: depo);
      await k.takip.yukle();
      expect(k.takip.tercih.acik, isFalse);
    });
  });

  group('Kabuk: açılışta ve ön plana gelince kontrol', () {
    testWidgets('bildirim açıksa uygulama açılınca ve ön plana dönünce yeni ilanlar bildirilir', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final depo = BellekDepolama({
        'ilan_bildirim_v1_h1': '{"acik":true,"turler":["memur"]}',
        'ilan_gorulen_v1_h1': '["a"]',
      });
      final kaynak = _Kaynak()..liste = [_ilan('a'), _ilan('yeni1')];
      final servis = SahteHatirlaticiServisi();
      final takip = YeniIlanTakibi(kaynak: kaynak, servis: servis, depolama: depo, hesapId: 'h1', simdi: () => simdi);
      final profilDepo = ProfilDeposu(BellekProfilKaydi(const Profil(ad: 'Ayşe', statu: Statu.memur657)));
      await profilDepo.yukle();
      await tester.pumpWidget(
        MaterialApp(
          theme: pusulaTema(),
          home: PusulaKabugu(
            profilDeposu: profilDepo,
            haberOtomatik: false,
            bugun: simdi,
            ilanTakibi: takip,
            ilanKaynagi: OrnekIlanKaynagi(sure: Duration.zero, bugun: simdi),
            haberKaynagi: OrnekHaberKaynagi(sure: Duration.zero, bugun: simdi),
            becayisDeposuUret: BecayisOrnekVeri.depoProfilden,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(servis.gosterilenler.map((g) => g.govde), ['Alım ilanı yeni1']);

      kaynak.liste = [...kaynak.liste, _ilan('yeni2')];
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(servis.gosterilenler.map((g) => g.govde), ['Alım ilanı yeni1', 'Alım ilanı yeni2']);

      // Kabuk kapanınca zamanlayıcı ve gözlemci temizlenir (bekleyen zamanlayıcı kalmaz).
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Ayarlar: Yeni ilan bildirimi', () {
    Future<YeniIlanTakibi> ac(WidgetTester tester, {bool izin = true, bool destek = true}) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final takip = YeniIlanTakibi(
        kaynak: _Kaynak(),
        servis: SahteHatirlaticiServisi(izinVerilir: izin, destekleniyor: destek),
        depolama: BellekDepolama(),
        hesapId: 'h1',
        simdi: () => simdi,
      );
      await takip.yukle();
      await tester.pumpWidget(
        MaterialApp(
          theme: pusulaTema(),
          home: AyarlarSayfasi(
            profil: const Profil(ad: 'A', statu: Statu.memur657),
            ilanTakibi: takip,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return takip;
    }

    testWidgets('anahtar açılınca tür seçenekleri ve açıklama görünür; türler değiştirilebilir', (tester) async {
      final takip = await ac(tester);
      expect(find.text('Yeni ilan bildirimi'), findsOneWidget);
      expect(find.text('Sözleşmeli'), findsNothing);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(takip.tercih.acik, isTrue);
      expect(find.text('Memur alımı'), findsOneWidget);
      expect(find.text('Sözleşmeli'), findsOneWidget);
      expect(find.textContaining('Uygulama kapalıyken bildirim gelmez'), findsOneWidget);
      await tester.tap(find.text('İşçi alımı'));
      await tester.pumpAndSettle();
      expect(takip.tercih.turler, contains(IlanTuru.isci));
    });

    testWidgets('izin verilmezse mesaj çıkar, anahtar kapalı kalır', (tester) async {
      await ac(tester, izin: false);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.textContaining('Bildirim izni verilmedi'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });

    testWidgets('platform desteklemiyorsa (web) bölüm görünmez', (tester) async {
      await ac(tester, destek: false);
      expect(find.text('Yeni ilan bildirimi'), findsNothing);
    });
  });
}

/// Testte mevcut ilanları (a, b) yeniden verir; yeni ilanlar bunların üstüne eklenir.
List<KamuIlani> _sirasiz(
  ({YeniIlanTakibi takip, _Kaynak kaynak, SahteHatirlaticiServisi servis, BellekDepolama depo}) k,
) => [_ilan('a'), _ilan('b')];
