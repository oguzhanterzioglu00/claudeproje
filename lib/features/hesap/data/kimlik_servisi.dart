import '../domain/hesap.dart';

/// Kullanıcıya gösterilebilir bir kimlik doğrulama hatası.
class KimlikHatasi implements Exception {
  const KimlikHatasi(this.mesaj);

  final String mesaj;

  @override
  String toString() => mesaj;
}

/// Hesap işlemleri. Gerçek sürümde arka uç (ör. Firebase Auth, Google ve Apple
/// ile giriş) bu arayüzü uygular; şimdilik [YerelKimlikServisi] vardır.
abstract interface class KimlikServisi {
  /// Cihazda açık oturum varsa hesabı döner.
  Future<Hesap?> mevcut();

  Future<Hesap> kayitOl({required String eposta, required String sifre});
  Future<Hesap> girisYap({required String eposta, required String sifre});

  /// Google veya Apple ile hızlı giriş.
  Future<Hesap> saglayiciIleGiris(GirisSaglayici saglayici);

  Future<void> sifreDegistir({required String eskiSifre, required String yeniSifre});

  /// Şifre sıfırlama bağlantısı ister. Hesap var/yok bilgisi sızdırılmaz.
  Future<void> sifreSifirlamaIste(String eposta);

  Future<void> cikisYap();

  /// Hesabı kalıcı olarak siler (mağaza kuralları ve KVKK silme hakkı).
  Future<void> hesabiSil();
}
