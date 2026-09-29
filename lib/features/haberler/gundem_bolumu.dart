import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/tema.dart';
import '../../core/yukselen.dart';
import 'haber_kaynagi.dart';
import 'haber_modeli.dart';
import 'haberler_sayfasi.dart';

/// Ana sayfadaki "Gündem" bölümü: en yeni [adet] haber ve "Tümü" bağlantısı.
/// Haberler yüklenemezse ana sayfayı bozmaz; bölüm sessizce gizlenir.
class GundemBolumu extends StatefulWidget {
  const GundemBolumu({
    super.key,
    this.kaynak = const OrnekHaberKaynagi(),
    this.bugun,
    this.adet = 3,
    this.kaynagiAc,
  });

  final HaberKaynagi kaynak;
  final DateTime? bugun;
  final int adet;
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
          final liste = snap.data;
          if (liste == null || liste.isEmpty) return const SizedBox.shrink();
          final gorunen = liste.take(widget.adet).toList();
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Yukselen(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    button: true,
                    label: 'Gündem, tüm haberler',
                    excludeSemantics: true,
                    onTap: _tumu,
                    child: InkWell(
                      onTap: _tumu,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Gündem',
                                style: PusulaYazi.baslik(18, agirlik: FontWeight.w700, aralik: -0.4)),
                            Row(children: [
                              Text('Tümü',
                                  style: PusulaYazi.metin(13, renk: PusulaRenk.mavi, agirlik: FontWeight.w700)),
                              const SizedBox(width: 4),
                              const Icon(LucideIcons.arrowRight, size: 16, color: PusulaRenk.mavi),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final h in gorunen) ...[
                    HaberKarti(
                      haber: h,
                      bugun: _bugun,
                      onTap: () => haberAyrintisiAc(context, h, bugun: _bugun, kaynagiAc: widget.kaynagiAc),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          );
        },
      );
}
