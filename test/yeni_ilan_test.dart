import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/depolama.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/ayarlar/ayarlar_sayfasi.dart';
import 'package:pusula/features/hatirlatici/hatirlatici_servisi.dart';
import 'package:pusula/features/ilanlar/arka_plan.dart';
import 'package:pusula/features/ilanlar/ilan_kaynagi.dart';
import 'package:pusula/features/ilanlar/ilan_modeli.dart';
import 'package:pusula/features/becayis/data/ornek_veri.dart';
import 'package:pusula/features/haberler/haber_modeli.dart';
import 'package:pusula/features/haberler/yeni_haber_takibi.dart';
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

  group('Tanı: test bildirimi ve şimdi kontrol et', () {
    test('test bildirimi gösterilir; telefon ayarlarında kapalıysa gösterilmez ve false döner', () async {
      final k = kur();
      await k.takip.yukle();
      expect(await k.takip.testBildirimiGonder(), isTrue);
      expect(k.servis.gosterilenler.single.baslik, contains('test bildirimi'));
      k.servis.bildirimlerAcik = false;
      expect(await k.takip.testBildirimiGonder(), isFalse);
      expect(k.servis.gosterilenler, hasLength(1));
    });

    test('kontrolSonucu: kapalı, akış alınamadı, yeni yok, bildirildi durumlarını ayırır', () async {
      final k = kur();
      await k.takip.yukle();
      expect((await k.takip.kontrolSonucu()).durum, KontrolDurumu.kapali);
      await k.takip.ayarla(true, statu: Statu.memur657);
      k.kaynak.hata = true;
      expect((await k.takip.kontrolSonucu()).durum, KontrolDurumu.alinamadi);
      k.kaynak.hata = false;
      final yokSonucu = await k.takip.kontrolSonucu();
      expect(yokSonucu.durum, KontrolDurumu.yeniYok);
      expect(yokSonucu.bakilan, 2);
      k.kaynak.liste = [..._sirasiz(k), _ilan('yeni')];
      final s = await k.takip.kontrolSonucu();
      expect((s.durum, s.bildirim), (KontrolDurumu.bildirildi, 1));
    });

    testWidgets('Ayarlar: düğmeler test bildirimi gönderir ve kontrol sonucunu söyler', (tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final kaynak = _Kaynak()..liste = [_ilan('a')];
      final servis = SahteHatirlaticiServisi();
      final takip = YeniIlanTakibi(
        kaynak: kaynak,
        servis: servis,
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
      expect(find.text('Test bildirimi'), findsNothing, reason: 'bildirim kapalıyken düğmeler yok');
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test bildirimi'));
      await tester.pumpAndSettle();
      expect(servis.gosterilenler, hasLength(1));
      expect(find.textContaining('Test bildirimi gönderildi'), findsOneWidget);

      servis.bildirimlerAcik = false;
      await tester.tap(find.text('Test bildirimi'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Bildirimler telefon ayarlarında kapalı'), findsOneWidget);

      await tester.tap(find.text('Şimdi kontrol et'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Akışta 1 ilan var; seçtiğin türlerde yeni ilan yok'), findsOneWidget);
      kaynak.hata = true;
      await tester.tap(find.text('Şimdi kontrol et'));
      await tester.pumpAndSettle();
      expect(find.textContaining('İlan akışı alınamadı'), findsOneWidget);
    });
  });

  group('Arka plan', () {
    YeniIlanTakibi takipKur(
      BellekDepolama depo,
      SahteArkaPlanZamanlayici ap, {
      _Kaynak? kaynak,
      SahteHatirlaticiServisi? servis,
    }) => YeniIlanTakibi(
      kaynak: kaynak ?? _Kaynak(),
      servis: servis ?? SahteHatirlaticiServisi(),
      depolama: depo,
      hesapId: 'h1',
      arkaPlan: ap,
      simdi: () => simdi,
    );

    test('bildirim açılınca arka plan işi başlar ve hesap kaydedilir; kapatılınca durur', () async {
      final depo = BellekDepolama();
      final ap = SahteArkaPlanZamanlayici();
      final t = takipKur(depo, ap);
      await t.yukle();
      expect(t.arkaPlanVar, isTrue);
      await t.ayarla(true, statu: Statu.memur657);
      expect(ap.baslatildi, 1);
      expect(await depo.oku(YeniIlanTakibi.arkaPlanHesapAnahtari), 'h1');
      await t.ayarla(false);
      expect(ap.durduruldu, 1);
    });

    test('izin verilmezse arka plan işi başlamaz', () async {
      final ap = SahteArkaPlanZamanlayici();
      final t = YeniIlanTakibi(
        kaynak: _Kaynak(),
        servis: SahteHatirlaticiServisi(izinVerilir: false),
        depolama: BellekDepolama(),
        hesapId: 'h1',
        arkaPlan: ap,
      );
      await t.yukle();
      expect(await t.ayarla(true), isFalse);
      expect(ap.baslatildi, 0);
    });

    test(
      'arkaPlaniSenkronla: tercih açıksa başlatır, kapalıysa durdurur; oturumKapandi hesabı siler, tercihi korur',
      () async {
        final depo = BellekDepolama({'ilan_bildirim_v1_h1': '{"acik":true,"turler":["memur"]}'});
        final ap = SahteArkaPlanZamanlayici();
        final t = takipKur(depo, ap);
        await t.yukle();
        await t.arkaPlaniSenkronla();
        expect(ap.baslatildi, 1);
        expect(await depo.oku(YeniIlanTakibi.arkaPlanHesapAnahtari), 'h1');
        await t.oturumKapandi();
        expect(ap.durduruldu, 1);
        expect(await depo.oku(YeniIlanTakibi.arkaPlanHesapAnahtari), isNull);
        expect(await depo.oku('ilan_bildirim_v1_h1'), isNotNull, reason: 'tercih korunur');

        final kapali = takipKur(BellekDepolama(), ap);
        await kapali.yukle();
        await kapali.arkaPlaniSenkronla();
        expect(ap.durduruldu, 2);
      },
    );

    test('tercihiSil arka plan işini durdurur ve hesap kaydını siler', () async {
      final depo = BellekDepolama();
      final ap = SahteArkaPlanZamanlayici();
      final t = takipKur(depo, ap);
      await t.yukle();
      await t.ayarla(true, statu: Statu.isci);
      await t.tercihiSil();
      expect(ap.durduruldu, 1);
      expect(await depo.oku(YeniIlanTakibi.arkaPlanHesapAnahtari), isNull);
    });

    test(
      'arkaPlanKontrolu: kayıtlı hesabın tercihine göre yeni ilanı bildirir (uygulama kapalıyken çalışan iş)',
      () async {
        final depo = BellekDepolama({
          YeniIlanTakibi.arkaPlanHesapAnahtari: 'h1',
          'ilan_bildirim_v1_h1': '{"acik":true,"turler":["memur"]}',
          'ilan_gorulen_v1_h1': '["a"]',
        });
        final kaynak = _Kaynak()..liste = [_ilan('a'), _ilan('yeni')];
        final servis = SahteHatirlaticiServisi();
        expect(await arkaPlanKontrolu(depolama: depo, kaynak: kaynak, servis: servis, simdi: () => simdi), isTrue);
        expect(servis.gosterilenler.map((g) => g.govde), ['Alım ilanı yeni']);
        expect(await arkaPlanKontrolu(depolama: depo, kaynak: kaynak, servis: servis, simdi: () => simdi), isTrue);
        expect(servis.gosterilenler, hasLength(1), reason: 'aynı ilan ikinci kez bildirilmez');
      },
    );

    test('arkaPlanKontrolu: hesap kaydı yok ya da tercih kapalıysa hiçbir şey yapmaz', () async {
      final kaynak = _Kaynak()..liste = [_ilan('yeni')];
      final servis = SahteHatirlaticiServisi();
      expect(await arkaPlanKontrolu(depolama: BellekDepolama(), kaynak: kaynak, servis: servis), isFalse);
      final kapali = BellekDepolama({YeniIlanTakibi.arkaPlanHesapAnahtari: 'h1'});
      expect(await arkaPlanKontrolu(depolama: kapali, kaynak: kaynak, servis: servis), isFalse);
      expect(kaynak.cagri, 0);
      expect(servis.gosterilenler, isEmpty);
    });

    testWidgets('Ayarlar: arka plan destekleniyorsa "uygulama kapalıyken de" açıklaması görünür', (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final t = takipKur(BellekDepolama(), SahteArkaPlanZamanlayici());
      await t.yukle();
      await tester.pumpWidget(
        MaterialApp(
          theme: pusulaTema(),
          home: AyarlarSayfasi(
            profil: const Profil(ad: 'A', statu: Statu.memur657),
            ilanTakibi: t,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.textContaining('Uygulama kapalıyken de yaklaşık 15-30 dakikada bir'), findsOneWidget);
      expect(find.textContaining('Uygulama kapalıyken bildirim gelmez'), findsNothing);
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

  haberTestleri();

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

// ---------------------------------------------------------------------------------------------
// Resmî Gazete bildirimi

class _HaberKaynagi implements HaberKaynagi {
  List<Haber> liste = [];
  bool hata = false;

  @override
  Future<List<Haber>> getir() async {
    if (hata) throw Exception('ağ yok');
    return liste;
  }
}

Haber _haber(String id, {DateTime? yayin, bool resmi = true, String baslik = 'Kamu Görevlilerinin Ek Ödeme Kararı'}) =>
    Haber(
      id: id,
      baslik: baslik,
      tur: HaberTuru.maas,
      kaynakAdi: 'Resmî Gazete',
      yayinTarihi: yayin ?? DateTime(2026, 9, 29),
      resmiKaynak: resmi,
    );

void haberTestleri() {
  final simdi = DateTime(2026, 9, 29, 10);

  ({
    YeniHaberTakibi takip,
    _HaberKaynagi kaynak,
    SahteHatirlaticiServisi servis,
    BellekDepolama depo,
    SahteArkaPlanZamanlayici ap,
  })
  kur({bool izin = true, BellekDepolama? depo}) {
    final kaynak = _HaberKaynagi()..liste = [_haber('rg-20260929-1-1'), _haber('rg-20260929')];
    final servis = SahteHatirlaticiServisi(izinVerilir: izin);
    final d = depo ?? BellekDepolama();
    final ap = SahteArkaPlanZamanlayici();
    return (
      takip: YeniHaberTakibi(
        kaynak: kaynak,
        servis: servis,
        depolama: d,
        hesapId: 'h1',
        arkaPlan: ap,
        simdi: () => simdi,
      ),
      kaynak: kaynak,
      servis: servis,
      depo: d,
      ap: ap,
    );
  }

  group('YeniHaberTakibi', () {
    test('varsayılan kapalı; açılınca izin istenir, mevcut maddeler bildirilmez, arka plan başlar', () async {
      final k = kur();
      await k.takip.yukle();
      expect(k.takip.acik, isFalse);
      expect(await k.takip.kontrolEt(), 0);
      expect(await k.takip.ayarla(true), isTrue);
      expect(k.servis.izinIstegi, 1);
      expect(k.ap.baslatildi, 1);
      expect(await k.takip.kontrolEt(), 0);
      expect(k.servis.gosterilenler, isEmpty);
    });

    test('yeni personel maddesi bildirilir; günlük sayı künyesi, resmî olmayan ve eski haber bildirilmez', () async {
      final k = kur();
      await k.takip.yukle();
      await k.takip.ayarla(true);
      k.kaynak.liste = [
        ...k.kaynak.liste,
        _haber('rg-20260929-2-5', baslik: 'Sözleşmeli Personel Esaslarında Değişiklik Kararı'),
        _haber('rg-20260930'),
        _haber('bilinmeyen', resmi: false),
        _haber('rg-20260920-1-1', yayin: DateTime(2026, 9, 20)),
      ];
      expect(await k.takip.kontrolEt(), 1);
      expect(k.servis.gosterilenler.single.baslik, 'Resmî Gazete');
      expect(k.servis.gosterilenler.single.govde, 'Sözleşmeli Personel Esaslarında Değişiklik Kararı');
      expect(await k.takip.kontrolEt(), 0);
    });

    test('çok sayıda yeni madde tek özet bildirimi olur; uzun başlık kısaltılır', () async {
      final k = kur();
      await k.takip.yukle();
      await k.takip.ayarla(true);
      k.kaynak.liste = [for (var i = 0; i < 5; i++) _haber('rg-20260929-9-$i')];
      expect(await k.takip.kontrolEt(), 1);
      expect(k.servis.gosterilenler.single.baslik, '5 yeni Resmî Gazete maddesi');

      final u = kur();
      await u.takip.yukle();
      await u.takip.ayarla(true);
      u.kaynak.liste = [_haber('rg-20260929-7-1', baslik: 'A' * 200)];
      await u.takip.kontrolEt();
      expect(u.servis.gosterilenler.single.govde, '${'A' * 120}...');
    });

    test('akış alınamazsa 0; izin verilmezse açılmaz; kapatınca arka plan durur', () async {
      final k = kur();
      await k.takip.yukle();
      await k.takip.ayarla(true);
      k.kaynak.hata = true;
      expect(await k.takip.kontrolEt(), 0);
      await k.takip.ayarla(false);
      expect(k.ap.durduruldu, 1);

      final red = kur(izin: false);
      await red.takip.yukle();
      expect(await red.takip.ayarla(true), isFalse);
      expect(red.takip.acik, isFalse);
    });

    test('ilan bildirimi de açıksa haber kapatılınca arka plan işi durmaz; ikisi kapanınca durur', () async {
      final depo = BellekDepolama({'ilan_bildirim_v1_h1': '{"acik":true,"turler":["memur"]}'});
      final k = kur(depo: depo);
      await k.takip.yukle();
      await k.takip.ayarla(true);
      await k.takip.ayarla(false);
      expect(k.ap.durduruldu, 0, reason: 'ilan bildirimi hâlâ açık');
      expect(await depo.oku(YeniIlanTakibi.arkaPlanHesapAnahtari), 'h1');

      await depo.yaz('ilan_bildirim_v1_h1', '{"acik":false,"turler":[]}');
      await k.takip.ayarla(false);
      expect(k.ap.durduruldu, 1);
      expect(await depo.oku(YeniIlanTakibi.arkaPlanHesapAnahtari), isNull);
    });

    test('tercih saklanır; tercihiSil hepsini temizler; bozuk kayıt kapalı sayılır', () async {
      final depo = BellekDepolama();
      final a = kur(depo: depo);
      await a.takip.yukle();
      await a.takip.ayarla(true);
      final b = kur(depo: depo);
      await b.takip.yukle();
      expect(b.takip.acik, isTrue);
      expect(await b.takip.kontrolEt(), 0, reason: 'görülen maddeler hatırlanır');
      await b.takip.tercihiSil();
      expect(await depo.oku('haber_bildirim_v1_h1'), isNull);
      expect(await depo.oku('haber_gorulen_v1_h1'), isNull);

      final bozuk = kur(depo: BellekDepolama({'haber_bildirim_v1_h1': '{bozuk'}));
      await bozuk.takip.yukle();
      expect(bozuk.takip.acik, isFalse);
    });

    test('arkaPlanKontrolu: haber bildirimi açıksa Resmî Gazete akışına da bakar', () async {
      final depo = BellekDepolama({
        YeniIlanTakibi.arkaPlanHesapAnahtari: 'h1',
        'haber_bildirim_v1_h1': '{"acik":true}',
        'haber_gorulen_v1_h1': '["rg-20260929-1-1"]',
      });
      final haberler = _HaberKaynagi()
        ..liste = [_haber('rg-20260929-1-1'), _haber('rg-20260929-2-2', baslik: 'Yeni Kadro Kararı')];
      final servis = SahteHatirlaticiServisi();
      final ilanKaynagi = _Kaynak();
      final sonuc = await arkaPlanKontrolu(
        depolama: depo,
        kaynak: ilanKaynagi,
        haberKaynagi: haberler,
        servis: servis,
        simdi: () => simdi,
      );
      expect(sonuc, isTrue);
      expect(servis.gosterilenler.map((g) => g.govde), ['Yeni Kadro Kararı']);
      expect(ilanKaynagi.cagri, 0, reason: 'ilan bildirimi kapalı');
    });
  });

  testWidgets('Ayarlar: Resmî Gazete anahtarı açılır, açıklama görünür; destek yoksa gizlidir', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final k = kur();
    await k.takip.yukle();
    await tester.pumpWidget(
      MaterialApp(
        theme: pusulaTema(),
        home: AyarlarSayfasi(
          profil: const Profil(ad: 'A', statu: Statu.memur657),
          haberTakibi: k.takip,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Resmî Gazete bildirimi'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(k.takip.acik, isTrue);
    expect(find.textContaining('yeni Resmî Gazete maddeleri'), findsOneWidget);

    final desteksiz = YeniHaberTakibi(
      kaynak: _HaberKaynagi(),
      servis: SahteHatirlaticiServisi(destekleniyor: false),
      depolama: BellekDepolama(),
      hesapId: 'h1',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: pusulaTema(),
        home: AyarlarSayfasi(
          profil: const Profil(ad: 'A', statu: Statu.memur657),
          haberTakibi: desteksiz,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Resmî Gazete bildirimi'), findsNothing);
  });
}
