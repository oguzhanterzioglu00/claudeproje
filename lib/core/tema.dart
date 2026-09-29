import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kadro renkleri (Ayas Software logosundan). Tasarımdaki değerlerle aynıdır.
abstract final class KadroRenk {
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

/// Başlıklar Sora, gövde metni Figtree.
ThemeData kadroTema() {
  final taban = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: KadroRenk.zemin,
    colorScheme: ColorScheme.fromSeed(
      seedColor: KadroRenk.lacivert,
      primary: KadroRenk.lacivert,
      secondary: KadroRenk.amber,
      surface: KadroRenk.beyaz,
    ),
  );

  final govde = GoogleFonts.figtreeTextTheme(taban.textTheme).apply(
    bodyColor: KadroRenk.lacivert,
    displayColor: KadroRenk.lacivert,
  );

  return taban.copyWith(
    textTheme: govde.copyWith(
      headlineSmall: GoogleFonts.sora(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        color: KadroRenk.lacivert,
      ),
      titleLarge: GoogleFonts.sora(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: KadroRenk.lacivert,
      ),
    ),
  );
}
