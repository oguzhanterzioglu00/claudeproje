/// Henüz mağazaya gönderilmeyecek özellikleri derleme bayraklarıyla hazır tutar.
///
/// Örnek:
/// `--dart-define=BECAYIS_ACIK=true --dart-define=BECAYIS_ODEME_ACIK=true`
abstract final class OzellikAyari {
  static const becayisAcik = bool.fromEnvironment(
    'BECAYIS_ACIK',
    defaultValue: false,
  );
  static const becayisOdemeAcik = bool.fromEnvironment(
    'BECAYIS_ODEME_ACIK',
    defaultValue: false,
  );
  static const reklamAlaniAcik = bool.fromEnvironment(
    'REKLAM_ALANI_ACIK',
    defaultValue: false,
  );
}
