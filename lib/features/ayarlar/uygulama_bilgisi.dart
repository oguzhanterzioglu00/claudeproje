/// Uygulamanın sürüm bilgisi. `pubspec.yaml`'daki `version` ile aynı tutulur
/// (bir test bunu denetler).
abstract final class UygulamaBilgisi {
  static const ad = 'Kamu Pusulası';
  static const surum = '0.1.0';
  static const derleme = '1';
  static const surumMetni = '$surum ($derleme)';
}
