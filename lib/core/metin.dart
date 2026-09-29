/// Türkçe kurallarına göre büyük harfe çevirir (i → İ, ı → I).
/// Dart'ın `toUpperCase()` metodu "Milli" için "MILLI" verir; dilekçe
/// başlıklarında bu yanlış olur.
String buyukHarf(String s) => s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

/// 41250 → "41.250" (Türkçe binlik ayırıcı).
String binlik(num n) {
  final s = n.round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return n < 0 ? '-$b' : b.toString();
}

/// 249.99 → "₺249,99". Binlik ayırıcı gerekmediği için basit tutuldu.
String lira(double tutar) => '₺${tutar.toStringAsFixed(2).replaceAll('.', ',')}';

/// 41250 → "₺41.250" (kuruşsuz, büyük tutarlar için).
String liraTam(num tutar) => '₺${binlik(tutar)}';

const _gunler = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
const _aylar = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

/// "Salı, 29 Eylül" (intl paketi gerektirmeden).
String kisaTarih(DateTime t) => '${_gunler[t.weekday - 1]}, ${t.day} ${_aylar[t.month - 1]}';

/// Karşılaştırma/arama için Türkçe harfleri doğru küçülten normalleştirme
/// (İ → i, I → ı; sonra küçük harf).
String normalize(String s) => s.trim().replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();

/// Arama için: [normalize] ve ek olarak Türkçe harfler sadeleştirilir
/// ("SAGLIK" ile "Sağlık" eşleşir). Eşleştirme kimliği için değil, yalnızca
/// kullanıcının yazdığı arama metni için kullanılır.
String aramaAnahtari(String s) {
  const kaynak = 'çğıöşü';
  const hedef = 'cgiosu';
  final k = normalize(s);
  final b = StringBuffer();
  for (final r in k.runes) {
    final c = String.fromCharCode(r);
    final i = kaynak.indexOf(c);
    b.write(i < 0 ? c : hedef[i]);
  }
  return b.toString();
}
