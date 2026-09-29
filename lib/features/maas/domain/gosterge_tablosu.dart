/// 657 sayılı Devlet Memurları Kanunu md. 154 ekindeki I sayılı cetvel:
/// aylık gösterge tablosu (derece × kademe).
///
/// Kaynak: kanun metni (MEB Personel Genel Müdürlüğü PDF'i) ve Sinop Üniversitesi
/// yayını; iki kaynaktaki 15 satır birebir aynı çıktı. Tabloyu değiştiren bir
/// kanun/KHK çıkarsa yalnızca burası güncellenir.
abstract final class GostergeTablosu {
  static const enUstDerece = 15;

  /// Satır = derece (1..15). Eleman sayısı o derecedeki kademe sayısıdır:
  /// 1. derecede 4, 2. derecede 6, 3. derecede 8, diğerlerinde 9.
  static const _satirlar = <List<int>>[
    [1320, 1380, 1440, 1500],
    [1155, 1210, 1265, 1320, 1380, 1440],
    [1020, 1065, 1110, 1155, 1210, 1265, 1320, 1380],
    [915, 950, 985, 1020, 1065, 1110, 1155, 1210, 1265],
    [835, 865, 895, 915, 950, 985, 1020, 1065, 1110],
    [760, 785, 810, 835, 865, 895, 915, 950, 985],
    [705, 720, 740, 760, 785, 810, 835, 865, 895],
    [660, 675, 690, 705, 720, 740, 760, 785, 810],
    [620, 630, 645, 660, 675, 690, 705, 720, 740],
    [590, 600, 610, 620, 630, 645, 660, 675, 690],
    [560, 570, 580, 590, 600, 610, 620, 630, 645],
    [545, 550, 555, 560, 570, 580, 590, 600, 610],
    [530, 535, 540, 545, 550, 555, 560, 570, 580],
    [515, 520, 525, 530, 535, 540, 545, 550, 555],
    [500, 505, 510, 515, 520, 525, 530, 535, 540],
  ];

  static void _denetle(int derece) {
    if (derece < 1 || derece > enUstDerece) {
      throw ArgumentError.value(derece, 'derece', '1 ile $enUstDerece arasında olmalı');
    }
  }

  /// [derece] derecesindeki kademe sayısı.
  static int kademeSayisi(int derece) {
    _denetle(derece);
    return _satirlar[derece - 1].length;
  }

  /// [derece] ve [kademe] için aylık gösterge rakamı.
  static int gosterge(int derece, int kademe) {
    _denetle(derece);
    final satir = _satirlar[derece - 1];
    if (kademe < 1 || kademe > satir.length) {
      throw ArgumentError.value(kademe, 'kademe', '$derece. derecede kademe 1-${satir.length} olmalı');
    }
    return satir[kademe - 1];
  }

  /// [kademe] o derecede yoksa geçerli en yakın kademeye çeker.
  static int kademeSinirla(int derece, int kademe) {
    final en = kademeSayisi(derece);
    return kademe < 1 ? 1 : (kademe > en ? en : kademe);
  }
}
