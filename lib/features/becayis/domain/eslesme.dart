import 'ilan.dart';

enum EslesmeTipi { ikili, zincir }

/// Bulunan bir becayiş eşleşmesi.
///
/// [ilanlar] zincirde çevrim sırasındadır: her ilan sahibi, listede kendinden
/// sonrakinin bulunduğu ile gider; sonuncu ilk ilanın iline gider.
class Eslesme {
  const Eslesme({
    required this.tip,
    required this.ilanlar,
    required this.skor,
    this.uyarilar = const [],
  });

  final EslesmeTipi tip;
  final List<Ilan> ilanlar;

  /// 0-100 arası, ürün kararıyla ayarlanabilir puan.
  final int skor;

  /// Kullanıcıya gösterilecek uyarılar (ör. farklı unvan).
  final List<String> uyarilar;

  /// Aynı eşleşme için sıralamadan bağımsız kararlı kimlik.
  String get id {
    final ids = ilanlar.map((i) => i.id).toList();
    if (tip == EslesmeTipi.ikili) ids.sort();
    return '${tip.name}:${ids.join('>')}';
  }

  bool icerir(String ilanId) => ilanlar.any((i) => i.id == ilanId);
}
