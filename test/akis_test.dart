import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pusula/core/akis.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/haberler/haber_kaynagi.dart';
import 'package:pusula/features/haberler/haber_modeli.dart';
import 'package:pusula/features/ilanlar/ilan_kaynagi.dart';
import 'package:pusula/features/ilanlar/ilan_modeli.dart';
import 'package:pusula/features/ilanlar/ilanlar_sayfasi.dart';

import 'yardimci/yazilar.dart';

const _ilanJson = {
  'guncelleme': '2026-09-29T23:23:50+03:00',
  'kaynak': 'Kariyer Kapısı (kariyerkapisi.gov.tr) — Kamu İşe Alım İlanları',
  'ilanlar': [
    {
      'id': 'a1',
      'baslik': 'YÜKSEK SEÇİM KURULU BAŞKANLIĞI - SÖZLEŞMELİ BİLİŞİM PERSONELİ ALIM İLANI (2026)',
      'kurum': 'YÜKSEK SEÇİM KURULU BAŞKANLIĞI',
      'kategori': 'Sözleşmeli Personel İlanları',
      'tur': 'sozlesmeli',
      'yayin': '2026-09-18T10:00:00+03:00',
      'sonBasvuru': null,
      'baglanti': 'https://kariyerkapisi.gov.tr/IlanDetay?i=a1',
    },
    {
      'id': 'a2',
      'baslik': 'ÖZELLEŞTİRME İDARESİ BAŞKANLIĞI - UZMAN YARDIMCILIĞI GİRİŞ SINAVI DUYURUSU',
      'kurum': 'ÖZELLEŞTİRME İDARESİ BAŞKANLIĞI',
      'kategori': 'A Grubu Memur (Kariyer Meslek)',
      'tur': 'memur',
      'yayin': '2026-10-19T00:00:00+03:00',
      'sonBasvuru': null,
      'baglanti': 'https://kariyerkapisi.gov.tr/IlanDetay?i=a2',
    },
    {
      'id': 'a3',
      'baslik': 'TEST KURUMU - Memur Alımı',
      'kurum': 'TEST KURUMU',
      'kategori': 'B Grubu Memur',
      'tur': 'memur',
      'yayin': '2026-09-20T09:00:00+03:00',
      'sonBasvuru': '2026-10-05',
      'baglanti': 'javascript:alert(1)',
    },
    {'id': '', 'baslik': 'kimliksiz', 'yayin': '2026-09-20T09:00:00+03:00'},
    {'id': 'bozuk-tarih', 'baslik': 'tarihsiz'},
    'bozuk',
  ],
};

const _haberJson = {
  'guncelleme': '2026-09-29T23:23:50+03:00',
  'haberler': [
    {
      'id': 'rg-20260929',
      'baslik': '29 Eylül 2026 Tarihli ve 33385 Sayılı Resmî Gazete',
      'tur': 'mevzuat',
      'kaynak': 'Resmî Gazete',
      'resmi': true,
      'yayin': '2026-09-29T00:00:00+03:00',
      'ozet': 'Bugünkü sayıda kamu personeliyle doğrudan ilgili madde bulunamadı.',
      'baglanti': 'https://www.resmigazete.gov.tr/29.09.2026',
    },
    {
      'id': 'rg-20260929-1-1',
      'baslik': 'Kamu Görevlilerinin Ek Ödeme Oranlarına İlişkin Karar',
      'tur': 'maas',
      'kaynak': 'Resmî Gazete',
      'resmi': true,
      'yayin': '2026-09-29T00:00:00+03:00',
      'baglanti': 'https://www.resmigazete.gov.tr/eskiler/2026/09/20260929-1.htm',
    },
    {'id': 'rg-20260928-2-2', 'baslik': 'Eski gün haberi', 'tur': 'tanimsiz-tur', 'yayin': '2026-09-28T00:00:00+03:00'},
    {'id': 'x'},
  ],
};

AkisIstemcisi _istemci(
  Map<String, Object?> Function(String yol) yanit, {
  List<String>? istekler,
  int durum = 200,
  DateTime Function()? simdi,
}) => AkisIstemcisi(
  istemci: MockClient((r) async {
    istekler?.add(r.url.toString());
    return http.Response.bytes(utf8.encode(jsonEncode(yanit(r.url.path))), durum);
  }),
  taban: Uri.parse('https://ornek.test/feed-data/'),
  simdi: simdi,
);

void main() {
  setUpAll(pusulaYazilariniYukle);

  group('AkisIstemcisi', () {
    test('dosyayı taban adresten okur; kısa süre içinde ikinci istek önbellekten gelir', () async {
      final istekler = <String>[];
      var an = DateTime(2026, 9, 29, 12);
      final i = _istemci((_) => _ilanJson, istekler: istekler, simdi: () => an);
      await i.oku('ilanlar.json');
      await i.oku('ilanlar.json');
      expect(istekler, ['https://ornek.test/feed-data/ilanlar.json']);
      an = an.add(const Duration(seconds: 61));
      await i.oku('ilanlar.json');
      expect(istekler, hasLength(2));
      await i.oku('ilanlar.json', yenile: true);
      expect(istekler, hasLength(3));
    });

    test('HTTP hatası, bozuk JSON ve beklenmeyen biçim AkisHatasi verir; hata önbelleğe alınmaz', () async {
      await expectLater(_istemci((_) => {}, durum: 404).oku('a.json'), throwsA(isA<AkisHatasi>()));
      final bozuk = AkisIstemcisi(
        istemci: MockClient((r) async => http.Response('{bozuk', 200)),
        taban: Uri.parse('https://ornek.test/'),
      );
      await expectLater(bozuk.oku('a.json'), throwsA(isA<AkisHatasi>()));
      final liste = AkisIstemcisi(
        istemci: MockClient((r) async => http.Response('[1,2]', 200)),
        taban: Uri.parse('https://ornek.test/'),
      );
      await expectLater(liste.oku('a.json'), throwsA(isA<AkisHatasi>()));
      final ag = AkisIstemcisi(
        istemci: MockClient((r) async => throw Exception('ağ yok')),
        taban: Uri.parse('https://ornek.test/'),
      );
      await expectLater(ag.oku('a.json'), throwsA(isA<AkisHatasi>()));
    });
  });

  group('ilanlariCoz', () {
    final ilanlar = AkisIlanKaynagi.ilanlariCoz(_ilanJson);

    test('geçerli kayıtlar çözülür, kimliksiz/tarihsiz/bozuk atlanır; en yeni başta', () {
      expect(ilanlar.map((i) => i.id), ['a2', 'a3', 'a1']);
    });

    test('kurum başlıktan ayrılır; tür, kategori, kaynak ve son gün doğru eşlenir', () {
      final a1 = ilanlar.firstWhere((i) => i.id == 'a1');
      expect(a1.kurum, 'YÜKSEK SEÇİM KURULU BAŞKANLIĞI');
      expect(a1.baslik, 'SÖZLEŞMELİ BİLİŞİM PERSONELİ ALIM İLANI (2026)');
      expect(a1.tur, IlanTuru.sozlesmeli);
      expect(a1.kategori, 'Sözleşmeli Personel İlanları');
      expect(a1.sonBasvuru, isNull);
      expect(a1.kaynakAdi, contains('Kariyer Kapısı'));
      expect(a1.baglanti.toString(), 'https://kariyerkapisi.gov.tr/IlanDetay?i=a1');
      expect(ilanlar.firstWhere((i) => i.id == 'a3').sonBasvuru, DateTime(2026, 10, 5));
    });

    test('yalnızca http(s) bağlantılar kabul edilir', () {
      expect(ilanlar.firstWhere((i) => i.id == 'a3').baglanti, isNull);
    });

    test('son günü olmayan ilan açık sayılır; kalan gün null; yayın tarihi ilerideyse başlamamıştır', () {
      final bugun = DateTime(2026, 9, 29);
      final a1 = ilanlar.firstWhere((i) => i.id == 'a1');
      expect(a1.acikMi(bugun), isTrue);
      expect(a1.kalanGun(bugun), isNull);
      expect(a1.gecenOran(bugun), 0);
      expect(a1.baslamadiMi(bugun), isFalse);
      expect(ilanlar.firstWhere((i) => i.id == 'a2').baslamadiMi(bugun), isTrue);
      expect(ilanlar.firstWhere((i) => i.id == 'a3').acikMi(DateTime(2026, 10, 6)), isFalse);
    });
  });

  group('haberleriCoz', () {
    final haberler = AkisHaberKaynagi.haberleriCoz(_haberJson);

    test('bozuk kayıt atlanır; aynı gün madde haberi günlük özetten önce, eski gün sonda', () {
      expect(haberler.map((h) => h.id), ['rg-20260929-1-1', 'rg-20260929', 'rg-20260928-2-2']);
    });

    test('tür, resmî kaynak, bağlantı ve tanımsız tür varsayılanı', () {
      expect(haberler[0].tur, HaberTuru.maas);
      expect(haberler[0].resmiKaynak, isTrue);
      expect(haberler[0].kaynakAdi, 'Resmî Gazete');
      expect(haberler[0].baglanti.toString(), contains('resmigazete.gov.tr'));
      expect(haberler[2].tur, HaberTuru.mevzuat);
      expect(haberler[2].resmiKaynak, isFalse);
    });
  });

  group('İlanlar ekranı (gerçek akış)', () {
    Future<void> ac(WidgetTester tester, IlanKaynagi kaynak) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: pusulaTema(),
          home: Scaffold(
            body: IlanlarSayfasi(kaynak: kaynak, bugun: DateTime(2026, 9, 29)),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    testWidgets('kaynak künyesi görünür, ÖRNEK rozeti ve "Sana uygun" yok; son günü bilinmeyen ilanın açıklaması var', (
      tester,
    ) async {
      await ac(tester, AkisIlanKaynagi(_istemci((_) => _ilanJson)));
      expect(find.text('Kamu İşe Alım İlanları'), findsOneWidget);
      expect(find.text('ÖRNEK'), findsNothing);
      expect(find.text('Sana uygun'), findsNothing);
      expect(find.text('3 açık ilan'), findsOneWidget);
      expect(find.text('SÖZLEŞMELİ BİLİŞİM PERSONELİ ALIM İLANI (2026)'), findsOneWidget);
      expect(find.text('Son başvuru tarihi ilan sayfasında'), findsOneWidget);
      expect(find.textContaining('Başvurular 19.10.2026 tarihinde başlar'), findsOneWidget);
      expect(find.text('6 gün'), findsOneWidget, reason: 'son günü bilinen ilan geri sayım gösterir');
    });

    testWidgets('ilan ayrıntısı: kategori, son başvuru bilinmiyor, kaynak ve doğrulama uyarısı', (tester) async {
      await ac(tester, AkisIlanKaynagi(_istemci((_) => _ilanJson)));
      await tester.tap(find.text('SÖZLEŞMELİ BİLİŞİM PERSONELİ ALIM İLANI (2026)'));
      await tester.pumpAndSettle();
      expect(find.text('Sözleşmeli Personel İlanları'), findsOneWidget);
      expect(find.text('İlan sayfasında yazar'), findsOneWidget);
      expect(find.textContaining('Kaynak: Kariyer Kapısı'), findsOneWidget);
      expect(find.textContaining('kaynaktan doğrula'), findsOneWidget);
    });

    testWidgets('100 karakteri aşan başlık kartta "..." ile kısaltılır, ayrıntıda tamamı görünür', (tester) async {
      final uzun = 'ÇOK UZUN BİR İLAN BAŞLIĞI ${'X' * 100}';
      final json = {
        'guncelleme': '2026-09-29T10:00:00+03:00',
        'ilanlar': [
          {'id': 'u1', 'baslik': uzun, 'kurum': '', 'tur': 'memur', 'yayin': '2026-09-20T09:00:00+03:00'},
        ],
      };
      await ac(tester, AkisIlanKaynagi(_istemci((_) => json)));
      expect(find.text('${uzun.substring(0, 100)}...'), findsOneWidget);
      expect(find.text(uzun), findsNothing);
      await tester.tap(find.text('${uzun.substring(0, 100)}...'));
      await tester.pumpAndSettle();
      expect(find.text(uzun), findsOneWidget);
    });

    testWidgets('ağ hatasında "yüklenemedi" görünür; tekrar denenince liste gelir', (tester) async {
      var basarili = false;
      final istemci = AkisIstemcisi(
        istemci: MockClient(
          (r) async =>
              basarili ? http.Response.bytes(utf8.encode(jsonEncode(_ilanJson)), 200) : http.Response('yok', 503),
        ),
        taban: Uri.parse('https://ornek.test/'),
      );
      await ac(tester, AkisIlanKaynagi(istemci));
      expect(find.text('İlanlar yüklenemedi'), findsOneWidget);
      basarili = true;
      await tester.tap(find.text('Tekrar dene'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('İlanlar yüklenemedi'), findsNothing);
      expect(find.text('3 açık ilan'), findsOneWidget);
    });

    testWidgets('örnek kaynakta ÖRNEK rozeti ve "Sana uygun" hâlâ görünür', (tester) async {
      await ac(tester, const OrnekIlanKaynagi(sure: Duration.zero));
      expect(find.text('ÖRNEK'), findsOneWidget);
      expect(find.text('Sana uygun'), findsOneWidget);
      expect(find.text('Kamu İşe Alım İlanları'), findsNothing);
    });
  });
}
