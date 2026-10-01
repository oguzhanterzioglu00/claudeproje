import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/depolama.dart';
import 'package:pusula/features/ayarlar/ayarlar_sayfasi.dart';
import 'package:pusula/features/ilanlar/ilan_alarmi.dart';
import 'package:pusula/features/ilanlar/ilan_modeli.dart';
import 'package:pusula/features/ilanlar/kayitli_ilanlar.dart';
import 'package:pusula/features/profil/data/profil_deposu.dart';
import 'package:pusula/features/profil/data/profil_kaydi.dart';
import 'package:pusula/features/profil/domain/profil.dart';
import 'package:pusula/features/yedek/yedek_paketi.dart';
import 'package:pusula/features/yedek/yedek_sayfasi.dart';

import 'yardimci/yazilar.dart';

KamuIlani _ilan(String id) => KamuIlani(
  id: id,
  baslik: 'İlan $id',
  kurum: 'KURUM',
  konum: 'Ankara',
  tur: IlanTuru.memur,
  yayinTarihi: DateTime(2026, 9, 20),
  sonBasvuru: DateTime(2026, 10, 30),
  kaynakAdi: 'Kariyer Kapısı',
  kaynakGuncelleme: DateTime(2026, 9, 29),
);

const _profil = Profil(ad: 'Ayşe Yılmaz', statu: Statu.memur657, il: 'Ankara', sicilNo: '123456');

Future<
  ({
    YedekBaglami baglam,
    ProfilDeposu profil,
    KayitliIlanlar kayitli,
    IlanAlarmlari alarm,
  })
>
_kur({Profil? profil, List<KamuIlani> ilanlar = const [], List<String> kelimeler = const []}) async {
  final depo = BellekDepolama();
  final pd = ProfilDeposu(BellekProfilKaydi(profil));
  await pd.yukle();
  final k = KayitliIlanlar(depo, hesapId: 'h');
  for (final i in ilanlar) {
    await k.degistir(i);
  }
  final a = IlanAlarmlari(depo, hesapId: 'h');
  for (final w in kelimeler) {
    await a.ekle(kelime: w);
  }
  return (baglam: YedekBaglami(profil: pd, kayitliIlanlar: k, alarmlar: a), profil: pd, kayitli: k, alarm: a);
}

void main() {
  setUpAll(pusulaYazilariniYukle);

  group('YedekPaketi', () {
    test('kodla ve çöz gidiş-dönüş (Türkçe karakterler korunur)', () async {
      final k = await _kur(profil: _profil, ilanlar: [_ilan('1'), _ilan('2')], kelimeler: ['zabıt katibi']);
      final kod = k.baglam.olustur().kodla();
      expect(kod, startsWith('KPYEDEK1.'));

      final p = YedekPaketi.coz(kod)!;
      expect(p.profil!.ad, 'Ayşe Yılmaz');
      expect(p.profil!.statu, Statu.memur657);
      expect(p.kayitliIlanlar.map((i) => i.id), containsAll(['1', '2']));
      expect(p.alarmlar.single.kelime, 'zabıt katibi');
      expect(p.ozet, 'profil, 2 kayıtlı ilan, 1 alarm');
    });

    test('boşluk ve satır sonları yok sayılır (mesajlaşma uygulaması kodu böler)', () async {
      final kod = (await _kur(profil: _profil)).baglam.olustur().kodla();
      final bolunmus = '  ${kod.replaceAllMapped(RegExp(r'.{40}'), (m) => '${m[0]}\n')}  ';
      expect(YedekPaketi.coz(bolunmus)?.profil?.ad, 'Ayşe Yılmaz');
    });

    test('eksik, bozuk ya da yabancı kod reddedilir', () async {
      final kod = (await _kur(profil: _profil)).baglam.olustur().kodla();
      expect(YedekPaketi.coz(''), isNull);
      expect(YedekPaketi.coz('merhaba'), isNull);
      expect(YedekPaketi.coz(kod.substring(0, kod.length - 20)), isNull, reason: 'kesik kopya');
      expect(YedekPaketi.coz(kod.replaceFirst('KPYEDEK1', 'KPYEDEK2')), isNull);
      final parcalar = kod.split('.');
      expect(YedekPaketi.coz('${parcalar[0]}.${parcalar[1]}A.${parcalar[2]}'), isNull, reason: 'içerik değişti');
    });

    test('bos: profil ve veri yoksa', () async {
      final k = await _kur();
      expect(k.baglam.olustur().bos, isTrue);
    });
  });

  group('YedekBaglami.geriYukle', () {
    test('profil değişir, ilanlar ve alarmlar mevcutlara eklenir, tekrar edenler atlanır', () async {
      final eski = await _kur(profil: _profil, ilanlar: [_ilan('1'), _ilan('2')], kelimeler: ['hemşire', 'zabıt']);
      final paket = YedekPaketi.coz(eski.baglam.olustur().kodla())!;

      final yeni = await _kur(
        profil: const Profil(ad: 'Eski ad', statu: Statu.isci),
        ilanlar: [_ilan('2'), _ilan('9')],
        kelimeler: ['zabıt'],
      );
      final r = await yeni.baglam.geriYukle(paket);

      expect(r.profil, isTrue);
      expect(r.ilan, 1, reason: 'yalnızca 1 numaralı yeni');
      expect(r.alarm, 1, reason: 'yalnızca hemşire yeni');
      expect(yeni.profil.profil!.ad, 'Ayşe Yılmaz');
      expect(yeni.kayitli.liste.map((i) => i.id), unorderedEquals(['2', '9', '1']));
      expect(yeni.alarm.liste.map((a) => a.kelime), unorderedEquals(['zabıt', 'hemşire']));
    });

    test('yedekte profil yoksa mevcut profile dokunulmaz', () async {
      final eski = await _kur(ilanlar: [_ilan('1')]);
      final paket = YedekPaketi.coz(eski.baglam.olustur().kodla())!;
      final yeni = await _kur(profil: _profil);
      final r = await yeni.baglam.geriYukle(paket);
      expect(r.profil, isFalse);
      expect(yeni.profil.profil!.ad, 'Ayşe Yılmaz');
    });

    test('kayıtlı ilan sınırı aşılmaz', () async {
      final yeni = await _kur(ilanlar: [for (var i = 0; i < KayitliIlanlar.enFazla - 1; i++) _ilan('m$i')]);
      final paket = YedekPaketi(kayitliIlanlar: [_ilan('a'), _ilan('b'), _ilan('c')], olusturma: DateTime.now());
      final r = await yeni.baglam.geriYukle(paket);
      expect(r.ilan, 1);
      expect(yeni.kayitli.liste, hasLength(KayitliIlanlar.enFazla));
    });
  });

  group('Yedekten yükle ekranı', () {
    Widget sar(Widget c) => MaterialApp(home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: c)));

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

    testWidgets('geçersiz kod uyarı verir; geçerli kod özetlenir ve yüklenir', (t) async {
      final eski = await _kur(profil: _profil, ilanlar: [_ilan('1')], kelimeler: ['hemşire']);
      final kod = eski.baglam.olustur().kodla();
      final yeni = await _kur();

      await t.pumpWidget(sar(YedekYukleSayfasi(baglam: yeni.baglam, panodanOku: () async => kod)));
      await t.enterText(find.byType(TextField), 'bozuk kod');
      await t.pump();
      expect(find.textContaining('geçersiz ya da eksik'), findsOneWidget);
      expect(find.text('Yedeği yükle'), findsNothing);

      await t.tap(find.text('Panodan yapıştır'));
      await t.pumpAndSettle();
      expect(find.textContaining('Yedekte: profil, 1 kayıtlı ilan, 1 alarm'), findsOneWidget);

      await t.tap(find.text('Yedeği yükle'));
      await t.pumpAndSettle();
      expect(find.textContaining('Profil yüklendi, 1 kayıtlı ilan eklendi, 1 alarm eklendi'), findsOneWidget);
      expect(yeni.profil.profil!.ad, 'Ayşe Yılmaz');
      expect(yeni.kayitli.liste, hasLength(1));
      expect(yeni.alarm.liste, hasLength(1));
    });

    testWidgets('boş pano hata göstermez, yükle düğmesi çıkmaz', (t) async {
      final yeni = await _kur();
      await t.pumpWidget(sar(YedekYukleSayfasi(baglam: yeni.baglam, panodanOku: () async => null)));
      await t.tap(find.text('Panodan yapıştır'));
      await t.pumpAndSettle();
      expect(find.textContaining('geçersiz'), findsNothing);
      expect(find.text('Yedeği yükle'), findsNothing);
    });
  });

  group('Ayarlar: yedek satırları', () {
    setUp(() {
      final b = TestWidgetsFlutterBinding.ensureInitialized();
      b.platformDispatcher.views.first.physicalSize = const Size(900, 2400);
      b.platformDispatcher.views.first.devicePixelRatio = 1;
    });
    tearDown(() {
      final b = TestWidgetsFlutterBinding.ensureInitialized();
      b.platformDispatcher.views.first.resetPhysicalSize();
      b.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    testWidgets('yedek verilmezse satırlar görünmez', (t) async {
      await t.pumpWidget(const MaterialApp(home: AyarlarSayfasi()));
      await t.pumpAndSettle();
      expect(find.text('Yedeği kopyala'), findsNothing);
    });

    testWidgets('"Yedeği kopyala" kodu panoya koyar', (t) async {
      String? pano;
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (c) async {
        if (c.method == 'Clipboard.setData') pano = (c.arguments as Map)['text'] as String?;
        return null;
      });
      addTearDown(() => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

      final k = await _kur(profil: _profil, ilanlar: [_ilan('1')]);
      await t.pumpWidget(MaterialApp(home: AyarlarSayfasi(yedek: k.baglam)));
      await t.pumpAndSettle();
      await t.tap(find.text('Yedeği kopyala'));
      await t.pumpAndSettle();
      expect(pano, startsWith('KPYEDEK1.'));
      expect(find.textContaining('Yedek kodu panoya kopyalandı (profil, 1 kayıtlı ilan)'), findsOneWidget);
    });

    testWidgets('yedeklenecek veri yoksa uyarır ve panoya bir şey koymaz', (t) async {
      String? pano;
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (c) async {
        if (c.method == 'Clipboard.setData') pano = (c.arguments as Map)['text'] as String?;
        return null;
      });
      addTearDown(() => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      final k = await _kur();
      await t.pumpWidget(MaterialApp(home: AyarlarSayfasi(yedek: k.baglam)));
      await t.pumpAndSettle();
      await t.tap(find.text('Yedeği kopyala'));
      await t.pumpAndSettle();
      expect(pano, isNull);
      expect(find.textContaining('Yedeklenecek bir şey yok'), findsOneWidget);
    });
  });
}
