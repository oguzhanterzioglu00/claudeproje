import '../../core/metin.dart';
import 'bilgi_bankasi.dart';

/// Cevabın dayandığı mevzuat maddesi.
class MevzuatKaynagi {
  const MevzuatKaynagi({required this.baslik, this.alinti});

  /// Ör. "657 sayılı Devlet Memurları Kanunu, md. 73".
  final String baslik;

  /// Maddeden doğrudan alıntı (varsa).
  final String? alinti;
}

class AsistanCevabi {
  const AsistanCevabi({
    required this.metin,
    this.kaynaklar = const [],
    this.ornek = false,
    this.oneriler = const [],
    this.uyari,
    this.surum,
  });

  final String metin;
  final List<MevzuatKaynagi> kaynaklar;

  /// Gerçek mevzuattan üretilmemiş demo cevabı; ekranda "ÖRNEK CEVAP" görünür.
  final bool ornek;

  /// Kullanıcıya dokunarak sorabileceği örnek sorular (belirsiz ya da bilinmeyen soruda).
  final List<String> oneriler;

  /// Cevabın kanun dışında kalan yönü için dikkat notu.
  final String? uyari;

  /// Cevabın dayandığı metnin sürüm bilgisi.
  final String? surum;
}

/// "Hakkım ne?" mevzuat asistanı sözleşmesi. Gerçek sürümde arka uç, mevzuat
/// metinleri üzerinde kaynak gösteren bir arama/üretim hattı çalıştırır
/// (bkz. docs/asistan-ve-haber-spec.md).
abstract interface class MevzuatAsistani {
  Future<AsistanCevabi> sor(String soru);
}

/// Soru–konu eşleştirmesinin sonucu.
class BilgiEslesmesi {
  const BilgiEslesmesi({this.konu, this.adaylar = const []});

  /// Kesin eşleşen konu; belirsiz ya da eşleşme yoksa null.
  final BilgiKonusu? konu;

  /// Eşit puanlı birden çok konu varsa onlar (kullanıcıdan netleştirmesi istenir).
  final List<BilgiKonusu> adaylar;
}

/// Sorudaki anahtar kelimelere göre bilgi bankasında konu bulur. Türkçe harf
/// farkları ve büyük/küçük harf önemsizdir.
abstract final class BilgiArama {
  /// Genel "izin" sözcüğü tek başına belirleyici değildir; yalnızca destekleyici puan verir.
  static double _agirlik(String anahtar) {
    if (anahtar == 'izin') return 0.5;
    return anahtar.contains(' ') ? 2 : 1;
  }

  static double puan(BilgiKonusu k, String soru) {
    var toplam = 0.0;
    for (final a in k.anahtarlar) {
      if (soru.contains(a)) toplam += _agirlik(a);
    }
    return toplam;
  }

  static BilgiEslesmesi esles(String soru, {List<BilgiKonusu> konular = BilgiBankasi.konular}) {
    final s = aramaAnahtari(soru);
    final puanlar = [for (final k in konular) (k, puan(k, s))];
    final en = puanlar.fold<double>(0, (m, e) => e.$2 > m ? e.$2 : m);
    if (en <= 0) return const BilgiEslesmesi();
    final ust = [
      for (final e in puanlar)
        if (e.$2 == en) e.$1
    ];
    return ust.length == 1 ? BilgiEslesmesi(konu: ust.first) : BilgiEslesmesi(adaylar: ust);
  }
}

/// Cihazda çalışan, doğrulanmış kanun metinlerine dayalı asistan: cevapları
/// [BilgiBankasi]'ndan, kaynak maddeden alıntıyla birlikte verir. Bilmediği konuda
/// uydurma içerik üretmez; hangi konuları yanıtlayabildiğini söyler.
class YerelMevzuatAsistani implements MevzuatAsistani {
  const YerelMevzuatAsistani({this.sure = const Duration(milliseconds: 700)});

  /// Düşünüyor animasyonu için yapay gecikme.
  final Duration sure;

  static const becayisKaynagi = MevzuatKaynagi(
    baslik: '657 sayılı Devlet Memurları Kanunu, md. 73 (Karşılıklı yer değiştirme)',
    alinti: 'Aynı Kurumun başka başka yerlerde bulunan aynı sınıftaki memurları, karşılıklı olarak '
        'yer değiştirme suretiyle atanmalarını isteyebilirler. Bu isteğin yerine getirilmesi '
        'atamaya yetkili amirlerince uygun bulunmasına bağlıdır.',
  );

  /// Hızlı soru düğmeleri: her konunun örnek sorusu.
  static List<BilgiKonusu> get desteklenenKonular => BilgiBankasi.konular.where((k) => !k.kapsamDisi).toList();

  @override
  Future<AsistanCevabi> sor(String soru) async {
    await Future<void>.delayed(sure);
    final e = BilgiArama.esles(soru);

    if (e.konu != null) {
      final k = e.konu!;
      return AsistanCevabi(
        metin: k.cevap,
        kaynaklar: k.kaynaklar,
        uyari: k.uyari,
        surum: k.kapsamDisi ? null : (k.surum ?? BilgiBankasi.surum),
      );
    }

    if (e.adaylar.isNotEmpty) {
      return AsistanCevabi(
        metin: 'Sorun birkaç konuya girebilir. Hangisini öğrenmek istersin?',
        oneriler: [for (final k in e.adaylar) k.ornekSoru],
      );
    }

    return AsistanCevabi(
      metin: 'Bu soru için kanun metninden dayanaklı bir cevap bulamadım, tahmin yürütmek istemem. '
          'Şu konularda kaynak göstererek cevap verebilirim:',
      oneriler: [for (final k in desteklenenKonular) k.ornekSoru],
    );
  }
}
