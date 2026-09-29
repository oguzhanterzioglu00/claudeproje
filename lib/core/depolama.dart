import 'package:shared_preferences/shared_preferences.dart';

/// Küçük anahtar-değer saklama arayüzü. Uygulama cihazda `shared_preferences`,
/// testler bellek içi uygulamayla çalışır.
abstract interface class AnahtarDeger {
  Future<String?> oku(String anahtar);
  Future<void> yaz(String anahtar, String deger);
  Future<void> sil(String anahtar);
}

class BellekDepolama implements AnahtarDeger {
  BellekDepolama([Map<String, String>? baslangic]) : _veri = {...?baslangic};

  final Map<String, String> _veri;

  @override
  Future<String?> oku(String anahtar) async => _veri[anahtar];

  @override
  Future<void> yaz(String anahtar, String deger) async => _veri[anahtar] = deger;

  @override
  Future<void> sil(String anahtar) async => _veri.remove(anahtar);
}

class YerelDepolama implements AnahtarDeger {
  const YerelDepolama();

  @override
  Future<String?> oku(String anahtar) async {
    final tercihler = await SharedPreferences.getInstance();
    // Arka plan izolatı da aynı dosyaya yazar; önbellek eskimesin diye okumadan önce yenilenir.
    await tercihler.reload();
    return tercihler.getString(anahtar);
  }

  @override
  Future<void> yaz(String anahtar, String deger) async =>
      (await SharedPreferences.getInstance()).setString(anahtar, deger);

  @override
  Future<void> sil(String anahtar) async => (await SharedPreferences.getInstance()).remove(anahtar);
}
