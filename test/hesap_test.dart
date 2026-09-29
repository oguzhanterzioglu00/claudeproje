import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/depolama.dart';
import 'package:pusula/features/hesap/data/kimlik_servisi.dart';
import 'package:pusula/features/hesap/data/oturum_deposu.dart';
import 'package:pusula/features/hesap/data/yerel_kimlik_servisi.dart';
import 'package:pusula/features/hesap/domain/hesap.dart';

void main() {
  YerelKimlikServisi servis([BellekDepolama? d]) => YerelKimlikServisi(depolama: d ?? BellekDepolama(), tur: 8);

  group('kurallar', () {
    test('e-posta', () {
      expect(HesapKurali.epostaGecerli('a@kurum.gov.tr'), isTrue);
      expect(HesapKurali.epostaGecerli(' a@b.co '), isTrue);
      for (final k in ['', 'a', 'a@b', 'a b@c.com', '@c.com', 'a@c.']) {
        expect(HesapKurali.epostaGecerli(k), isFalse, reason: k);
      }
    });

    test('şifre: en az 8 karakter, harf ve rakam', () {
      expect(HesapKurali.sifreHatasi('kisa1'), isNotNull);
      expect(HesapKurali.sifreHatasi('12345678'), contains('harf'));
      expect(HesapKurali.sifreHatasi('abcdefgh'), contains('rakam'));
      expect(HesapKurali.sifreHatasi('şifre2026'), isNull);
      expect(HesapKurali.sifreHatasi('Abcdefg1'), isNull);
    });

    test('Hesap.fromJson bozuk veride hata fırlatmaz', () {
      expect(Hesap.fromJson(null), isNull);
      expect(Hesap.fromJson('x'), isNull);
      expect(Hesap.fromJson({'id': 5}), isNull);
      expect(Hesap.fromJson({'id': 'a', 'saglayici': 'yok'}), isNull);
      final h = Hesap.fromJson({'id': 'a', 'saglayici': 'google', 'eposta': 3, 'ad': null})!;
      expect((h.eposta, h.ad, h.sifreliHesap), ('', '', false));
      const orijinal = Hesap(id: 'u', saglayici: GirisSaglayici.eposta, eposta: 'a@b.co', ad: 'A');
      final geri = Hesap.fromJson(orijinal.toJson())!;
      expect((geri.id, geri.eposta, geri.ad, geri.saglayici), ('u', 'a@b.co', 'A', GirisSaglayici.eposta));
    });
  });

  group('yerel kimlik servisi', () {
    test('kayıt, çıkış, yeniden giriş', () async {
      final s = servis();
      expect(await s.mevcut(), isNull);
      final h = await s.kayitOl(eposta: 'Ayse@Kurum.gov.tr', sifre: 'sifre1234');
      expect(h.eposta, 'Ayse@Kurum.gov.tr');
      expect((await s.mevcut())?.id, h.id);

      await s.cikisYap();
      expect(await s.mevcut(), isNull);

      final geri = await s.girisYap(eposta: 'ayse@kurum.gov.tr', sifre: 'sifre1234');
      expect(geri.id, h.id, reason: 'e-posta büyük/küçük harfe duyarsız');
    });

    test('aynı e-posta ile ikinci kayıt reddedilir; geçersiz girdiler açıklama verir', () async {
      final s = servis();
      await s.kayitOl(eposta: 'a@b.co', sifre: 'sifre1234');
      await expectLater(
        s.kayitOl(eposta: 'A@B.co', sifre: 'sifre1234'),
        throwsA(isA<KimlikHatasi>().having((e) => e.mesaj, 'mesaj', contains('zaten'))),
      );
      await expectLater(s.kayitOl(eposta: 'yanlis', sifre: 'sifre1234'), throwsA(isA<KimlikHatasi>()));
      await expectLater(s.kayitOl(eposta: 'x@y.co', sifre: 'kisa'), throwsA(isA<KimlikHatasi>()));
    });

    test('yanlış şifre ile bilinmeyen hesap aynı mesajı verir', () async {
      final s = servis();
      await s.kayitOl(eposta: 'a@b.co', sifre: 'sifre1234');
      Future<String> mesaj(String e, String p) async {
        try {
          await s.girisYap(eposta: e, sifre: p);
        } on KimlikHatasi catch (h) {
          return h.mesaj;
        }
        return 'girdi';
      }

      expect(await mesaj('a@b.co', 'yanlis1234'), 'E-posta veya şifre hatalı');
      expect(await mesaj('yok@b.co', 'sifre1234'), 'E-posta veya şifre hatalı');
    });

    test('şifre düz metin saklanmaz', () async {
      final d = BellekDepolama();
      await servis(d).kayitOl(eposta: 'a@b.co', sifre: 'gizliSifre99');
      expect(await d.oku('hesaplar_v1'), isNot(contains('gizliSifre99')));
    });

    test('şifre değiştirme: eski şifre doğrulanır, yeni şifre kurala uyar, eskisi artık girmez', () async {
      final s = servis();
      await s.kayitOl(eposta: 'a@b.co', sifre: 'sifre1234');

      await expectLater(s.sifreDegistir(eskiSifre: 'yanlis1234', yeniSifre: 'yeniSifre55'),
          throwsA(isA<KimlikHatasi>().having((e) => e.mesaj, 'mesaj', contains('Mevcut'))));
      await expectLater(s.sifreDegistir(eskiSifre: 'sifre1234', yeniSifre: 'kisa'), throwsA(isA<KimlikHatasi>()));
      await expectLater(s.sifreDegistir(eskiSifre: 'sifre1234', yeniSifre: 'sifre1234'), throwsA(isA<KimlikHatasi>()));

      await s.sifreDegistir(eskiSifre: 'sifre1234', yeniSifre: 'yeniSifre55');
      await s.cikisYap();
      await expectLater(s.girisYap(eposta: 'a@b.co', sifre: 'sifre1234'), throwsA(isA<KimlikHatasi>()));
      expect((await s.girisYap(eposta: 'a@b.co', sifre: 'yeniSifre55')).eposta, 'a@b.co');
    });

    test('Google/Apple örnek girişi şifre değiştirmeye izin vermez', () async {
      final s = servis();
      final h = await s.saglayiciIleGiris(GirisSaglayici.google);
      expect((h.saglayici, h.sifreliHesap), (GirisSaglayici.google, false));
      await expectLater(s.sifreDegistir(eskiSifre: 'a', yeniSifre: 'sifre1234'), throwsA(isA<KimlikHatasi>()));
      await expectLater(s.saglayiciIleGiris(GirisSaglayici.eposta), throwsArgumentError);
    });

    test('hesap silme: oturum kapanır, e-posta yeniden kaydedilebilir, eski şifre geçmez', () async {
      final s = servis();
      await s.kayitOl(eposta: 'a@b.co', sifre: 'sifre1234');
      await s.hesabiSil();
      expect(await s.mevcut(), isNull);
      await expectLater(s.girisYap(eposta: 'a@b.co', sifre: 'sifre1234'), throwsA(isA<KimlikHatasi>()));
      await s.kayitOl(eposta: 'a@b.co', sifre: 'baskaSifre1');
    });

    test('bozuk depolama kayıtları çökertmez', () async {
      final s = servis(BellekDepolama({'hesaplar_v1': '{bozuk', 'oturum_v1': '[]'}));
      expect(await s.mevcut(), isNull);
      await s.kayitOl(eposta: 'a@b.co', sifre: 'sifre1234');
    });

    test('şifre sıfırlama yalnızca e-posta biçimini denetler', () async {
      final s = servis();
      await s.sifreSifirlamaIste('kimse@yok.com');
      await expectLater(s.sifreSifirlamaIste('x'), throwsA(isA<KimlikHatasi>()));
    });
  });

  group('oturum deposu', () {
    test('kayıt oturumu açar, çıkış kapatır; işlem sırasında meşgul olur', () async {
      final o = OturumDeposu(servis());
      await o.yukle();
      expect((o.yuklendi, o.hesap), (true, null));
      var mesgulGorundu = false;
      o.addListener(() => mesgulGorundu |= o.mesgul);
      await o.kayitOl('a@b.co', 'sifre1234');
      expect(o.hesap?.eposta, 'a@b.co');
      expect(mesgulGorundu, isTrue);
      expect(o.mesgul, isFalse);
      await o.cikisYap();
      expect(o.hesap, isNull);
    });

    test('hata durumunda hesap değişmez ve meşgul kalkar', () async {
      final o = OturumDeposu(servis());
      await o.yukle();
      await expectLater(o.girisYap('yok@b.co', 'sifre1234'), throwsA(isA<KimlikHatasi>()));
      expect((o.hesap, o.mesgul), (null, false));
    });

    test('açılışta kayıtlı oturum geri yüklenir', () async {
      final d = BellekDepolama();
      await OturumDeposu(servis(d)).kayitOl('a@b.co', 'sifre1234');
      final yeni = OturumDeposu(servis(d));
      await yeni.yukle();
      expect(yeni.hesap?.eposta, 'a@b.co');
    });
  });
}
