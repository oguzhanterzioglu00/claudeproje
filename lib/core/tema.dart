import 'package:flutter/material.dart';

/// Pusula renkleri (Ayas Software logosundan). Tasarımdaki değerlerle aynıdır.
abstract final class PusulaRenk {
  static const lacivert = Color(0xFF182350);
  static const mavi = Color(0xFF2F63B5);
  static const turkuaz = Color(0xFF12B5D6);
  static const amber = Color(0xFFFBB040);
  static const eflatun = Color(0xFFC43F9C);
  static const mor = Color(0xFF7B3FA0);
  static const zemin = Color(0xFFF5F4F9);
  static const soluk = Color(0xFF5A6273);
  static const kirmizi = Color(0xFFE0553F);
  static const cizgi = Color(0xFFE8E6F0);
  static const yesilZemin = Color(0xFFE7F7D4);
  static const yesilYazi = Color(0xFF2C5A0B);
  static const beyaz = Color(0xFFFFFFFF);
}

/// Sık kullanılan yazı stilleri. Başlıklar Sora, gövde metni Figtree
/// (ikisi de uygulamaya gömülü; bkz. pubspec.yaml).
abstract final class PusulaYazi {
  static const baslikAilesi = 'Sora';
  static const metinAilesi = 'Figtree';

  /// Sora ve Figtree'de olmayan ₺ işareti için gömülü yedek yazı.
  static const liraAilesi = 'PusulaLira';
  static const _yedek = [liraAilesi];

  static TextStyle baslik(
    double boyut, {
    Color renk = PusulaRenk.lacivert,
    double aralik = -0.5,
    FontWeight agirlik = FontWeight.w800,
  }) =>
      TextStyle(
        fontFamily: baslikAilesi,
        fontFamilyFallback: _yedek,
        fontSize: boyut,
        fontWeight: agirlik,
        letterSpacing: aralik,
        color: renk,
        height: 1.15,
      );

  static TextStyle metin(
    double boyut, {
    Color renk = PusulaRenk.lacivert,
    FontWeight agirlik = FontWeight.w600,
  }) =>
      TextStyle(
        fontFamily: metinAilesi,
        fontFamilyFallback: _yedek,
        fontSize: boyut,
        fontWeight: agirlik,
        color: renk,
      );
}

ThemeData pusulaTema() {
  final taban = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: PusulaRenk.zemin,
    colorScheme: ColorScheme.fromSeed(
      seedColor: PusulaRenk.lacivert,
      primary: PusulaRenk.lacivert,
      secondary: PusulaRenk.amber,
      surface: PusulaRenk.beyaz,
    ),
  );

  final govde = taban.textTheme.apply(
    fontFamily: PusulaYazi.metinAilesi,
    bodyColor: PusulaRenk.lacivert,
    displayColor: PusulaRenk.lacivert,
  );

  return taban.copyWith(
    textTheme: govde.copyWith(
      headlineSmall: PusulaYazi.baslik(24, aralik: -1),
      titleLarge: PusulaYazi.baslik(18, agirlik: FontWeight.w700, aralik: -0.4),
    ),
  );
}
