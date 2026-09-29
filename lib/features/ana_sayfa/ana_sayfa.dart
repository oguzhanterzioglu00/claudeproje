import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/avatar.dart';
import '../../core/bilesenler.dart';
import '../../core/metin.dart';
import '../../core/tema.dart';
import '../../core/logo.dart';
import '../../core/ucgenler.dart';
import '../../core/yukselen.dart';
import 'ana_sayfa_verisi.dart';

/// Ana sayfa: tahmini net maaş, yol haritası ve kısayollar.
class AnaSayfa extends StatelessWidget {
  const AnaSayfa({
    super.key,
    required this.veri,
    this.bugun,
    this.asistanaGit,
    this.becayisiAc,
    this.maasaGit,
    this.bildirimAc,
    this.profilAc,
    this.gundem,
    this.avatarFoto,
    this.avatarAd = '',
  });

  final AnaSayfaVerisi veri;

  /// Testlerde sabit tarih vermek için; boşsa bugün.
  final DateTime? bugun;
  final VoidCallback? asistanaGit;
  final VoidCallback? becayisiAc;
  final VoidCallback? maasaGit;
  final VoidCallback? bildirimAc;
  final VoidCallback? profilAc;

  /// Kısayolların altında gösterilen haber bölümü (isteğe bağlı).
  final Widget? gundem;

  /// Profil düğmesinde gösterilen fotoğraf ve ad (baş harfler için).
  final Uint8List? avatarFoto;
  final String avatarAd;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 16),
          children: [
            Yukselen(
                child: _Ust(
              tarih: kisaTarih(bugun ?? DateTime.now()),
              bildirimVar: veri.bildirimVar,
              onBildirim: bildirimAc,
              onProfil: profilAc,
              avatarFoto: avatarFoto,
              avatarAd: avatarAd,
            )),
            const SizedBox(height: 14),
            Yukselen(
              gecikme: const Duration(milliseconds: 100),
              child: _MaasKarti(veri: veri, onTap: maasaGit),
            ),
            if (veri.yolHaritasi.isNotEmpty) ...[
              const SizedBox(height: 16),
              Yukselen(
                gecikme: const Duration(milliseconds: 200),
                child: Semantics(
                  container: true,
                  button: maasaGit != null,
                  label: 'Yol haritan, detay',
                  excludeSemantics: true,
                  onTap: maasaGit,
                  child: InkWell(
                    onTap: maasaGit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Yol haritan', style: PusulaYazi.baslik(18, agirlik: FontWeight.w700, aralik: -0.4)),
                          Row(children: [
                            Text('Detay',
                                style: PusulaYazi.metin(13, renk: PusulaRenk.mavi, agirlik: FontWeight.w700)),
                            const SizedBox(width: 4),
                            const Icon(LucideIcons.arrowRight, size: 16, color: PusulaRenk.mavi),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Yukselen(
                gecikme: const Duration(milliseconds: 300),
                child: _YolHaritasi(ogeler: veri.yolHaritasi),
              ),
            ],
            const SizedBox(height: 14),
            Yukselen(
              gecikme: const Duration(milliseconds: 400),
              child: Row(
                children: [
                  Expanded(
                    child: _Kisayol(
                      renk: PusulaRenk.mor,
                      on: PusulaRenk.beyaz,
                      ikonRengi: PusulaRenk.amber,
                      ikon: LucideIcons.sparkles,
                      baslik: 'Hakkım ne?',
                      alt: 'Kaynaklı cevap al',
                      onTap: asistanaGit,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Kisayol(
                      renk: PusulaRenk.amber,
                      on: PusulaRenk.lacivert,
                      ikonRengi: PusulaRenk.lacivert,
                      ikon: LucideIcons.arrowRightLeft,
                      baslik: 'Becayiş',
                      alt: veri.becayisAlt,
                      onTap: becayisiAc,
                    ),
                  ),
                ],
              ),
            ),
            if (gundem != null) gundem!,
          ],
        ),
      );
}

class _Ust extends StatelessWidget {
  const _Ust({
    required this.tarih,
    required this.bildirimVar,
    this.onBildirim,
    this.onProfil,
    this.avatarFoto,
    this.avatarAd = '',
  });

  final String tarih;
  final bool bildirimVar;
  final VoidCallback? onBildirim;
  final VoidCallback? onProfil;
  final Uint8List? avatarFoto;
  final String avatarAd;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const PusulaLogo(boyut: 42, koseOrani: 0.33),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kamu Pusulası',
                          overflow: TextOverflow.ellipsis, style: PusulaYazi.baslik(20, aralik: -0.8)),
                      Text(tarih, style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'Profilim',
            excludeSemantics: true,
            onTap: onProfil,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onProfil,
              child: Container(
                width: 46,
                height: 46,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: PusulaRenk.lacivert, width: 1.5),
                ),
                child: ProfilAvatar(boyut: 40, foto: avatarFoto, ad: avatarAd),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: bildirimVar ? 'Bildirimler, yeni var' : 'Bildirimler',
            excludeSemantics: true,
            onTap: onBildirim,
            child: Material(
              color: PusulaRenk.beyaz,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onBildirim,
                child: SizedBox.square(
                  dimension: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(LucideIcons.bell, size: 22, color: PusulaRenk.lacivert),
                      if (bildirimVar)
                        Positioned(
                          top: 8,
                          right: 9,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: PusulaRenk.kirmizi,
                              shape: BoxShape.circle,
                              border: Border.all(color: PusulaRenk.beyaz, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}

class _MaasKarti extends StatelessWidget {
  const _MaasKarti({required this.veri, this.onTap});

  final AnaSayfaVerisi veri;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hareketsiz = MediaQuery.disableAnimationsOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Material(
        color: PusulaRenk.mavi,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 176,
            child: Stack(
              children: [
                const Positioned(
                  right: -70,
                  top: -80,
                  child: Opacity(opacity: 0.55, child: PusulaUcgenler(boyut: 230, orta: PusulaRenk.lacivert)),
                ),
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: hareketsiz ? 1 : 0, end: 1),
                    duration: hareketsiz ? Duration.zero : const Duration(milliseconds: 1800),
                    builder: (context, t, _) {
                      // İlk %22 bekleme (girişle uyum), sonra sayı ve çizgi akar.
                      final p = Curves.easeOutCubic.transform(((t - 0.22) / 0.78).clamp(0.0, 1.0));
                      return Stack(
                        children: [
                          if (veri.egri != null)
                            Positioned.fill(
                              child: CustomPaint(painter: _EgriRessami(veri.egri!, p)),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(children: [
                                      const Icon(LucideIcons.wallet, size: 18, color: Color(0xFFDCE3FF)),
                                      const SizedBox(width: 8),
                                      Text('Tahmini net maaşın',
                                          style: PusulaYazi.metin(13, renk: const Color(0xFFDCE3FF))),
                                    ]),
                                    if (veri.ornek)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: PusulaRenk.lacivert,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text('ÖRNEK HESAP',
                                            style:
                                                PusulaYazi.metin(11, renk: PusulaRenk.amber, agirlik: FontWeight.w700)
                                                    .copyWith(letterSpacing: 0.4)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (veri.netMaas != null)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          liraTam(veri.netMaas! * p),
                                          maxLines: 1,
                                          style: PusulaYazi.baslik(44, renk: PusulaRenk.beyaz, aralik: -2)
                                              .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                                        ),
                                      ),
                                      if (veri.zamFarki != null) ...[
                                        const SizedBox(width: 10),
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Container(
                                            padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
                                            decoration: BoxDecoration(
                                              color: PusulaRenk.amber,
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                                              const Icon(LucideIcons.trendingUp, size: 14, color: PusulaRenk.lacivert),
                                              const SizedBox(width: 4),
                                              Text('+${liraTam(veri.zamFarki!)} zam',
                                                  style: PusulaYazi.metin(12, agirlik: FontWeight.w700)),
                                            ]),
                                          ),
                                        ),
                                      ],
                                    ],
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8, right: 8),
                                    child: Text(
                                      veri.maasMesaji ?? 'Maaşını görmek için profilini tamamla.',
                                      style: PusulaYazi.baslik(20, renk: PusulaRenk.beyaz, aralik: -0.6)
                                          .copyWith(height: 1.25),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
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

/// Alt kenardaki maaş eğrisi: dolgulu alan + beyaz çizgi + son noktalardan birinde amber nokta.
class _EgriRessami extends CustomPainter {
  _EgriRessami(this.noktalar, this.ilerleme);

  final List<double> noktalar;
  final double ilerleme;

  @override
  void paint(Canvas canvas, Size size) {
    const yukseklik = 58.0;
    final ust = size.height - yukseklik;
    Offset nokta(int i) => Offset(
          size.width * i / (noktalar.length - 1),
          ust + 6 + (yukseklik - 14) * (1 - noktalar[i]),
        );

    final cizgi = Path()..moveTo(nokta(0).dx, nokta(0).dy);
    for (var i = 1; i < noktalar.length; i++) {
      cizgi.lineTo(nokta(i).dx, nokta(i).dy);
    }
    final alan = Path.from(cizgi)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(alan, Paint()..color = PusulaRenk.beyaz.withValues(alpha: 0.14 * ilerleme));

    final boya = Paint()
      ..color = PusulaRenk.beyaz
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final m in cizgi.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * ilerleme), boya);
    }

    if (ilerleme >= 1) {
      final son = nokta(noktalar.length - 2);
      canvas.drawCircle(son, 6, Paint()..color = PusulaRenk.amber);
      canvas.drawCircle(
        son,
        6,
        Paint()
          ..color = PusulaRenk.mavi
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(_EgriRessami eski) => eski.ilerleme != ilerleme || eski.noktalar != noktalar;
}

class _YolHaritasi extends StatelessWidget {
  const _YolHaritasi({required this.ogeler});

  final List<YolHaritasiOgesi> ogeler;

  static const _ikonlar = [LucideIcons.calendarClock, LucideIcons.award, LucideIcons.flag];

  @override
  Widget build(BuildContext context) => PusulaKart(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            for (var i = 0; i < ogeler.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              _YolSatiri(oge: ogeler[i], ikon: _ikonlar[i % _ikonlar.length]),
            ],
          ],
        ),
      );
}

class _YolSatiri extends StatelessWidget {
  const _YolSatiri({required this.oge, required this.ikon});

  final YolHaritasiOgesi oge;
  final IconData ikon;

  @override
  Widget build(BuildContext context) {
    final hareketsiz = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: '${oge.baslik}: ${oge.deger}',
      excludeSemantics: true,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: oge.renk, borderRadius: BorderRadius.circular(14)),
            child: Icon(ikon, size: 22, color: oge.ikonRengi),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(oge.baslik, style: PusulaYazi.metin(14, agirlik: FontWeight.w700)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: hareketsiz ? oge.oran : 0, end: oge.oran),
                    duration: hareketsiz ? Duration.zero : const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 5,
                      backgroundColor: PusulaRenk.cizgi,
                      color: oge.renk,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(oge.deger, style: PusulaYazi.baslik(16, aralik: -0.5)),
        ],
      ),
    );
  }
}

class _Kisayol extends StatelessWidget {
  const _Kisayol({
    required this.renk,
    required this.on,
    required this.ikonRengi,
    required this.ikon,
    required this.baslik,
    required this.alt,
    this.onTap,
  });

  final Color renk;
  final Color on;
  final Color ikonRengi;
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
            height: 116,
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
                    child: Icon(ikon, size: 22, color: ikonRengi),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(baslik, style: PusulaYazi.baslik(16, renk: on, aralik: -0.5)),
                      Text(alt, style: PusulaYazi.metin(12, renk: on)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
