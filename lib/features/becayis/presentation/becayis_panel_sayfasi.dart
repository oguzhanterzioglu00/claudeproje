import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/tema.dart';
import '../../../core/ucgenler.dart';
import '../../../core/yukselen.dart';
import '../domain/eslesme.dart';
import '../domain/ilan.dart';

/// Becayiş sekmesinin paneli: ilanım, sayılar ve en yeni eşleşme.
class BecayisPanelSayfasi extends StatelessWidget {
  const BecayisPanelSayfasi({
    super.key,
    required this.benim,
    required this.eslesmeler,
    this.eslesmeAc,
    this.ilanlariGor,
    this.ilaniDuzenle,
  });

  final Ilan benim;
  final List<Eslesme> eslesmeler;
  final ValueChanged<Eslesme>? eslesmeAc;
  final VoidCallback? ilanlariGor;
  final VoidCallback? ilaniDuzenle;

  @override
  Widget build(BuildContext context) {
    final ikili = eslesmeler.where((e) => e.tip == EslesmeTipi.ikili).toList();
    final zincir = eslesmeler.where((e) => e.tip == EslesmeTipi.zincir).length;
    final enYeni = ikili.isEmpty ? null : ikili.first;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
        children: [
          const Yukselen(child: _Baslik()),
          const SizedBox(height: 14),
          Yukselen(
            gecikme: const Duration(milliseconds: 100),
            child: _IlanKarti(ilan: benim),
          ),
          const SizedBox(height: 14),
          Yukselen(
            gecikme: const Duration(milliseconds: 200),
            child: Row(
              children: [
                Expanded(
                  child: _Sayi(
                    renk: KadroRenk.mor,
                    on: KadroRenk.beyaz,
                    ikon: LucideIcons.users,
                    sayi: ikili.length,
                    etiket: 'Eşleşme',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Sayi(
                    renk: KadroRenk.turkuaz,
                    on: KadroRenk.lacivert,
                    ikon: LucideIcons.arrowRightLeft,
                    sayi: zincir,
                    etiket: "3'lü zincir",
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Sayi(
                    renk: KadroRenk.amber,
                    on: KadroRenk.lacivert,
                    ikon: LucideIcons.mapPin,
                    sayi: benim.hedefIller.length,
                    etiket: 'Hedef il',
                  ),
                ),
              ],
            ),
          ),
          if (enYeni != null) ...[
            const SizedBox(height: 16),
            Yukselen(
              gecikme: const Duration(milliseconds: 400),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Yeni eşleşme', style: KadroYazi.baslik(18, agirlik: FontWeight.w700, aralik: -0.4)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: KadroRenk.kirmizi,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('Az önce', style: KadroYazi.metin(12, renk: KadroRenk.beyaz, agirlik: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Yukselen(
              gecikme: const Duration(milliseconds: 480),
              child: _EslesmeKarti(
                benim: benim,
                eslesme: enYeni,
                onTap: eslesmeAc == null ? null : () => eslesmeAc!(enYeni),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Yukselen(
            gecikme: const Duration(milliseconds: 560),
            child: Row(
              children: [
                Expanded(
                  child: _EylemKarti(
                    renk: KadroRenk.mavi,
                    on: KadroRenk.beyaz,
                    ikon: LucideIcons.search,
                    baslik: 'İlanları gör',
                    alt: 'Tüm illerden ilanlar',
                    onTap: ilanlariGor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EylemKarti(
                    renk: KadroRenk.amber,
                    on: KadroRenk.lacivert,
                    ikon: LucideIcons.pencil,
                    baslik: 'İlanı düzenle',
                    alt: 'Hedef illeri değiştir',
                    onTap: ilaniDuzenle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Baslik extends StatelessWidget {
  const _Baslik();

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Karşılıklı yer değiştirme', style: KadroYazi.metin(12, renk: KadroRenk.soluk, agirlik: FontWeight.w700)),
              Text('Becayiş', style: KadroYazi.baslik(26, aralik: -1.2)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: KadroRenk.lacivert,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('ÖRNEK', style: KadroYazi.metin(11, renk: KadroRenk.amber, agirlik: FontWeight.w700)),
          ),
        ],
      );
}

class _IlanKarti extends StatelessWidget {
  const _IlanKarti({required this.ilan});

  final Ilan ilan;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          color: KadroRenk.lacivert,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Stack(
            children: [
              const Positioned(
                right: -80,
                top: -90,
                child: Opacity(
                  opacity: 0.45,
                  child: KadroUcgenler(boyut: 210, orta: KadroRenk.mavi),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('İLANIM', style: KadroYazi.metin(12, renk: const Color(0xFFC9D0E0), agirlik: FontWeight.w700)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: KadroRenk.beyaz.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: Color(0xFFB7E88A), shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text('Yayında', style: KadroYazi.metin(12, renk: KadroRenk.beyaz, agirlik: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(ilan.unvan, style: KadroYazi.baslik(32, renk: KadroRenk.beyaz, aralik: -1.4)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, size: 15, color: Color(0xFFC9D0E0)),
                      const SizedBox(width: 6),
                      Text('${ilan.kurumAdi} · ${ilan.mevcutIl}', style: KadroYazi.metin(14, renk: const Color(0xFFC9D0E0))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Gitmek istediğin iller', style: KadroYazi.metin(12, renk: const Color(0xFFC9D0E0))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final il in ilan.hedefIller)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                          decoration: BoxDecoration(
                            color: KadroRenk.beyaz.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(il, style: KadroYazi.metin(12, renk: KadroRenk.beyaz, agirlik: FontWeight.w700)),
                        ),
                    ],
                  ),
                  if (ilan.maviTik) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(LucideIcons.badgeCheck, size: 18, color: KadroRenk.amber),
                        const SizedBox(width: 8),
                        Text('Mavi tik · kurumsal e-posta doğrulandı',
                            style: KadroYazi.metin(13, renk: KadroRenk.amber, agirlik: FontWeight.w700)),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
}

class _Sayi extends StatelessWidget {
  const _Sayi({
    required this.renk,
    required this.on,
    required this.ikon,
    required this.sayi,
    required this.etiket,
  });

  final Color renk;
  final Color on;
  final IconData ikon;
  final int sayi;
  final String etiket;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$sayi $etiket',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: KadroRenk.beyaz,
            border: Border.all(color: KadroRenk.lacivert, width: 1.5),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: renk, borderRadius: BorderRadius.circular(12)),
                child: Icon(ikon, size: 18, color: on),
              ),
              const SizedBox(height: 8),
              Text('$sayi', style: KadroYazi.baslik(24, aralik: -1)),
              Text(etiket, style: KadroYazi.metin(12, renk: KadroRenk.soluk)),
            ],
          ),
        ),
      );
}

class _EslesmeKarti extends StatelessWidget {
  const _EslesmeKarti({required this.benim, required this.eslesme, this.onTap});

  final Ilan benim;
  final Eslesme eslesme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final diger = eslesme.ilanlar.firstWhere((i) => i.id != benim.id);
    final uyari = eslesme.uyarilar.isEmpty ? null : eslesme.uyarilar.first;

    return Material(
      color: KadroRenk.beyaz,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: const BorderSide(color: KadroRenk.lacivert, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          child: Row(
            children: [
              _SkorHalkasi(skor: eslesme.skor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${diger.gorunenAd} · ${diger.unvan}', style: KadroYazi.metin(15, agirlik: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text('${diger.mevcutIl} → ${benim.mevcutIl} · ${diger.kurumAdi}',
                        style: KadroYazi.metin(13, renk: KadroRenk.soluk, agirlik: FontWeight.w500)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(uyari == null ? LucideIcons.check : LucideIcons.info,
                            size: 14, color: uyari == null ? KadroRenk.yesilYazi : KadroRenk.soluk),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            uyari ?? 'Kurum, sınıf ve unvan eşleşti',
                            style: KadroYazi.metin(12,
                                renk: uyari == null ? KadroRenk.yesilYazi : KadroRenk.soluk,
                                agirlik: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: KadroRenk.amber, borderRadius: BorderRadius.circular(14)),
                child: const Icon(LucideIcons.chevronRight, size: 20, color: KadroRenk.lacivert),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkorHalkasi extends StatelessWidget {
  const _SkorHalkasi({required this.skor});

  final int skor;

  @override
  Widget build(BuildContext context) {
    final hareketsiz = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Uyum skoru yüzde $skor',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 56,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: hareketsiz ? skor / 100 : 0, end: skor / 100),
          duration: hareketsiz ? Duration.zero : const Duration(milliseconds: 1400),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: v,
                  strokeWidth: 5,
                  strokeCap: StrokeCap.round,
                  backgroundColor: KadroRenk.cizgi,
                  color: KadroRenk.amber,
                ),
              ),
              Text('${(v * 100).round()}', style: KadroYazi.baslik(15, aralik: -0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EylemKarti extends StatelessWidget {
  const _EylemKarti({
    required this.renk,
    required this.on,
    required this.ikon,
    required this.baslik,
    required this.alt,
    this.onTap,
  });

  final Color renk;
  final Color on;
  final IconData ikon;
  final String baslik;
  final String alt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: renk,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: SizedBox(
            height: 110,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: on.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(ikon, size: 22, color: on),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(baslik, style: KadroYazi.baslik(16, renk: on, aralik: -0.5)),
                      Text(alt, style: KadroYazi.metin(12, renk: on)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
