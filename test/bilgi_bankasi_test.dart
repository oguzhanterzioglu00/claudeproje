import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/metin.dart';
import 'package:pusula/features/asistan/asistan_servisi.dart';
import 'package:pusula/features/asistan/bilgi_bankasi.dart';

void main() {
  group('bilgi bankası içeriği', () {
    test('kimlikler ve etiketler benzersiz', () {
      final kimlikler = BilgiBankasi.konular.map((k) => k.id).toList();
      expect(kimlikler.toSet().length, kimlikler.length);
      final etiketler = BilgiBankasi.konular.map((k) => k.etiket).toList();
      expect(etiketler.toSet().length, etiketler.length);
    });

    test('kapsam dışı olmayan her konu kaynak maddeden alıntı taşır; uydurma kaynak yok', () {
      for (final k in BilgiBankasi.konular) {
        if (k.kapsamDisi) {
          expect(k.kaynaklar, isEmpty, reason: '${k.id}: kapsam dışı konuda kaynak gösterilmez');
          continue;
        }
        expect(k.kaynaklar, isNotEmpty, reason: k.id);
        for (final kaynak in k.kaynaklar) {
          expect(
            kaynak.baslik,
            anyOf(
              startsWith('657 sayılı Devlet Memurları Kanunu, md. '),
              startsWith('5510 sayılı Kanun, '),
              startsWith('4857 sayılı İş Kanunu, '),
              startsWith('Sözleşmeli Personel Çalıştırılmasına İlişkin Esaslar, md. '),
              startsWith('1475 sayılı İş Kanunu, md. 14'),
            ),
            reason: k.id,
          );
          expect(kaynak.alinti, isNotNull, reason: '${k.id}: ${kaynak.baslik}');
          expect(kaynak.alinti!.length, greaterThan(60), reason: '${k.id}: ${kaynak.baslik}');
        }
      }
    });

    test('anahtar kelimeler sadeleştirilmiş biçimde (küçük harf, Türkçe harfsiz) yazılmış', () {
      for (final k in BilgiBankasi.konular) {
        for (final a in k.anahtarlar) {
          expect(aramaAnahtari(a), a, reason: '${k.id}: "$a" sadeleştirilmiş olmalı');
        }
      }
    });

    test('cevaplardaki rakamlar kanun alıntılarıyla tutarlı (bilinen kritik değerler)', () {
      String alinti(String id) =>
          BilgiBankasi.konular.firstWhere((k) => k.id == id).kaynaklar.map((e) => e.alinti).join(' ');
      String cevap(String id) => BilgiBankasi.konular.firstWhere((k) => k.id == id).cevap;

      expect(alinti('yillik_izin'), allOf(contains('yirmi gün'), contains('30 gündür')));
      expect(cevap('yillik_izin'), allOf(contains('20 gün'), contains('30 gün')));

      expect(
        alinti('mazeret_izni'),
        allOf(contains('onaltı hafta'), contains('yirmidört hafta'), contains('on gün babalık'), contains('yedi gün')),
      );
      expect(
        cevap('mazeret_izni'),
        allOf(contains('16 hafta'), contains('24 hafta'), contains('10 gün'), contains('7 gün')),
      );

      expect(alinti('hastalik_izni'), allOf(contains('onsekiz aya'), contains('oniki aya'), contains('üç aya')));
      expect(cevap('hastalik_izni'), allOf(contains('18 aya'), contains('12 aya'), contains('3 aya')));

      expect(alinti('ayliksiz_izin'), allOf(contains('onsekiz aya'), contains('yirmidört aya'), contains('bir yıla')));
      expect(cevap('ayliksiz_izin'), allOf(contains('18 aya'), contains('24 aya'), contains('1 yıla')));

      expect(
        alinti('isci_yillik_izin'),
        allOf(contains('ondört günden'), contains('yirmi günden'), contains('yirmialtı günden')),
      );
      expect(cevap('isci_yillik_izin'), allOf(contains('14 gün'), contains('20 gün'), contains('26 gün')));
      expect(
        alinti('isci_calisma'),
        allOf(contains('kırkbeş saat'), contains('yüzde elli'), contains('ikiyüzyetmiş saat')),
      );
      expect(cevap('isci_calisma'), allOf(contains('45 saat'), contains('%50'), contains('270 saat')));
      expect(
        alinti('isci_fesih'),
        allOf(contains('iki hafta'), contains('dört hafta'), contains('altı hafta'), contains('sekiz hafta')),
      );
      expect(
        cevap('isci_fesih'),
        allOf(contains('2 hafta'), contains('4 hafta'), contains('6 hafta'), contains('8 hafta')),
      );
      expect(alinti('isci_kidem'), contains('30 günlük ücreti'));
      expect(cevap('isci_kidem'), contains('30 günlük ücreti'));
      expect(
        alinti('isci_mazeret'),
        allOf(
          contains('sekiz ve doğumdan sonra onaltı hafta'),
          contains('birbuçuk saat'),
          contains('üç gün'),
          contains('on gün'),
        ),
      );
      expect(alinti('sozlesmeli_yillik_izin'), allOf(contains('yirmi gün'), contains('otuz gün')));
      expect(cevap('sozlesmeli_yillik_izin'), allOf(contains('20 gün'), contains('30 gün')));
      expect(
        alinti('sozlesmeli_mazeret'),
        allOf(
          contains('yirmi dört hafta'),
          contains('üç saat'),
          contains('bir buçuk saat'),
          contains('on gün'),
          contains('yedi gün'),
          contains('üç aya kadar'),
        ),
      );
      expect(
        cevap('sozlesmeli_mazeret'),
        allOf(
          contains('24 hafta'),
          contains('3 saat'),
          contains('1,5 saat'),
          contains('10 gün'),
          contains('7 gün'),
          contains('üç aya kadar'),
        ),
      );

      expect(
        cevap('isci_mazeret'),
        allOf(
          contains('8'),
          contains('16 hafta'),
          contains('24 hafta'),
          contains('1,5 saat'),
          contains('3 gün'),
          contains('10 gün'),
        ),
      );

      expect(
        alinti('kademe_derece'),
        allOf(contains('en az bir yıl'), contains('en az 3 yıl'), contains('3 üncü kademesinde 1 yıl')),
      );
    });
  });

  group('soru eşleştirme', () {
    String? konu(String soru) => BilgiArama.esles(soru).konu?.id;

    test('doğal sorular doğru konuya gider (Türkçe harf ve büyük/küçük harf farkı önemsiz)', () {
      const beklenen = {
        'Becayiş şartları nedir?': 'becayis',
        'BECAYIS yapmak istiyorum': 'becayis',
        'Yıllık izin kaç gün?': 'yillik_izin',
        'yillik iznimi bolebilir miyim': 'yillik_izin',
        'Kullanılmayan izin hakları düşer mi?': 'yillik_izin',
        'Mazeret izni kaç gün?': 'mazeret_izni',
        'Eşim doğum yaptı, babalık izni alabilir miyim?': 'mazeret_izni',
        'Doğum izni kaç hafta?': 'mazeret_izni',
        'Süt izni günde kaç saat?': 'mazeret_izni',
        'Rapor kullanımı ile ilgili haklarım neler?': 'hastalik_izni',
        'Hastalık izni ne kadar sürer?': 'hastalik_izni',
        'Anneme refakat izni alabilir miyim': 'hastalik_izni',
        'Aylıksız izin ne zaman verilir?': 'ayliksiz_izin',
        'ücretsiz izin alabilir miyim': 'ayliksiz_izin',
        'Kademe ve derece yükselmesi şartları nedir?': 'kademe_derece',
        'Terfi ne zaman olur': 'kademe_derece',
        'Tayin şartları nelerdir?': 'tayin',
        'Eş durumu tayini yapılır mı': 'tayin',
        'Kurumlar arası nakil mümkün mü': 'tayin',
        'Disiplin cezaları nelerdir?': 'disiplin',
        'Uyarma ve kınama cezası ne zaman verilir': 'disiplin',
        'Adaylık süresi ne kadar?': 'adaylik',
        'Asaleti onaylanmak için ne gerekir': 'adaylik',
        'Haftalık çalışma süresi kaç saat?': 'calisma_saati',
        'Mesai saatleri kaça kadar': 'calisma_saati',
        'Emeklilik için ne kadar süre gerekir?': 'emeklilik',
        'İşçi yıllık izin kaç gün?': 'isci_yillik_izin',
        'İşçiyim, 8 yıldır çalışıyorum yıllık izin hakkım nedir': 'isci_yillik_izin',
        'İş Kanunu doğum izni kaç hafta': 'isci_mazeret',
        'İşçi eşim doğum yaptı, ücretli izin alabilir miyim': 'isci_mazeret',
        'İşçi fazla mesai ücreti nasıl ödenir?': 'isci_calisma',
        'İş Kanunu haftalık çalışma süresi kaç saat': 'isci_calisma',
        'İhbar süresi ne kadar?': 'isci_fesih',
        'İşten çıkarılırsam ihbar tazminatı': 'isci_fesih',
        'Kıdem tazminatı nasıl hesaplanır?': 'isci_kidem',
        'Sözleşmeli personel yıllık izin kaç gün?': 'sozlesmeli_yillik_izin',
        '4/B sözleşmeli olarak çalışıyorum, izin hakkım nedir? yıllık izin': 'sozlesmeli_yillik_izin',
        'Sözleşmeli personel doğum izni kaç hafta?': 'sozlesmeli_mazeret',
        'Sözleşmeli personel süt izni günde kaç saat': 'sozlesmeli_mazeret',
        'Sözleşmeli personel hastalık izni nasıl verilir?': 'sozlesmeli_hastalik',
        'Sözleşmeli personel çalışma saatleri nasıl?': 'sozlesmeli_calisma',
        'İşçi kıdem tazminatına ne zaman hak kazanır': 'isci_kidem',
      };
      beklenen.forEach((soru, id) => expect(konu(soru), id, reason: soru));
    });

    test('konuyla ilgisiz soru eşleşmez', () {
      final e = BilgiArama.esles('Bugün hava nasıl olacak?');
      expect(e.konu, isNull);
      expect(e.adaylar, isEmpty);
      expect(BilgiArama.esles('   ').konu, isNull);
    });

    test('yalnızca "izin" yazılırsa birden çok aday döner (tahmin edilmez)', () {
      final e = BilgiArama.esles('izin');
      expect(e.konu, isNull);
      expect(
        e.adaylar.map((k) => k.id),
        containsAll(['yillik_izin', 'mazeret_izni', 'hastalik_izni', 'ayliksiz_izin']),
      );
    });

    test('her konunun kendi örnek sorusu kendi konusuna gider', () {
      for (final k in BilgiBankasi.konular) {
        expect(BilgiArama.esles(k.ornekSoru).konu?.id, k.id, reason: k.ornekSoru);
      }
    });
  });

  group('çalışan grubuna göre eşleştirme (memur / işçi)', () {
    String? konuK(String soru, {Kitle? kitle}) => BilgiArama.esles(soru, kitle: kitle).konu?.id;

    test('grup belirtilmezse aynı konuda memur konusu öncelikli; işçi konusu yalnızca işçi ifadesiyle', () {
      expect(konuK('Yıllık izin kaç gün?'), 'yillik_izin');
      expect(konuK('Doğum izni kaç hafta?'), 'mazeret_izni');
      expect(konuK('Yıllık izin kaç gün işçi için?'), 'isci_yillik_izin');
    });

    test('işçi statüsündeki kullanıcıya işçi konusu, memura memur konusu döner', () {
      expect(konuK('Yıllık izin kaç gün?', kitle: Kitle.isci), 'isci_yillik_izin');
      expect(konuK('Yıllık izin kaç gün?', kitle: Kitle.memur), 'yillik_izin');
      expect(konuK('Doğum izni kaç hafta?', kitle: Kitle.isci), 'isci_mazeret');
    });

    test('sorudaki açık ifade kullanıcının statüsünden önce gelir', () {
      expect(konuK('Memur yıllık izin kaç gün?', kitle: Kitle.isci), 'yillik_izin');
      expect(konuK('İşçi yıllık izin kaç gün?', kitle: Kitle.memur), 'isci_yillik_izin');
    });

    test('yalnızca "izin" yazan işçiye işçi izin konuları önerilir (memur konuları değil)', () {
      final e = BilgiArama.esles('izin', kitle: Kitle.isci);
      expect(e.konu, isNull);
      expect(e.adaylar.map((k) => k.id), unorderedEquals(['isci_yillik_izin', 'isci_mazeret']));
    });

    test('sözleşmeli: statüyle ya da soruda "sözleşmeli" yazınca 4/B konuları; memur konusu gelmez', () {
      expect(konuK('Yıllık izin kaç gün?', kitle: Kitle.sozlesmeli), 'sozlesmeli_yillik_izin');
      expect(konuK('Doğum izni kaç hafta?', kitle: Kitle.sozlesmeli), 'sozlesmeli_mazeret');
      expect(konuK('Sözleşmeli yıllık izin kaç gün?'), 'sozlesmeli_yillik_izin');
      expect(
        konuK('Sözleşmeli yıllık izin kaç gün?', kitle: Kitle.memur),
        'sozlesmeli_yillik_izin',
        reason: 'açık ifade önce gelir',
      );
      expect(konuK('Yıllık izin kaç gün?'), 'yillik_izin', reason: 'grup belirsizse memur konusu');
    });

    test('yalnızca "izin" yazan sözleşmeliye 4/B izin konuları önerilir', () {
      final e = BilgiArama.esles('izin', kitle: Kitle.sozlesmeli);
      expect(e.konu, isNull);
      expect(
        e.adaylar.map((k) => k.id),
        unorderedEquals(['sozlesmeli_yillik_izin', 'sozlesmeli_mazeret', 'sozlesmeli_hastalik']),
      );
    });

    test('kendi grubunda karşılığı olmayan soru tüm konularda aranır', () {
      expect(konuK('Kıdem tazminatı nedir?', kitle: Kitle.memur), 'isci_kidem');
      expect(konuK('Becayiş şartları nedir?', kitle: Kitle.isci), 'becayis');
    });

    test('emeklilik (5510) her iki gruba da cevap verir', () {
      expect(konuK('Emeklilik yaşı kaç?', kitle: Kitle.isci), 'emeklilik');
      expect(konuK('Emeklilik yaşı kaç?', kitle: Kitle.memur), 'emeklilik');
    });

    test('konularIcin sözleşmeli: yalnızca 4/B konuları ve emeklilik', () {
      final ids = YerelMevzuatAsistani.konularIcin(Kitle.sozlesmeli).map((k) => k.id).toSet();
      expect(ids, {
        'sozlesmeli_yillik_izin',
        'sozlesmeli_mazeret',
        'sozlesmeli_hastalik',
        'sozlesmeli_calisma',
        'emeklilik',
      });
    });

    test('konularIcin: gruba uygun konular; grup yoksa hepsi', () {
      final isci = YerelMevzuatAsistani.konularIcin(Kitle.isci).map((k) => k.id);
      expect(isci, containsAll(['isci_yillik_izin', 'isci_kidem', 'emeklilik']));
      expect(isci, isNot(contains('becayis')));
      expect(YerelMevzuatAsistani.konularIcin(Kitle.memur).map((k) => k.id), isNot(contains('isci_kidem')));
      expect(YerelMevzuatAsistani.konularIcin(null).length, BilgiBankasi.konular.length);
    });
  });

  group('YerelMevzuatAsistani', () {
    const asistan = YerelMevzuatAsistani(sure: Duration.zero);

    test('eşleşen konuda alıntı, sürüm ve uyarı ile cevap verir', () async {
      final c = await asistan.sor('Yıllık izin kaç gün?');
      expect(c.kaynaklar.map((k) => k.baslik), contains(startsWith('657 sayılı Devlet Memurları Kanunu, md. 102')));
      expect(c.surum, BilgiBankasi.surum);
      expect(c.uyari, isNotNull);
      expect(c.ornek, isFalse);
    });

    test('bilinmeyen soruda kaynak/uydurma yok, desteklenen konuları önerir', () async {
      final c = await asistan.sor('Bilinmeyen bir şey');
      expect(c.kaynaklar, isEmpty);
      expect(c.surum, isNull);
      expect(c.oneriler, hasLength(YerelMevzuatAsistani.desteklenenKonular.length));
    });

    test('emeklilik 5510 sayılı Kanun alıntısıyla, 2008 öncesi uyarısıyla ve kendi sürüm notuyla yanıtlanır', () async {
      final c = await asistan.sor('emeklilik yaşı kaç');
      expect(c.metin, allOf(contains('58'), contains('60'), contains('9000 gün'), contains('emekliye sevk onayı')));
      expect(c.kaynaklar.first.baslik, startsWith('5510 sayılı Kanun, md. 28'));
      expect(c.kaynaklar.first.alinti, allOf(contains('58, erkek ise 60'), contains('en az 9000 gün')));
      expect(c.uyari, contains('2008 öncesinde'));
      expect(c.surum, BilgiBankasi.surum5510);
    });

    test('işçi konusu İş Kanunu alıntısı, kendi sürüm notu ve toplu iş sözleşmesi uyarısıyla yanıtlanır', () async {
      final c = await asistan.sor('yıllık izin kaç gün', kitle: Kitle.isci);
      expect(c.kaynaklar.first.baslik, startsWith('4857 sayılı İş Kanunu, md. 53'));
      expect(c.metin, allOf(contains('14 gün'), contains('20 gün'), contains('26 gün')));
      expect(c.uyari, contains('toplu iş sözleşmesi'));
      expect(c.surum, BilgiBankasi.surumIsKanunu);
      final oneriler = (await asistan.sor('bilinmeyen bir şey', kitle: Kitle.isci)).oneriler;
      expect(oneriler, contains('Kıdem tazminatı nasıl hesaplanır?'));
      expect(oneriler, isNot(contains('Becayiş şartları nedir?')));
    });

    test(
      'sözleşmeli kullanıcıya 4/B alıntısı ve sürüm notu; başka gruba ait konuda "senin için farklı olabilir" uyarısı',
      () async {
        final c = await asistan.sor('yıllık izin kaç gün', kitle: Kitle.sozlesmeli);
        expect(c.kaynaklar.first.baslik, startsWith('Sözleşmeli Personel Çalıştırılmasına İlişkin Esaslar, md. 9'));
        expect(c.surum, BilgiBankasi.surumSozlesmeli);
        expect(c.uyari, isNot(contains('farklı olabilir')), reason: 'kendi grubuna ait konu');

        final d = await asistan.sor('disiplin cezaları nelerdir', kitle: Kitle.sozlesmeli);
        expect(d.kaynaklar.first.baslik, startsWith('657 sayılı Devlet Memurları Kanunu'));
        expect(
          d.uyari,
          allOf(contains('memurlar (657 sayılı Kanun)'), contains('4/B sözleşmeli personel için farklı olabilir')),
        );

        final e = await asistan.sor('emeklilik yaşı', kitle: Kitle.sozlesmeli);
        expect(e.uyari, isNot(contains('farklı olabilir')), reason: 'herkes konusu');
      },
    );

    test('Becayiş kaynağı sabiti bilgi bankasıyla aynı maddeyi gösterir', () {
      final k = BilgiBankasi.konular.firstWhere((k) => k.id == 'becayis');
      expect(k.kaynaklar.single.alinti, YerelMevzuatAsistani.becayisKaynagi.alinti);
    });
  });
}
