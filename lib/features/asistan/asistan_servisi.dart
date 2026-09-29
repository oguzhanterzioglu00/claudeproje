/// Cevabın dayandığı mevzuat maddesi.
class MevzuatKaynagi {
  const MevzuatKaynagi({required this.baslik, this.alinti});

  /// Ör. "657 sayılı Devlet Memurları Kanunu, md. 73".
  final String baslik;

  /// Maddeden doğrudan alıntı (varsa).
  final String? alinti;
}

class AsistanCevabi {
  const AsistanCevabi({required this.metin, this.kaynaklar = const [], this.ornek = false});

  final String metin;
  final List<MevzuatKaynagi> kaynaklar;

  /// Gerçek mevzuattan üretilmemiş demo cevabı; ekranda "ÖRNEK CEVAP" görünür.
  final bool ornek;
}

/// "Hakkım ne?" mevzuat asistanı sözleşmesi. Gerçek sürümde arka uç, mevzuat
/// metinleri üzerinde kaynak gösteren bir arama/üretim hattı çalıştırır
/// (bkz. docs/asistan-ve-haber-spec.md).
abstract interface class MevzuatAsistani {
  Future<AsistanCevabi> sor(String soru);
}

/// Arka uç bağlanana kadar: yalnızca doğrulanmış Becayiş maddesine gerçek
/// metinle cevap verir, diğer sorularda uydurma hukuki içerik üretmez.
class SahteAsistan implements MevzuatAsistani {
  const SahteAsistan({this.sure = const Duration(milliseconds: 900)});

  final Duration sure;

  static const becayisKaynagi = MevzuatKaynagi(
    baslik: '657 sayılı Devlet Memurları Kanunu, md. 73 (Karşılıklı yer değiştirme)',
    alinti: 'Aynı Kurumun başka başka yerlerde bulunan aynı sınıftaki memurları, karşılıklı olarak '
        'yer değiştirme suretiyle atanmalarını isteyebilirler. Bu isteğin yerine getirilmesi '
        'atamaya yetkili amirlerince uygun bulunmasına bağlıdır.',
  );

  @override
  Future<AsistanCevabi> sor(String soru) async {
    await Future<void>.delayed(sure);
    if (soru.toLowerCase().contains('becayiş') || soru.toLowerCase().contains('becayis')) {
      return const AsistanCevabi(
        metin: 'Becayiş, aynı kurumda ve aynı sınıfta olup farklı yerlerde görev yapan iki memurun '
            'karşılıklı olarak yer değiştirmesidir. Talep, atamaya yetkili amirin uygun bulmasına bağlıdır; '
            'yani kurum reddedebilir.',
        kaynaklar: [becayisKaynagi],
      );
    }
    return const AsistanCevabi(
      metin: 'Bu örnek sürümde bu soru için mevzuattan cevap üretemiyorum. Gerçek asistan bağlandığında '
          'cevap, ilgili kanun maddesiyle birlikte burada görünecek.',
      ornek: true,
    );
  }
}
