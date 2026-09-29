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
          expect(kaynak.baslik,
              anyOf(startsWith('657 sayılı Devlet Memurları Kanunu, md. '), startsWith('5510 sayılı Kanun, ')),
              reason: k.id);
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
          allOf(
              contains('onaltı hafta'), contains('yirmidört hafta'), contains('on gün babalık'), contains('yedi gün')));
      expect(cevap('mazeret_izni'),
          allOf(contains('16 hafta'), contains('24 hafta'), contains('10 gün'), contains('7 gün')));

      expect(alinti('hastalik_izni'), allOf(contains('onsekiz aya'), contains('oniki aya'), contains('üç aya')));
      expect(cevap('hastalik_izni'), allOf(contains('18 aya'), contains('12 aya'), contains('3 aya')));

      expect(alinti('ayliksiz_izin'), allOf(contains('onsekiz aya'), contains('yirmidört aya'), contains('bir yıla')));
      expect(cevap('ayliksiz_izin'), allOf(contains('18 aya'), contains('24 aya'), contains('1 yıla')));

      expect(alinti('kademe_derece'),
          allOf(contains('en az bir yıl'), contains('en az 3 yıl'), contains('3 üncü kademesinde 1 yıl')));
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
          e.adaylar.map((k) => k.id), containsAll(['yillik_izin', 'mazeret_izni', 'hastalik_izni', 'ayliksiz_izin']));
    });

    test('her konunun kendi örnek sorusu kendi konusuna gider', () {
      for (final k in BilgiBankasi.konular) {
        expect(BilgiArama.esles(k.ornekSoru).konu?.id, k.id, reason: k.ornekSoru);
      }
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

    test('Becayiş kaynağı sabiti bilgi bankasıyla aynı maddeyi gösterir', () {
      final k = BilgiBankasi.konular.firstWhere((k) => k.id == 'becayis');
      expect(k.kaynaklar.single.alinti, YerelMevzuatAsistani.becayisKaynagi.alinti);
    });
  });
}
