/// Arka uç (Supabase) bağlantı ayarları. Derleme sırasında verilir:
///
/// ```sh
/// flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
/// ```
///
/// Yayınlanabilir (publishable) anahtar, eski adıyla anon anahtarı, herkese açık olacak şekilde tasarlanmıştır (istemciye gömülür); veriyi korumak anahtarın gizliliği
/// değil, veritabanındaki satır düzeyi güvenlik (RLS) kurallarıdır (bkz. `docs/supabase/kurulum.sql`). Yine de
/// anahtarlar depoya yazılmaz, derleme komutuna ya da CI sırlarına verilir. Ayar yoksa uygulama geliştirme kipinde
/// cihaz içi örnek hesapla açılır (arayüz bunu "örnek" olarak belirtir).
abstract final class SunucuAyari {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const _yayinlanabilir = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const _eskiAnon = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Google Cloud **Web** OAuth istemci kimliği (yerel Google girişi için; gizli değildir, anahtar/secret değildir).
  /// Verilmezse Google girişi tarayıcıdan yapılır.
  static const googleWebIstemcisi = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  /// İstemci anahtarı: yeni "publishable" ya da eski "anon" anahtarı (ikisi de çalışır).
  static String get anahtar => _yayinlanabilir.isNotEmpty ? _yayinlanabilir : _eskiAnon;

  /// Arka uç bağlantısı verilmiş mi?
  static bool get tanimli => url.isNotEmpty && anahtar.isNotEmpty;
}
