import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/depolama.dart';
import 'package:pusula/features/hatirlatici/hatirlatici_servisi.dart';
import 'package:pusula/features/ilanlar/ilan_alarm_sayfasi.dart';
import 'package:pusula/features/ilanlar/ilan_alarmi.dart';
import 'package:pusula/features/ilanlar/ilan_kaynagi.dart';
import 'package:pusula/features/ilanlar/ilan_modeli.dart';
import 'package:pusula/features/ilanlar/ilanlar_sayfasi.dart';
import 'package:pusula/features/ilanlar/yeni_ilan_takibi.dart';

import 'yardimci/yazilar.dart';

class _Kaynak implements IlanKaynagi {
  List<KamuIlani> liste = [];

  @override
  Future<List<KamuIlani>> getir() async => liste;
}

KamuIlani _ilan(
  String id, {
  String baslik = 'Zabıt Katibi Alımı',
  String kurum = 'ADALET BAKANLIĞI',
  String konum = 'İstanbul',
  IlanTuru tur = IlanTuru.memur,
}) => KamuIlani(
  id: id,
  baslik: baslik,
  kurum: kurum,
  konum: konum,
  tur: tur,
  yayinTarihi: DateTime(2026, 9, 20),
  sonBasvuru: DateTime(2026, 10, 30),
  kaynakAdi: 'Kariyer Kapısı',
  kaynakGuncelleme: DateTime(2026, 9, 29),
);

void main() {
  setUpAll(pusulaYazilariniYukle);

  final simdi = DateTime(2026, 9, 29, 10);

  group('IlanAlarmi.eslesir', () {
    final ilan = _ilan('1');

    test('kelimenin hepsi ilanda geçmeli (Türkçe harf farkı yok sayılır)', () {
      expect(const IlanAlarmi(id: 'a', kelime: 'zabıt katibi').eslesir(ilan), isTrue);
      expect(const IlanAlarmi(id: 'a', kelime: 'ZABIT KATİBİ').eslesir(ilan), isTrue);
      expect(const IlanAlarmi(id: 'a', kelime: 'zabit katibi').eslesir(ilan), isTrue, reason: 'ı/i farkı');
      expect(const IlanAlarmi(id: 'a', kelime: 'zabıt hemşire').eslesir(ilan), isFalse);
    });

    test('il ve tür koşulu da aranır', () {
      expect(const IlanAlarmi(id: 'a', kelime: 'zabıt', il: 'istanbul').eslesir(ilan), isTrue);
      expect(const IlanAlarmi(id: 'a', kelime: 'zabıt', il: 'Ankara').eslesir(ilan), isFalse);
      expect(const IlanAlarmi(id: 'a', kelime: 'zabıt', tur: IlanTuru.memur).eslesir(ilan), isTrue);
      expect(const IlanAlarmi(id: 'a', kelime: 'zabıt', tur: IlanTuru.isci).eslesir(ilan), isFalse);
    });

    test('yalnızca il ya da yalnızca tür yeterlidir; kurumda geçen sözcük de sayılır', () {
      expect(const IlanAlarmi(id: 'a', il: 'İstanbul').eslesir(ilan), isTrue);
      expect(const IlanAlarmi(id: 'a', tur: IlanTuru.memur).eslesir(ilan), isTrue);
      expect(const IlanAlarmi(id: 'a', kelime: 'adalet').eslesir(ilan), isTrue);
    });

    test('ad ve json gidiş-dönüş; bozuk kayıt reddedilir', () {
      const a = IlanAlarmi(id: 'x', kelime: 'hemşire', il: 'İzmir', tur: IlanTuru.sozlesmeli);
      expect(a.ad, 'hemşire · İzmir · Sözleşmeli');
      final geri = IlanAlarmi.fromJson(a.toJson())!;
      expect(geri.kelime, 'hemşire');
      expect(geri.il, 'İzmir');
      expect(geri.tur, IlanTuru.sozlesmeli);
      expect(IlanAlarmi.fromJson('bozuk'), isNull);
      expect(IlanAlarmi.fromJson({'id': 'x'}), isNull, reason: 'hiç koşulu olmayan alarm geçersiz');
    });
  });

  group('IlanAlarmlari', () {
    test('ekler, kalıcı tutar, tekrarı ve boşu reddeder, siler', () async {
      final depo = BellekDepolama();
      final a = IlanAlarmlari(depo, hesapId: 'h1');
      await a.yukle();
      expect(await a.ekle(kelime: 'zabıt katibi', il: 'İstanbul'), isTrue);
      expect(await a.ekle(kelime: 'ZABIT KATIBI', il: 'istanbul'), isFalse, reason: 'aynı alarm');
      expect(await a.ekle(), isFalse, reason: 'boş alarm');
      expect(a.liste, hasLength(1));

      final b = IlanAlarmlari(depo, hesapId: 'h1');
      await b.yukle();
      expect(b.liste.single.ad, 'zabıt katibi · İstanbul');
      expect(await IlanAlarmlari.oku(depo, 'h1'), hasLength(1));
      expect(await IlanAlarmlari.oku(depo, 'baska'), isEmpty, reason: 'başka hesabın alarmı görünmez');

      await b.sil(b.liste.single.id);
      expect(b.liste, isEmpty);
      expect(await IlanAlarmlari.oku(depo, 'h1'), isEmpty);
    });

    test('en fazla ${IlanAlarmlari.enFazla} alarm', () async {
      final a = IlanAlarmlari(BellekDepolama(), hesapId: 'h1');
      for (var i = 0; i < IlanAlarmlari.enFazla; i++) {
        expect(await a.ekle(kelime: 'k$i'), isTrue);
      }
      expect(a.dolu, isTrue);
      expect(await a.ekle(kelime: 'fazla'), isFalse);
    });

    test('uyan: ilana uyan ilk alarmı bulur', () async {
      final a = IlanAlarmlari(BellekDepolama(), hesapId: 'h1');
      await a.ekle(kelime: 'hemşire');
      await a.ekle(kelime: 'zabıt');
      expect(a.uyan(_ilan('1'))?.kelime, 'zabıt');
      expect(a.uyan(_ilan('2', baslik: 'Şoför', kurum: 'X')), isNull);
    });
  });

  group('YeniIlanTakibi + alarm', () {
    ({YeniIlanTakibi takip, _Kaynak kaynak, SahteHatirlaticiServisi servis, BellekDepolama depo}) kur() {
      final kaynak = _Kaynak()..liste = [_ilan('eski', baslik: 'Eski ilan', kurum: 'X', konum: 'Y')];
      final servis = SahteHatirlaticiServisi();
      final depo = BellekDepolama();
      return (
        takip: YeniIlanTakibi(kaynak: kaynak, servis: servis, depolama: depo, hesapId: 'h1', simdi: () => simdi),
        kaynak: kaynak,
        servis: servis,
        depo: depo,
      );
    }

    test('yalnızca-alarm modunda tür bildirimi gelmez, alarma uyan ilan bildirilir', () async {
      final k = kur();
      await k.takip.yukle();
      await IlanAlarmlari(k.depo, hesapId: 'h1').ekle(kelime: 'zabıt', il: 'İstanbul');
      expect(await k.takip.ayarla(true, yalnizcaAlarm: true), isTrue);
      expect(k.takip.tercih.turler, isEmpty);

      k.kaynak.liste = [
        ...k.kaynak.liste,
        _ilan('uymayan', baslik: 'Şoför Alımı', kurum: 'Belediye', konum: 'Ankara'), // memur türünde ama alarma uymaz
        _ilan('uyan'),
      ];
      expect(await k.takip.kontrolEt(), 1);
      expect(k.servis.gosterilenler, hasLength(1));
      expect(k.servis.gosterilenler.single.baslik, 'Alarm: zabıt · İstanbul');
      expect(k.servis.gosterilenler.single.govde, contains('Zabıt Katibi Alımı'));

      expect(await k.takip.kontrolEt(), 0, reason: 'aynı ilan ikinci kez bildirilmez');
    });

    test('tür tercihi ve alarm birlikte: ikisinden birine uyan bildirilir', () async {
      final k = kur();
      await k.takip.yukle();
      await IlanAlarmlari(k.depo, hesapId: 'h1').ekle(kelime: 'hemşire');
      await k.takip.ayarla(true); // varsayılan türler (statü yok: hepsi)
      await k.takip.turAyarla(IlanTuru.isci, true);
      await k.takip.turAyarla(IlanTuru.memur, false);
      await k.takip.turAyarla(IlanTuru.sozlesmeli, false);
      await k.takip.turAyarla(IlanTuru.diger, false);

      k.kaynak.liste = [
        ...k.kaynak.liste,
        _ilan('isci1', baslik: 'Temizlik görevlisi', tur: IlanTuru.isci),
        _ilan('hemsire', baslik: 'Hemşire alımı', tur: IlanTuru.sozlesmeli),
        _ilan('uymaz', baslik: 'Mühendis', tur: IlanTuru.memur),
      ];
      expect(await k.takip.kontrolEt(), 2);
    });

    test('çok sayıda eşleşme tek özet bildirimde toplanır ve alarma uyan sayısı yazılır', () async {
      final k = kur();
      await k.takip.yukle();
      await IlanAlarmlari(k.depo, hesapId: 'h1').ekle(kelime: 'zabıt');
      await k.takip.ayarla(true, yalnizcaAlarm: true);
      k.kaynak.liste = [for (var i = 0; i < 5; i++) _ilan('z$i'), ...k.kaynak.liste];
      expect(await k.takip.kontrolEt(), 1);
      expect(k.servis.gosterilenler.single.baslik, '5 yeni kamu ilanı');
      expect(k.servis.gosterilenler.single.govde, contains('5 tanesi alarmına uyuyor'));
    });

    test('bildirim zaten açıkken alarm için tekrar açmak mevcut tür seçimini bozmaz', () async {
      final k = kur();
      await k.takip.yukle();
      await k.takip.ayarla(true);
      final onceki = {...k.takip.tercih.turler};
      expect(await k.takip.ayarla(true, yalnizcaAlarm: true), isTrue);
      expect(k.takip.tercih.turler, onceki);
    });

    test('tercihiSil alarmları da siler', () async {
      final k = kur();
      await k.takip.yukle();
      await IlanAlarmlari(k.depo, hesapId: 'h1').ekle(kelime: 'zabıt');
      await k.takip.tercihiSil();
      expect(await IlanAlarmlari.oku(k.depo, 'h1'), isEmpty);
    });
  });

  group('İlanlar ekranında alarm', () {
    Widget sar(Widget c) => MaterialApp(home: Scaffold(body: c));

    // Form uzun: alt sayfadaki düğme varsayılan test ekranının dışında kalmasın.
    setUp(() {
      final b = TestWidgetsFlutterBinding.ensureInitialized();
      b.platformDispatcher.views.first.physicalSize = const Size(900, 2000);
      b.platformDispatcher.views.first.devicePixelRatio = 1;
    });
    tearDown(() {
      final b = TestWidgetsFlutterBinding.ensureInitialized();
      b.platformDispatcher.views.first.resetPhysicalSize();
      b.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    testWidgets('arama kutusundan alarm kurulur; uyan ilanda "Alarmına uyuyor" rozeti görünür', (t) async {
      final kaynak = _Kaynak()..liste = [_ilan('1'), _ilan('2', baslik: 'Şoför', kurum: 'Belediye', konum: 'Ankara')];
      final alarmlar = IlanAlarmlari(BellekDepolama(), hesapId: 'h1');
      await t.pumpWidget(sar(IlanlarSayfasi(kaynak: kaynak, bugun: simdi, alarmlar: alarmlar)));
      await t.pumpAndSettle();
      expect(find.text('Alarmına uyuyor'), findsNothing);

      await t.enterText(find.byType(TextField).first, 'zabıt');
      await t.pump();
      await t.tap(find.text('"zabıt" için alarm kur'));
      await t.pumpAndSettle();
      expect(find.text('İlan alarmları'), findsWidgets);
      expect(find.widgetWithText(TextField, 'zabıt'), findsNWidgets(2), reason: 'arama kutusu ve alarm formu: arama metni forma yazılı gelir');

      await t.tap(find.text('Alarm kur'));
      await t.pumpAndSettle();
      expect(alarmlar.liste, hasLength(1));
      expect(find.text('Şu an 1 açık ilan uyuyor'), findsOneWidget);

      await t.tapAt(const Offset(10, 10)); // alt sayfayı kapat
      await t.pumpAndSettle();
      expect(find.text('Alarmına uyuyor'), findsOneWidget, reason: 'yalnızca zabıt katibi ilanında');
    });

    testWidgets('boş form uyarı verir, alarm eklenmez', (t) async {
      final alarmlar = IlanAlarmlari(BellekDepolama(), hesapId: 'h1');
      await t.pumpWidget(sar(IlanAlarmSayfasi(alarmlar: alarmlar, ilanlar: const [], bugun: simdi)));
      await t.pumpAndSettle();
      await t.tap(find.text('Alarm kur'));
      await t.pumpAndSettle();
      expect(find.text('Bir kelime, il ya da tür seç.'), findsOneWidget);
      expect(alarmlar.liste, isEmpty);
    });

    testWidgets('bildirim izni verilmezse alarm kurulmaz ve açıklama gösterilir', (t) async {
      final servis = SahteHatirlaticiServisi(izinVerilir: false);
      final takip = YeniIlanTakibi(
        kaynak: _Kaynak(),
        servis: servis,
        depolama: BellekDepolama(),
        hesapId: 'h1',
        simdi: () => simdi,
      );
      await takip.yukle();
      final alarmlar = IlanAlarmlari(BellekDepolama(), hesapId: 'h1');
      await t.pumpWidget(sar(IlanAlarmSayfasi(alarmlar: alarmlar, ilanlar: const [], bugun: simdi, takip: takip)));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).first, 'hemşire');
      await t.tap(find.text('Alarm kur'));
      await t.pumpAndSettle();
      expect(find.textContaining('Bildirim izni verilmedi'), findsOneWidget);
      expect(alarmlar.liste, isEmpty);
    });

    testWidgets('alarm silinir', (t) async {
      final alarmlar = IlanAlarmlari(BellekDepolama(), hesapId: 'h1');
      await alarmlar.ekle(kelime: 'hemşire');
      await t.pumpWidget(sar(IlanAlarmSayfasi(alarmlar: alarmlar, ilanlar: const [], bugun: simdi)));
      await t.pumpAndSettle();
      expect(find.text('hemşire'), findsOneWidget);
      await t.tap(find.byType(IconButton).first);
      await t.pumpAndSettle();
      expect(alarmlar.liste, isEmpty);
      expect(find.text('Henüz alarmın yok'), findsOneWidget);
    });
  });
}
