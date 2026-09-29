import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'tema.dart';

/// Yuvarlak profil görseli: fotoğraf varsa o, yoksa adın baş harfleri.
/// [kamera] true ise köşede "fotoğraf değiştir" rozeti çıkar.
class ProfilAvatar extends StatelessWidget {
  const ProfilAvatar({super.key, required this.boyut, this.foto, this.ad = '', this.kamera = false});

  final double boyut;
  final Uint8List? foto;
  final String ad;
  final bool kamera;

  /// "Ayşe Yılmaz" → "AY"; boşsa "".
  static String basHarfler(String ad) {
    final parcalar = ad.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parcalar.isEmpty) return '';
    // Türkçe: i → İ, ı → I.
    String buyuk(String s) => switch (s) {
          'i' => 'İ',
          'ı' => 'I',
          _ => s.toUpperCase(),
        };
    final a = buyuk(parcalar.first.characters.first);
    if (parcalar.length == 1) return a;
    return a + buyuk(parcalar.last.characters.first);
  }

  @override
  Widget build(BuildContext context) {
    final harfler = basHarfler(ad);
    final daire = Container(
      width: boyut,
      height: boyut,
      decoration: const BoxDecoration(color: PusulaRenk.amber, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: foto != null
          ? Image.memory(foto!, width: boyut, height: boyut, fit: BoxFit.cover, gaplessPlayback: true)
          : harfler.isEmpty
              ? Icon(LucideIcons.userRound, size: boyut * 0.5, color: PusulaRenk.lacivert)
              : Text(harfler, style: PusulaYazi.baslik(boyut * 0.38, aralik: -0.5)),
    );
    return Semantics(
      label: foto != null ? 'Profil fotoğrafı' : (harfler.isEmpty ? 'Profil simgesi' : 'Profil: $ad'),
      image: true,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: boyut,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            daire,
            if (kamera)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: boyut * 0.32,
                  height: boyut * 0.32,
                  decoration: BoxDecoration(
                    color: PusulaRenk.lacivert,
                    shape: BoxShape.circle,
                    border: Border.all(color: PusulaRenk.zemin, width: 2),
                  ),
                  child: Icon(LucideIcons.camera, size: boyut * 0.16, color: PusulaRenk.beyaz),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
