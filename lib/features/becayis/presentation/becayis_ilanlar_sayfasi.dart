import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/bilesenler.dart';
import '../../../core/tema.dart';
import '../../../core/yukselen.dart';
import '../data/becayis_deposu.dart';
import '../domain/eslesme.dart';
import '../domain/ilan.dart';

/// Diğer kullanıcıların becayiş ilanları; ile göre süzülür.
class BecayisIlanlarSayfasi extends StatefulWidget {
  const BecayisIlanlarSayfasi({
    super.key,
    required this.depo,
    this.eslesmeAc,
    this.ilanVer,
  });

  final BecayisDeposu depo;
  final ValueChanged<Eslesme>? eslesmeAc;
  final VoidCallback? ilanVer;

  @override
  State<BecayisIlanlarSayfasi> createState() => _BecayisIlanlarSayfasiState();
}

class _BecayisIlanlarSayfasiState extends State<BecayisIlanlarSayfasi> {
  static const _tumu = 'Tüm iller';
  static const _hizliIller = [
    _tumu, 'Ankara', 'İstanbul', 'İzmir', 'Bursa', 'Eskişehir', 'Ordu', 'Antalya',
  ];

  String _il = _tumu;

  bool _uyar(Ilan i) =>
      _il == _tumu || i.mevcutIl == _il || i.hedefIller.contains(_il);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.depo,
        builder: (context, _) {
          final liste = widget.depo.digerleri.where(_uyar).toList();
          return Scaffold(
            floatingActionButton: widget.ilanVer == null
                ? null
                : _IlanVerDugmesi(onTap: widget.ilanVer!),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 96),
                children: [
                  Yukselen(
                    child: GeriBaslik(ustYazi: '${liste.length} açık ilan', baslik: 'İlanları gör', sag: const OrnekRozeti()),
                  ),
                  const SizedBox(height: 14),
                  Yukselen(
                    gecikme: const Duration(milliseconds: 100),
                    child: SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _hizliIller.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final il = _hizliIller[i];
                          final secili = il == _il;
                          return Semantics(
                            selected: secili,
                            button: true,
                            child: Material(
                              color: secili ? PusulaRenk.lacivert : PusulaRenk.beyaz,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => setState(() => _il = il),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Center(
                                    child: Text(
                                      il,
                                      style: PusulaYazi.metin(
                                        13,
                                        renk: secili ? PusulaRenk.beyaz : PusulaRenk.lacivert,
                                        agirlik: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (liste.isEmpty)
                    const _BosDurum()
                  else
                    for (var k = 0; k < liste.length; k++) ...[
                      Yukselen(
                        gecikme: Duration(milliseconds: 150 + k * 80),
                        child: _IlanKarti(
                          ilan: liste[k],
                          sira: k,
                          skor: widget.depo.uyumSkoru(liste[k]),
                          onUyum: widget.eslesmeAc == null
                              ? null
                              : () => widget.eslesmeAc!(widget.depo.eslesmeler.firstWhere(
                                  (e) => e.tip == EslesmeTipi.ikili && e.icerir(liste[k].id))),
                        ),
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

class _IlanKarti extends StatelessWidget {
  const _IlanKarti({required this.ilan, required this.sira, required this.skor, this.onUyum});

  final Ilan ilan;
  final int sira;
  final int? skor;
  final VoidCallback? onUyum;

  static const _renkler = [
    (PusulaRenk.mor, PusulaRenk.beyaz),
    (PusulaRenk.mavi, PusulaRenk.beyaz),
    (PusulaRenk.turkuaz, PusulaRenk.lacivert),
    (PusulaRenk.amber, PusulaRenk.lacivert),
  ];

  @override
  Widget build(BuildContext context) {
    final (zemin, yazi) = _renkler[sira % _renkler.length];
    return PusulaKart(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: zemin, borderRadius: BorderRadius.circular(15)),
                child: Text(ilan.unvan.characters.first, style: PusulaYazi.baslik(20, renk: yazi)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(ilan.unvan,
                              overflow: TextOverflow.ellipsis,
                              style: PusulaYazi.metin(16, agirlik: FontWeight.w700)),
                        ),
                        if (ilan.maviTik) ...[
                          const SizedBox(width: 6),
                          Semantics(
                            label: 'Mavi tik',
                            child: const Icon(LucideIcons.badgeCheck, size: 17, color: PusulaRenk.mavi),
                          ),
                        ],
                      ],
                    ),
                    Text(ilan.kurumAdi,
                        overflow: TextOverflow.ellipsis,
                        style: PusulaYazi.metin(13, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: PusulaRenk.zemin,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.mapPin, size: 14, color: PusulaRenk.lacivert),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${ilan.mevcutIl} → ${ilan.hedefIller.first}',
                          overflow: TextOverflow.ellipsis,
                          style: PusulaYazi.metin(13, agirlik: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (skor != null)
                Material(
                  color: PusulaRenk.amber,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onUyum,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
                      child: SizedBox(
                        height: 32,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('%$skor uyum',
                                style: PusulaYazi.metin(12, agirlik: FontWeight.w700)),
                            const Icon(LucideIcons.chevronRight, size: 16, color: PusulaRenk.lacivert),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BosDurum extends StatelessWidget {
  const _BosDurum();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: PusulaRenk.beyaz,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: PusulaRenk.lacivert, width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: PusulaRenk.cizgi, borderRadius: BorderRadius.circular(16)),
              child: const Icon(LucideIcons.search, size: 24, color: PusulaRenk.lacivert),
            ),
            const SizedBox(height: 8),
            Text('Bu ilde ilan yok', style: PusulaYazi.metin(16, agirlik: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('İlk ilanı sen ver, eşleşme seni bulsun.',
                textAlign: TextAlign.center,
                style: PusulaYazi.metin(13, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)),
          ],
        ),
      );
}

class _IlanVerDugmesi extends StatelessWidget {
  const _IlanVerDugmesi({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: PusulaRenk.lacivert,
        shape: const StadiumBorder(),
        elevation: 3,
        shadowColor: PusulaRenk.lacivert.withValues(alpha: 0.35),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 20, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.plus, size: 22, color: PusulaRenk.amber),
                  const SizedBox(width: 8),
                  Text('İlan ver',
                      style: PusulaYazi.metin(14, renk: PusulaRenk.beyaz, agirlik: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      );
}
