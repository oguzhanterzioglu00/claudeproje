import '../domain/hesap.dart';

/// Kullanıcıya gösterilebilir bir kimlik doğrulama hatası.
class KimlikHatasi implements Exception {
  const KimlikHatasi(this.mesaj, {this.bilgi = false});

  final String mesaj;

  /// true ise bir hata değil, kullanıcıya bildirilen bir durumdur (ör. "doğrulama e-postası gönderildi");
  /// arayüzde kırmızı hata yerine bilgi olarak gösterilir.
  final bool bilgi;

  @override
  String toString() => mesaj;
}

/// Kayıt oldu ama e-posta doğrulaması bekleniyor: hesap açıldı, giriş doğrulamadan sonra yapılabilir.
class EpostaDogrulamaBekleniyor extends KimlikHatasi {
  const EpostaDogrulamaBekleniyor(String eposta)
    : super(
        'Doğrulama bağlantısını $eposta adresine gönderdik. Bağlantıya dokunduktan sonra giriş yap.',
        bilgi: true,
      );
}

/// Kimlik servisinin arka plandan bildirdiği olaylar (ör. tarayıcıdan Google ile dönüş, şifre sıfırlama bağlantısı).
enum KimlikOlayTuru { oturumAcildi, oturumKapandi, sifreKurtarma }

class KimlikOlayi {
  const KimlikOlayi(this.tur, [this.hesap]);

  final KimlikOlayTuru tur;
  final Hesap? hesap;
}

/// Hesap işlemleri. Gerçek sürümde [SupabaseKimlikServisi] (e-posta ve Google ile giriş) bu arayüzü uygular;
/// arka uç yapılandırılmamışsa (geliştirme ve testler) cihazda çalışan [YerelKimlikServisi] kullanılır.
abstract interface class KimlikServisi {
  /// Gerçek bir arka uca bağlı mı? false ise hesaplar yalnızca cihazdadır ve arayüz bunu "örnek" olarak belirtir.
  bool get gercek;

  /// Arka planda gelen oturum olayları (tarayıcıdan dönüş, şifre sıfırlama bağlantısı...).
  Stream<KimlikOlayi> get olaylar;

  /// Cihazda açık oturum varsa hesabı döner.
  Future<Hesap?> mevcut();

  Future<Hesap> kayitOl({required String eposta, required String sifre});
  Future<Hesap> girisYap({required String eposta, required String sifre});

  /// Google (veya desteklenen başka bir sağlayıcı) ile giriş.
  Future<Hesap> saglayiciIleGiris(GirisSaglayici saglayici);

  Future<void> sifreDegistir({required String eskiSifre, required String yeniSifre});

  /// Şifre sıfırlama bağlantısı ister. Hesap var/yok bilgisi sızdırılmaz.
  Future<void> sifreSifirlamaIste(String eposta);

  /// Sıfırlama bağlantısıyla gelen kullanıcı için yeni şifre belirler.
  Future<void> kurtarmaSifresiBelirle(String yeniSifre);

  Future<void> cikisYap();

  /// Hesabı kalıcı olarak siler (mağaza kuralları ve KVKK silme hakkı).
  Future<void> hesabiSil();
}
