/// Türkçe kurallarına göre büyük harfe çevirir (i → İ, ı → I).
/// Dart'ın `toUpperCase()` metodu "Milli" için "MILLI" verir; dilekçe
/// başlıklarında bu yanlış olur.
String buyukHarf(String s) => s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

/// 249.99 → "₺249,99". Binlik ayırıcı gerekmediği için basit tutuldu.
String lira(double tutar) => '₺${tutar.toStringAsFixed(2).replaceAll('.', ',')}';
