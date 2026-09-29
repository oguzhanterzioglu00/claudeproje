import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/avatar.dart';
import '../../../core/bilesenler.dart';
import '../../../core/tema.dart';
import '../../../core/yukselen.dart';
import '../data/fotograf_deposu.dart';

/// Profil fotoğrafı seçme alanı: büyük önizleme, kamera, galeri ve kaldırma.
/// İlk kurulum adımı olarak ve [FotografSayfasi] içinde kullanılır.
class FotografAlani extends StatefulWidget {
  const FotografAlani({super.key, required this.depo, required this.kaynak, this.ad = ''});

  final FotografDeposu depo;
  final FotografKaynagi kaynak;
  final String ad;

  @override
  State<FotografAlani> createState() => _FotografAlaniState();
}

class _FotografAlaniState extends State<FotografAlani> {
  bool _mesgul = false;
  String? _hata;

  Future<void> _al(Future<Uint8List?> Function() getir) async {
    if (_mesgul) return;
    setState(() {
      _mesgul = true;
      _hata = null;
    });
    try {
      final bayt = await getir();
      if (bayt != null) await widget.depo.ayarla(bayt);
    } on FotografHatasi catch (h) {
      _hata = h.mesaj;
    } catch (_) {
      _hata = 'Fotoğraf eklenemedi. Tekrar dene.';
    }
    if (mounted) setState(() => _mesgul = false);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.depo,
        builder: (context, _) {
          final foto = widget.depo.foto;
          final hareketsiz = MediaQuery.disableAnimationsOf(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: AnimatedSwitcher(
                  duration: hareketsiz ? Duration.zero : const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutBack,
                  transitionBuilder: (c, anim) =>
                      ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: c)),
                  child: ProfilAvatar(
                    key: ValueKey(foto == null ? 0 : Object.hash(foto.length, foto.first, foto.last)),
                    boyut: 168,
                    foto: foto,
                    ad: widget.ad,
                    kamera: true,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Yukselen(
                child: _Secenek(
                  ikon: LucideIcons.camera,
                  baslik: 'Fotoğraf çek',
                  alt: 'Kamerayla şimdi çek',
                  onTap: _mesgul ? null : () => _al(widget.kaynak.cek),
                ),
              ),
              const SizedBox(height: 10),
              Yukselen(
                gecikme: const Duration(milliseconds: 80),
                child: _Secenek(
                  ikon: LucideIcons.image,
                  baslik: 'Galeriden seç',
                  alt: 'Telefondaki bir fotoğrafı kullan',
                  onTap: _mesgul ? null : () => _al(widget.kaynak.galeridenSec),
                ),
              ),
              if (foto != null) ...[
                const SizedBox(height: 10),
                _Secenek(
                  ikon: LucideIcons.trash2,
                  baslik: 'Fotoğrafı kaldır',
                  alt: 'Baş harflerin gösterilir',
                  tehlike: true,
                  onTap: _mesgul ? null : widget.depo.kaldir,
                ),
              ],
              if (_hata != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(_hata!,
                      textAlign: TextAlign.center,
                      style: PusulaYazi.metin(13, renk: PusulaRenk.kirmizi, agirlik: FontWeight.w700)),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.shield, size: 15, color: PusulaRenk.soluk),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text('Fotoğrafın yalnızca bu cihazda saklanır',
                        style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)),
                  ),
                ],
              ),
            ],
          );
        },
      );
}

class _Secenek extends StatelessWidget {
  const _Secenek(
      {required this.ikon, required this.baslik, required this.alt, required this.onTap, this.tehlike = false});

  final IconData ikon;
  final String baslik;
  final String alt;
  final VoidCallback? onTap;
  final bool tehlike;

  @override
  Widget build(BuildContext context) {
    final renk = tehlike ? PusulaRenk.kirmizi : PusulaRenk.lacivert;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: '$baslik. $alt',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: PusulaRenk.beyaz,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: renk, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tehlike ? const Color(0xFFFCE8E4) : PusulaRenk.amber,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(ikon, size: 22, color: renk),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(baslik, style: PusulaYazi.metin(15, renk: renk, agirlik: FontWeight.w700)),
                      Text(alt, style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Profilden açılan tam ekran fotoğraf sayfası.
class FotografSayfasi extends StatelessWidget {
  const FotografSayfasi({super.key, required this.depo, required this.kaynak, this.ad = ''});

  final FotografDeposu depo;
  final FotografKaynagi kaynak;
  final String ad;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
            children: [
              const Yukselen(
                child: GeriBaslik(ustYazi: 'Profilim', baslik: 'Fotoğraf', sag: SizedBox.shrink()),
              ),
              const SizedBox(height: 28),
              FotografAlani(depo: depo, kaynak: kaynak, ad: ad),
              const SizedBox(height: 22),
              BirincilDugme(yukseklik: 56, metin: 'Bitti', onPressed: () => Navigator.of(context).maybePop()),
            ],
          ),
        ),
      );
}
