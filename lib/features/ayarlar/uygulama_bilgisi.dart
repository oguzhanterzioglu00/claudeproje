/// Uygulamanın sürüm bilgisi. `pubspec.yaml`'daki `version` ile aynı tutulur
/// (bir test bunu denetler).
abstract final class UygulamaBilgisi {
  static const ad = 'Kamu Pusulası';
  static const surum = '1.0.0';
  static const derleme = '1';
  static const surumMetni = '$surum ($derleme)';

  /// Mağaza ve kullanıcı için: uygulama hiçbir kamu kurumunun resmî uygulaması değildir.
  static const bagimsizlikNotu =
      '$ad bağımsız bir uygulamadır; hiçbir kamu kurumunun, sendikanın ya da resmî kuruluşun uygulaması '
      'değildir ve onlarla bağlantılı değildir. Mevzuat bilgisi resmî kaynaklardan derlenir; ilan ve haberlerin '
      'kaynağı her kartta belirtilir.';
}
