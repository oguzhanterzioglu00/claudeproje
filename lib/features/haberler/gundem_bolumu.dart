import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/tema.dart';
import '../../core/yukselen.dart';
import 'haber_kaynagi.dart';
import 'haber_modeli.dart';
import 'haber_slaytlari.dart';
import 'haberler_sayfasi.dart';

/// Görselli haber slaytları bölümü: ana sayfadaki "Gündem" ve maaş ekranındaki
/// "Maaş ve özlük haberleri". [turler] verilirse yalnızca o türler gösterilir.
/// Haberler yüklenemez ya da boşsa bölüm sessizce gizlenir.
class GundemBolumu extends StatefulWidget {
  const GundemBolumu({
    super.key,
    this.kaynak = const OrnekHaberKaynagi(),
    this.bugun,
    this.adet = 5,
    this.baslik = 'Gündem',
    this.turler,
    this.otomatik = true,
    this.kaynagiAc,
  });

  final HaberKaynagi kaynak;
  final DateTime? bugun;
  final int adet;
  final String baslik;
  final Set<HaberTuru>? turler;
  final bool otomatik;
  final ValueChanged<Haber>? kaynagiAc;

  @override
  State<GundemBolumu> createState() => _GundemBolumuState();
}

class _GundemBolumuState extends State<GundemBolumu> {
  late final Future<List<Haber>> _haberler = widget.kaynak.getir();

  DateTime get _bugun => widget.bugun ?? DateTime.now();

  void _tumu() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => HaberlerSayfasi(kaynak: widget.kaynak, bugun: widget.bugun, kaynagiAc: widget.kaynagiAc),
    ),
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Haber>>(
    future: _haberler,
    builder: (context, snap) {
      final hepsi = snap.data;
      if (hepsi == null) return const SizedBox.shrink();
      final liste = hepsi.where((h) => widget.turler == null || widget.turler!.contains(h.tur)).take(widget.adet).toList();
      if (liste.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Yukselen(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                container: true,
                button: true,
                label: '${widget.baslik}, tüm haberler',
                excludeSemantics: true,
                onTap: _tumu,
                child: InkWell(
                  onTap: _tumu,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.baslik, style: PusulaYazi.baslik(18, agirlik: FontWeight.w700, aralik: -0.4)),
                        Row(
                          children: [
                            Text('Tümü', style: PusulaYazi.metin(13, renk: PusulaRenk.mavi, agirlik: FontWeight.w700)),
                            const SizedBox(width: 4),
                            const Icon(LucideIcons.arrowRight, size: 16, color: PusulaRenk.mavi),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              HaberSlaytlari(
                haberler: liste,
                bugun: _bugun,
                otomatik: widget.otomatik,
                onAc: (h) => haberAyrintisiAc(context, h, bugun: _bugun, kaynagiAc: widget.kaynagiAc),
              ),
            ],
          ),
        ),
      );
    },
  );
}
