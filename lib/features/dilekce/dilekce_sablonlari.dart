import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/metin.dart';
import '../profil/domain/profil.dart';

/// Dilekçe formundaki bir alanın türü.
enum AlanTuru { tarih, sayi, metin, secim }

/// Şablondaki doldurulacak alan.
@immutable
class DilekceAlani {
  const DilekceAlani(
    this.id,
    this.etiket, {
    this.tur = AlanTuru.metin,
    this.ipucu = '',
    this.zorunlu = true,
    this.secenekler = const [],
    this.enAz = 1,
    this.enCok = 365,
  });

  final String id;
  final String etiket;
  final AlanTuru tur;
  final String ipucu;
  final bool zorunlu;

  /// [AlanTuru.secim] için seçenekler.
  final List<String> secenekler;

  /// [AlanTuru.sayi] için sınırlar.
  final int enAz;
  final int enCok;
}

/// Kullanıcının girdiği değerler. Boş ve eksik alanlar şablonda `[…]` olarak görünür.
@immutable
class DilekceGirdisi {
  const DilekceGirdisi({
    required this.profil,
    required this.tarih,
    this.metinler = const {},
    this.tarihler = const {},
    this.sayilar = const {},
  });

  final Profil? profil;

  /// Dilekçenin tarihi.
  final DateTime tarih;
  final Map<String, String> metinler;
  final Map<String, DateTime> tarihler;
  final Map<String, int> sayilar;

  String metin(String id) => (metinler[id] ?? '').trim();
}

/// Kullanıcıya gösterilen sonuç: dilekçe metni ve eksik kalan zorunlu alanlar.
@immutable
class DilekceSonucu {
  const DilekceSonucu(this.metin, this.eksikAlanlar, this.eksikProfil);

  final String metin;

  /// Doldurulmamış zorunlu form alanlarının etiketleri.
  final List<String> eksikAlanlar;

  /// Profilde olmayan bilgiler (ör. "kurum adı").
  final List<String> eksikProfil;

  bool get tamam => eksikAlanlar.isEmpty && eksikProfil.isEmpty;
}

/// Dilekçe türleri. Madde numaraları uygulamanın doğrulanmış mevzuat bilgi bankasındaki (bkz.
/// `bilgi_bankasi.dart`) 657 sayılı Devlet Memurları Kanunu maddeleridir; yeni bir atıf eklenirken kaynağıyla
/// doğrulanmalıdır. Şablonlar genel bir örnektir: kurumun kendi form ya da yazım kuralları varsa onlara uyulmalıdır.
enum DilekceTuru {
  yillikIzin(
    'Yıllık izin',
    'İzin talebi',
    LucideIcons.palmtree,
    Color(0xFF12B5D6),
    'Yıllık izin kullanmak için amire verilen talep',
    'md. 102 ve 103',
    [
      DilekceAlani('baslangic', 'İzne başlama tarihi', tur: AlanTuru.tarih),
      DilekceAlani('gun', 'İzin süresi (gün)', tur: AlanTuru.sayi, enCok: 90),
      DilekceAlani('adres', 'İzin süresince ulaşılacak adres', ipucu: 'İsteğe bağlı', zorunlu: false),
    ],
  ),
  mazeretIzni(
    'Mazeret izni',
    'Diğer mazeretler',
    LucideIcons.clock,
    Color(0xFFFBB040),
    'Zorunlu bir mazeret için 10 güne kadar izin talebi',
    'md. 104/C',
    [
      DilekceAlani('baslangic', 'İzne başlama tarihi', tur: AlanTuru.tarih),
      DilekceAlani('gun', 'İzin süresi (gün)', tur: AlanTuru.sayi, enCok: 20),
      DilekceAlani('mazeret', 'Mazeretin', ipucu: 'Örn. ailevi bir zorunluluk'),
    ],
  ),
  evlilikOlum(
    'Evlilik ve ölüm izni',
    'Yedi gün',
    LucideIcons.heart,
    Color(0xFFC43F9C),
    'Evlilik ya da yakın kaybında istek üzerine 7 gün izin',
    'md. 104/B',
    [
      DilekceAlani(
        'olay',
        'Olay',
        tur: AlanTuru.secim,
        secenekler: ['Kendi evlenmem', 'Çocuğumun evlenmesi', 'Yakınımın vefatı'],
      ),
      DilekceAlani('yakinlik', 'Vefat eden yakının', ipucu: 'Örn. babam, eşimin annesi'),
      DilekceAlani('baslangic', 'İzne başlama tarihi', tur: AlanTuru.tarih),
    ],
  ),
  hastalik(
    'Hastalık raporu',
    'Rapor bildirimi',
    LucideIcons.stethoscope,
    Color(0xFF2F63B5),
    'Alınan istirahat raporunu kuruma bildirme',
    'md. 105',
    [
      DilekceAlani('raporTarihi', 'Raporun başlangıç tarihi', tur: AlanTuru.tarih),
      DilekceAlani('gun', 'Rapor süresi (gün)', tur: AlanTuru.sayi, enCok: 180),
      DilekceAlani('saglikKurumu', 'Raporu veren sağlık kuruluşu', ipucu: 'Örn. Ankara Şehir Hastanesi'),
    ],
  ),
  aylikSizIzin(
    'Aylıksız izin',
    'Beş hizmet yılından sonra',
    LucideIcons.calendarOff,
    Color(0xFF7B3FA0),
    '5 hizmet yılını dolduran memurun aylıksız izin talebi',
    'md. 108/E',
    [
      DilekceAlani('baslangic', 'İzne başlama tarihi', tur: AlanTuru.tarih),
      DilekceAlani('ay', 'İstenen süre (ay)', tur: AlanTuru.sayi, enCok: 12),
      DilekceAlani('gerekce', 'Gerekçen', ipucu: 'İsteğe bağlı', zorunlu: false),
    ],
  ),
  kurumIciAtama(
    'Kurum içi atama',
    'İstek üzerine',
    LucideIcons.mapPin,
    Color(0xFF0E7C93),
    'Aynı kurum içinde başka bir yere atanma isteği',
    'md. 76',
    [
      DilekceAlani('hedefYer', 'İstediğin görev yeri', ipucu: 'Örn. İzmir il müdürlüğü'),
      DilekceAlani('gerekce', 'Gerekçen', ipucu: 'Örn. ailevi nedenler', zorunlu: false),
    ],
  ),
  kurumlarArasiNakil(
    'Kurumlar arası nakil',
    'Kurum muvafakatiyle',
    LucideIcons.arrowRightLeft,
    Color(0xFF182350),
    'Başka bir kuruma nakil isteği',
    'md. 74',
    [
      DilekceAlani('hedefKurum', 'Nakil istediğin kurum', ipucu: 'Örn. Sağlık Bakanlığı'),
      DilekceAlani('hedefYer', 'İstediğin görev yeri', ipucu: 'İsteğe bağlı', zorunlu: false),
      DilekceAlani('gerekce', 'Gerekçen', ipucu: 'İsteğe bağlı', zorunlu: false),
    ],
  ),
  esDurumu(
    'Eş durumu ataması',
    'Aile birliği',
    LucideIcons.users,
    Color(0xFFE0553F),
    'Memur olan eşin görev yerine atanma isteği',
    'md. 72',
    [
      DilekceAlani('esKurum', 'Eşinin görev yaptığı kurum', ipucu: 'Örn. Milli Eğitim Müdürlüğü'),
      DilekceAlani('hedefYer', 'Eşinin görev yeri (istediğin yer)', ipucu: 'Örn. Konya'),
    ],
  );

  const DilekceTuru(this.baslik, this.alt, this.ikon, this.renk, this.aciklama, this.madde, this.alanlar);

  final String baslik;
  final String alt;
  final IconData ikon;
  final Color renk;
  final String aciklama;

  /// Dilekçede atıf yapılan madde (657 sayılı Kanun).
  final String madde;
  final List<DilekceAlani> alanlar;

  /// Kullanıcının bilmesi gereken kısa şart/uyarı (formda gösterilir).
  String? get uyari => switch (this) {
    aylikSizIzin =>
      'Bu izin için 5 hizmet yılını tamamlamış olman gerekir; toplam süre memuriyet boyunca en fazla 1 yıldır '
          've en çok iki defada kullanılabilir.',
    kurumlarArasiNakil => 'Nakil, iki kurumun da muvafakatine bağlıdır; dilekçe yalnızca isteğini bildirir.',
    mazeretIzni => 'Bir yıl içinde 10 gün, zaruret hâlinde 10 gün daha verilebilir; ikinci kez verilen yıllık izinden düşülür.',
    evlilikOlum => 'Evlilik ya da yakın kaybında, istek üzerine yedi gün izin verilir.',
    _ => null,
  };

  static String tarihMetni(DateTime t) =>
      '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';

  /// 0-99 arası sayının yazıyla gösterimi ("7" -> "yedi").
  static String sayiYazi(int n) {
    const birler = ['', 'bir', 'iki', 'üç', 'dört', 'beş', 'altı', 'yedi', 'sekiz', 'dokuz'];
    const onlar = ['', 'on', 'yirmi', 'otuz', 'kırk', 'elli', 'altmış', 'yetmiş', 'seksen', 'doksan'];
    if (n == 0) return 'sıfır';
    if (n < 0 || n > 99) return '$n';
    return '${onlar[n ~/ 10]}${birler[n % 10]}';
  }

  static String _gun(int n) => '$n (${sayiYazi(n)}) gün';

  /// Dilekçeyi üretir. Eksik bilgiler `[…]` ile işaretlenir ve [DilekceSonucu]'nda listelenir.
  DilekceSonucu uret(DilekceGirdisi g) {
    final p = g.profil;
    final eksikProfil = <String>[];
    String profilden(String ad, String? deger, String yer) {
      final d = (deger ?? '').trim();
      if (d.isEmpty) {
        eksikProfil.add(ad);
        return yer;
      }
      return d;
    }

    final ad = profilden('ad soyad', p?.ad, '[Ad Soyad]');
    final kurum = profilden('kurum adı', p?.kurumAdi, '[Kurum adı]');
    final unvan = profilden('unvan', p?.unvan, '[Unvan]');
    final sicil = (p?.sicilNo ?? '').trim();
    if (sicil.isEmpty) eksikProfil.add('sicil no');

    final eksikAlanlar = <String>[];
    String m(String id) {
      final a = alanlar.firstWhere((x) => x.id == id);
      final d = g.metin(id);
      if (d.isEmpty && a.zorunlu) eksikAlanlar.add(a.etiket);
      return d.isEmpty ? '[…]' : d;
    }

    String t(String id) {
      final a = alanlar.firstWhere((x) => x.id == id);
      final d = g.tarihler[id];
      if (d == null) {
        if (a.zorunlu) eksikAlanlar.add(a.etiket);
        return '[gg.aa.yyyy]';
      }
      return tarihMetni(d);
    }

    String s(String id) {
      final a = alanlar.firstWhere((x) => x.id == id);
      final d = g.sayilar[id];
      if (d == null || d < a.enAz || d > a.enCok) {
        if (a.zorunlu) eksikAlanlar.add(a.etiket);
        return '[…]';
      }
      return '$d';
    }

    String sayiliGun(String id) {
      final d = g.sayilar[id];
      final a = alanlar.firstWhere((x) => x.id == id);
      if (d == null || d < a.enAz || d > a.enCok) {
        eksikAlanlar.add(a.etiket);
        return '[…] gün';
      }
      return _gun(d);
    }

    final giris = '$kurum bünyesinde $unvan olarak görev yapmaktayım.';
    late final String govde;
    late final String konu;

    switch (this) {
      case yillikIzin:
        konu = 'Yıllık izin talebi hakkında.';
        final adres = g.metin('adres');
        govde =
            '$giris 657 sayılı Devlet Memurları Kanunu\'nun 102 ve 103. maddeleri uyarınca, ${t('baslangic')} '
            'tarihinden itibaren ${sayiliGun('gun')} yıllık izin kullanmak istiyorum.'
            '${adres.isEmpty ? '' : '\n\nİzin süresince ulaşılabileceğim adres: $adres'}';
      case mazeretIzni:
        konu = 'Mazeret izni talebi hakkında.';
        govde =
            '$giris Aşağıda belirttiğim mazeretim nedeniyle, 657 sayılı Devlet Memurları Kanunu\'nun 104. '
            'maddesinin (C) bendi uyarınca ${t('baslangic')} tarihinden itibaren ${sayiliGun('gun')} mazeret izni '
            'kullanmak istiyorum.\n\nMazeretim: ${m('mazeret')}';
      case evlilikOlum:
        konu = 'İzin talebi hakkında.';
        final olay = g.metin('olay');
        final vefat = olay == 'Yakınımın vefatı';
        if (olay.isEmpty) eksikAlanlar.add('Olay');
        final yakin = vefat ? m('yakinlik') : '';
        final neden = switch (olay) {
          'Kendi evlenmem' => 'evlenmem',
          'Çocuğumun evlenmesi' => 'çocuğumun evlenmesi',
          'Yakınımın vefatı' => '$yakin vefatı',
          _ => '[…]',
        };
        govde =
            '$giris $neden nedeniyle, 657 sayılı Devlet Memurları Kanunu\'nun 104. maddesinin (B) bendi uyarınca '
            '${t('baslangic')} tarihinden itibaren ${_gun(7)} izin kullanmak istiyorum.';
      case hastalik:
        konu = 'Hastalık raporunun bildirilmesi hakkında.';
        govde =
            '$giris ${m('saglikKurumu')} tarafından düzenlenen, ${t('raporTarihi')} tarihinden itibaren '
            '${sayiliGun('gun')} istirahat öngören raporum nedeniyle, 657 sayılı Devlet Memurları Kanunu\'nun 105. '
            'maddesi gereğince hastalık iznimin kullandırılmasını talep ediyorum. Raporumun bir örneği ekte sunulmuştur.';
      case aylikSizIzin:
        konu = 'Aylıksız izin talebi hakkında.';
        final gerekce = g.metin('gerekce');
        govde =
            '$giris 5 hizmet yılımı tamamlamış bulunmaktayım. 657 sayılı Devlet Memurları Kanunu\'nun 108. '
            'maddesinin (E) bendi uyarınca ${t('baslangic')} tarihinden itibaren ${s('ay')} ay süreyle aylıksız '
            'izin kullanmak istiyorum.${gerekce.isEmpty ? '' : '\n\nGerekçem: $gerekce'}';
      case kurumIciAtama:
        konu = 'İstek üzerine atama talebi hakkında.';
        final gerekce = g.metin('gerekce');
        govde =
            '$giris 657 sayılı Devlet Memurları Kanunu\'nun 76. maddesi uyarınca, kurumumuzun ${m('hedefYer')} '
            'görev yerindeki uygun bir kadroya naklen atanmamı talep ediyorum.'
            '${gerekce.isEmpty ? '' : '\n\nGerekçem: $gerekce'}';
      case kurumlarArasiNakil:
        konu = 'Kurumlar arası nakil talebi hakkında.';
        final yer = g.metin('hedefYer');
        final gerekce = g.metin('gerekce');
        govde =
            '$giris 657 sayılı Devlet Memurları Kanunu\'nun 74. maddesi uyarınca, ${m('hedefKurum')}'
            '${yer.isEmpty ? '' : ' $yer görev yerindeki'} uygun bir kadroya, kurumların muvafakatiyle naklen '
            'atanmamı talep ediyorum.${gerekce.isEmpty ? '' : '\n\nGerekçem: $gerekce'}';
      case esDurumu:
        konu = 'Eş durumu nedeniyle atama talebi hakkında.';
        govde =
            '$giris Eşim ${m('esKurum')} bünyesinde memur olarak görev yapmaktadır. Aile birliğinin korunması '
            'amacıyla, 657 sayılı Devlet Memurları Kanunu\'nun 72. maddesi uyarınca ${m('hedefYer')} görev yerine '
            'atanmamı talep ediyorum.';
    }

    final metin = StringBuffer()
      ..writeln('T.C.')
      ..writeln(buyukHarf(kurum))
      ..writeln('İlgili Makama')
      ..writeln()
      ..writeln('Tarih: ${tarihMetni(g.tarih)}')
      ..writeln('Konu: $konu')
      ..writeln()
      ..writeln(govde)
      ..writeln()
      ..writeln('Gereğini bilgilerinize arz ederim.')
      ..writeln()
      ..writeln(ad)
      ..writeln(unvan)
      ..writeln(sicil.isEmpty ? 'Sicil No: [...]' : 'Sicil No: $sicil')
      ..write('İmza:');

    return DilekceSonucu(metin.toString(), eksikAlanlar, eksikProfil);
  }
}
