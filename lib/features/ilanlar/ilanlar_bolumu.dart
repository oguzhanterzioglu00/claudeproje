import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/bilesenler.dart';
import '../../core/tema.dart';
import '../../core/yukselen.dart';
import 'ilan_kaynagi.dart';
import 'ilan_modeli.dart';

/// Ana sayfadaki "Yeni ilanlar": kullanıcının türlerine uyan, en yeni açık ilanlar. Dokununca İlanlar
/// sekmesine gidilir. İlanlar yüklenemez ya da uygun ilan yoksa bölüm sessizce gizlenir.
class IlanlarBolumu extends StatefulWidget {
  const IlanlarBolumu({
    super.key,
    required this.kaynak,
    required this.turler,
    required this.tumunuAc,
    this.bugun,
    this.adet = 3,
  });

  final IlanKaynagi kaynak;

  /// Gösterilecek ilan türleri (statüye göre).
  final Set<IlanTuru> turler;
  final VoidCallback tumunuAc;
  final DateTime? bugun;
  final int adet;

  @override
  State<IlanlarBolumu> createState() => _IlanlarBolumuState();
}

class _IlanlarBolumuState extends State<IlanlarBolumu> {
  late final Future<List<KamuIlani>> _ilanlar = widget.kaynak.getir();

  DateTime get _bugun => widget.bugun ?? DateTime.now();

  @override
  Widget build(BuildContext context) => FutureBuilder<List<KamuIlani>>(
    future: _ilanlar,
    builder: (context, snap) {
      final hepsi = snap.data;
      if (hepsi == null) return const SizedBox.shrink();
      final liste = [
        for (final i in hepsi)
          if (widget.turler.contains(i.tur) && i.acikMi(_bugun)) i,
      ].take(widget.adet).toList();
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
                label: 'Yeni ilanlar, tüm ilanlar',
                excludeSemantics: true,
                onTap: widget.tumunuAc,
                child: InkWell(
                  onTap: widget.tumunuAc,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Yeni ilanlar', style: PusulaYazi.baslik(18, agirlik: FontWeight.w700, aralik: -0.4)),
                        Row(
                          children: [
                            Text(
                              'Tümü',
                              style: PusulaYazi.metin(13, renk: PusulaRenk.mavi, agirlik: FontWeight.w700),
                            ),
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
              for (final i in liste) ...[
                _Satir(ilan: i, bugun: _bugun, onTap: widget.tumunuAc),
                const SizedBox(height: 8),
              ],
              Text(
                'Kaynak: ${liste.first.kaynakAdi.split(' (').first}',
                style: PusulaYazi.metin(11, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Satir extends StatelessWidget {
  const _Satir({required this.ilan, required this.bugun, required this.onTap});

  final KamuIlani ilan;
  final DateTime bugun;
  final VoidCallback onTap;

  static String _kisalt(String s) => s.length <= 100 ? s : '${s.substring(0, 100).trimRight()}...';

  @override
  Widget build(BuildContext context) {
    final baslamadi = ilan.baslamadiMi(bugun);
    final kalan = ilan.kalanGun(bugun);
    return PusulaKart(
      onTap: onTap,
      radius: 20,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: PusulaRenk.zemin, borderRadius: BorderRadius.circular(14)),
            child: const Icon(LucideIcons.briefcase, size: 20, color: PusulaRenk.lacivert),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ilan.kurum.isNotEmpty)
                  Text(
                    ilan.kurum,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w700),
                  ),
                Text(
                  _kisalt(ilan.baslik),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PusulaYazi.metin(14, agirlik: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  baslamadi
                      ? 'Başvurular ${ilan.yayinTarihi.day.toString().padLeft(2, '0')}.${ilan.yayinTarihi.month.toString().padLeft(2, '0')}.${ilan.yayinTarihi.year} tarihinde başlar'
                      : kalan == null
                      ? ilan.tur.etiket
                      : '${ilan.tur.etiket} · $kalan gün kaldı',
                  style: PusulaYazi.metin(12, renk: PusulaRenk.lacivert, agirlik: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
