import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/bilesenler.dart';
import '../../../core/metin.dart';
import '../../../core/tema.dart';
import '../../../core/ucgenler.dart';
import '../../../core/yukselen.dart';
import '../data/becayis_deposu.dart';
import '../domain/eslesme.dart';
import '../domain/ilan.dart';
import '../domain/kisi_bilgisi.dart';

/// Bir eşleşmenin ayrıntısı: skor, takas, ikili/3'lü zincir geçişi,
/// karşılıklı onay, uygulama içi ödeme ve iletişim bilgisi.
class BecayisEslesmeSayfasi extends StatefulWidget {
  const BecayisEslesmeSayfasi({
    super.key,
    required this.depo,
    required this.ilkEslesme,
    this.dilekceAc,
  });

  final BecayisDeposu depo;
  final Eslesme ilkEslesme;
  final ValueChanged<Eslesme>? dilekceAc;

  @override
  State<BecayisEslesmeSayfasi> createState() => _BecayisEslesmeSayfasiState();
}

class _BecayisEslesmeSayfasiState extends State<BecayisEslesmeSayfasi> {
  late bool _zincirMod = widget.ilkEslesme.tip == EslesmeTipi.zincir;

  Eslesme? _secili(List<Eslesme> hepsi) {
    final tip = _zincirMod ? EslesmeTipi.zincir : EslesmeTipi.ikili;
    final adaylar = hepsi.where((e) => e.tip == tip).toList();
    if (adaylar.isEmpty) return null;
    return adaylar.firstWhere((e) => e.id == widget.ilkEslesme.id, orElse: () => adaylar.first);
  }

  /// Çevrimi "ben" başa gelecek şekilde döndürür.
  List<Ilan> _benBasta(Eslesme e) {
    final k = e.ilanlar.indexWhere((i) => i.id == widget.depo.benim.id);
    if (k <= 0) return e.ilanlar;
    return [...e.ilanlar.sublist(k), ...e.ilanlar.sublist(0, k)];
  }

  Future<void> _odemeAc(Eslesme e) => AltSayfa.goster<void>(
        context,
        builder: (c) => _OdemeSayfasi(depo: widget.depo, eslesme: e),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.depo,
        builder: (context, _) {
          final hepsi = widget.depo.eslesmeler;
          final ikiModVar = hepsi.any((e) => e.tip == EslesmeTipi.ikili) &&
              hepsi.any((e) => e.tip == EslesmeTipi.zincir);
          final e = _secili(hepsi) ?? widget.ilkEslesme;
          final benim = widget.depo.benim;
          final sirali = _benBasta(e);
          final digerler = sirali.where((i) => i.id != benim.id).toList();

          return Scaffold(
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
                children: [
                  Yukselen(
                    child: GeriBaslik(
                      ustYazi: '${benim.kurumAdi} · ${benim.unvan}',
                      baslik: 'Eşleşme',
                    ),
                  ),
                  if (ikiModVar) ...[
                    const SizedBox(height: 14),
                    Yukselen(
                      gecikme: const Duration(milliseconds: 80),
                      child: _ModSecici(
                        zincir: _zincirMod,
                        onDegis: (z) => setState(() => _zincirMod = z),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Yukselen(gecikme: const Duration(milliseconds: 140), child: _SkorKarti(eslesme: e)),
                  const SizedBox(height: 14),
                  Yukselen(
                    gecikme: const Duration(milliseconds: 200),
                    child: e.tip == EslesmeTipi.ikili
                        ? _IkiliTakas(ben: benim, diger: digerler.first)
                        : _ZincirTakas(sirali: sirali, benimId: benim.id),
                  ),
                  if (e.tip == EslesmeTipi.zincir) ...[
                    const SizedBox(height: 10),
                    const _UyariSatiri(
                      "3'lü zincir 657 sayılı Kanun md. 73'te açıkça geçmez; kurum uygun bulmayabilir.",
                    ),
                  ],
                  for (final u in e.uyarilar) ...[
                    const SizedBox(height: 10),
                    _UyariSatiri(u),
                  ],
                  const SizedBox(height: 14),
                  Yukselen(
                    gecikme: const Duration(milliseconds: 260),
                    child: _IletisimKarti(
                      depo: widget.depo,
                      eslesme: e,
                      digerler: digerler,
                      onOdeme: () => _odemeAc(e),
                      onDilekce: widget.dilekceAc == null ? null : () => widget.dilekceAc!(e),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _ModSecici extends StatelessWidget {
  const _ModSecici({required this.zincir, required this.onDegis});

  final bool zincir;
  final ValueChanged<bool> onDegis;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: PusulaRenk.cizgi, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Expanded(child: _Sekme('İkili', !zincir, () => onDegis(false))),
            const SizedBox(width: 4),
            Expanded(child: _Sekme("3'lü zincir", zincir, () => onDegis(true))),
          ],
        ),
      );
}

class _Sekme extends StatelessWidget {
  const _Sekme(this.etiket, this.secili, this.onTap);

  final String etiket;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: secili,
        child: Material(
          color: secili ? PusulaRenk.lacivert : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: SizedBox(
              height: 44,
              child: Center(
                child: Text(
                  etiket,
                  style: PusulaYazi.metin(
                    14,
                    renk: secili ? PusulaRenk.beyaz : PusulaRenk.lacivert,
                    agirlik: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _SkorKarti extends StatelessWidget {
  const _SkorKarti({required this.eslesme});

  final Eslesme eslesme;

  static const _acikYazi = Color(0xFFC9D0E0);

  @override
  Widget build(BuildContext context) {
    final ikili = eslesme.tip == EslesmeTipi.ikili;
    final skor = eslesme.skor;
    final etiket = skor >= 90 ? 'Çok yüksek' : skor >= 75 ? 'Yüksek' : 'İyi';
    final farkliUnvan = eslesme.uyarilar.isNotEmpty;
    final kriterler = ikili
        ? ['Kurum eşleşti', 'Sınıf eşleşti', farkliUnvan ? 'Unvan farklı' : 'Unvan aynı']
        : ['3 kişi', 'Kurum ve sınıf aynı', 'İller karşılıklı'];

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Container(
        color: PusulaRenk.lacivert,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Stack(
          children: [
            const Positioned(
              right: -80,
              top: -90,
              child: Opacity(opacity: 0.4, child: PusulaUcgenler(boyut: 200, orta: PusulaRenk.mavi)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SkorHalkasi(
                      skor: skor,
                      boyut: 96,
                      kalinlik: 9,
                      yaziBoyutu: 28,
                      iz: const Color(0xFF2B3A6E),
                      yaziRengi: PusulaRenk.beyaz,
                      yuzdeIsareti: true,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('UYUM SKORU',
                              style: PusulaYazi.metin(11, renk: _acikYazi, agirlik: FontWeight.w700)
                                  .copyWith(letterSpacing: 0.6)),
                          Text(etiket,
                              style: PusulaYazi.baslik(22, renk: PusulaRenk.beyaz, aralik: -0.8)),
                          Text(ikili ? 'Kriterler tutuyor' : 'Zincir kapanıyor',
                              style: PusulaYazi.metin(13, renk: _acikYazi, agirlik: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final k in kriterler)
                      Container(
                        padding: const EdgeInsets.fromLTRB(8, 5, 11, 5),
                        decoration: BoxDecoration(
                          color: PusulaRenk.beyaz.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.check, size: 14, color: PusulaRenk.amber),
                            const SizedBox(width: 5),
                            Text(k, style: PusulaYazi.metin(12, renk: PusulaRenk.beyaz, agirlik: FontWeight.w700)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Takastaki bir kişi: yuvarlak simge, ad ve alt yazı.
class _Dugum extends StatelessWidget {
  const _Dugum({
    required this.zemin,
    required this.yazi,
    required this.ad,
    required this.alt,
    this.tik = false,
  });

  final Color zemin;
  final Color yazi;
  final String ad;
  final String alt;
  final bool tik;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 84,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(color: zemin, shape: BoxShape.circle),
                  child: Icon(LucideIcons.user, size: 26, color: yazi),
                ),
                if (tik)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(color: PusulaRenk.beyaz, shape: BoxShape.circle),
                      child: const Icon(LucideIcons.badgeCheck, size: 16, color: PusulaRenk.mavi),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(ad,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PusulaYazi.metin(14, agirlik: FontWeight.w700)),
            Text(alt,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PusulaYazi.metin(12, renk: PusulaRenk.soluk)),
          ],
        ),
      );
}

class _IkiliTakas extends StatelessWidget {
  const _IkiliTakas({required this.ben, required this.diger});

  final Ilan ben;
  final Ilan diger;

  @override
  Widget build(BuildContext context) => PusulaKart(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Dugum(zemin: PusulaRenk.amber, yazi: PusulaRenk.lacivert, ad: 'Sen', alt: ben.mevcutIl),
            Expanded(
              child: SizedBox(
                height: 54,
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    const Expanded(child: _Kesik(renk: PusulaRenk.turkuaz)),
                    Container(
                      width: 38,
                      height: 38,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: const BoxDecoration(color: PusulaRenk.lacivert, shape: BoxShape.circle),
                      child: const Icon(LucideIcons.arrowRightLeft, size: 20, color: PusulaRenk.amber),
                    ),
                    const Expanded(child: _Kesik(renk: PusulaRenk.turkuaz)),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
            _Dugum(
              zemin: PusulaRenk.turkuaz,
              yazi: PusulaRenk.lacivert,
              ad: diger.gorunenAd,
              alt: diger.mevcutIl,
              tik: diger.maviTik,
            ),
          ],
        ),
      );
}

class _ZincirTakas extends StatelessWidget {
  const _ZincirTakas({required this.sirali, required this.benimId});

  final List<Ilan> sirali;
  final String benimId;

  static const _renkler = [
    (PusulaRenk.amber, PusulaRenk.lacivert),
    (PusulaRenk.turkuaz, PusulaRenk.lacivert),
    (PusulaRenk.mor, PusulaRenk.beyaz),
  ];

  @override
  Widget build(BuildContext context) {
    final oklar = <Widget>[];
    for (var k = 0; k < sirali.length; k++) {
      final ilan = sirali[k];
      final sonraki = sirali[(k + 1) % sirali.length];
      final (zemin, yazi) = _renkler[k % _renkler.length];
      oklar.add(_Dugum(
        zemin: zemin,
        yazi: yazi,
        ad: ilan.id == benimId ? 'Sen' : ilan.gorunenAd,
        alt: '→ ${sonraki.mevcutIl}',
        tik: ilan.id != benimId && ilan.maviTik,
      ));
      if (k < sirali.length - 1) {
        oklar.add(const Padding(
          padding: EdgeInsets.only(top: 15),
          child: Icon(LucideIcons.chevronRight, size: 24, color: PusulaRenk.mor),
        ));
      }
    }
    return PusulaKart(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: oklar,
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 42),
            child: SizedBox(height: 18, width: double.infinity, child: _Kesik(renk: PusulaRenk.mor, kose: true)),
          ),
          const SizedBox(height: 6),
          Text('Zincir kapanıyor: herkes istediği ile ulaşıyor',
              textAlign: TextAlign.center,
              style: PusulaYazi.metin(12, renk: PusulaRenk.mor, agirlik: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Kesik çizgi; [kose] true ise alt köşeli "U" yolu çizer.
class _Kesik extends StatelessWidget {
  const _Kesik({required this.renk, this.kose = false});

  final Color renk;
  final bool kose;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _KesikYol(renk: renk, kose: kose),
        child: kose ? null : const SizedBox(height: 3, width: double.infinity),
      );
}

class _KesikYol extends CustomPainter {
  _KesikYol({required this.renk, required this.kose});

  final Color renk;
  final bool kose;

  @override
  void paint(Canvas canvas, Size size) {
    final yol = Path();
    if (kose) {
      yol
        ..moveTo(1.25, 0)
        ..lineTo(1.25, size.height - 1.25)
        ..lineTo(size.width - 1.25, size.height - 1.25)
        ..lineTo(size.width - 1.25, 0);
    } else {
      yol
        ..moveTo(0, size.height / 2)
        ..lineTo(size.width, size.height / 2);
    }
    final boya = Paint()
      ..color = renk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (final m in yol.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 11) {
        canvas.drawPath(m.extractPath(d, (d + 6).clamp(0, m.length).toDouble()), boya);
      }
    }
  }

  @override
  bool shouldRepaint(_KesikYol eski) => eski.renk != renk || eski.kose != kose;
}

class _UyariSatiri extends StatelessWidget {
  const _UyariSatiri(this.metin);

  final String metin;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1D6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(LucideIcons.info, size: 18, color: PusulaRenk.lacivert),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(metin, style: PusulaYazi.metin(13, agirlik: FontWeight.w600))),
          ],
        ),
      );
}

class _IletisimKarti extends StatelessWidget {
  const _IletisimKarti({
    required this.depo,
    required this.eslesme,
    required this.digerler,
    required this.onOdeme,
    required this.onDilekce,
  });

  final BecayisDeposu depo;
  final Eslesme eslesme;
  final List<Ilan> digerler;
  final VoidCallback onOdeme;
  final VoidCallback? onDilekce;

  static const _renkler = [
    (PusulaRenk.turkuaz, PusulaRenk.lacivert),
    (PusulaRenk.mor, PusulaRenk.beyaz),
  ];

  @override
  Widget build(BuildContext context) {
    final acik = depo.iletisimAcik;
    final onayladim = depo.onayladim(eslesme);
    final hazir = depo.hazir(eslesme);
    final adlar = digerler.map((i) => i.gorunenAd).join(' ve ');
    final karsi = depo.karsiOnayladi(eslesme);

    return PusulaKart(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('İletişim bilgisi', style: PusulaYazi.baslik(17, agirlik: FontWeight.w700, aralik: -0.4)),
              Hap(
                acik ? 'Açık' : 'Kilitli',
                zemin: acik ? PusulaRenk.yesilZemin : PusulaRenk.cizgi,
                yazi: acik ? PusulaRenk.yesilYazi : PusulaRenk.lacivert,
                ikon: acik ? LucideIcons.lockOpen : LucideIcons.lock,
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var k = 0; k < digerler.length; k++)
            _KisiSatiri(
              ilan: digerler[k],
              kisi: depo.kisi(digerler[k].id),
              renk: _renkler[k % _renkler.length],
            ),
          const SizedBox(height: 10),
          if (!acik) ...[
            if (karsi)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: PusulaRenk.yesilZemin,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.check, size: 16, color: PusulaRenk.yesilYazi),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        digerler.length == 1 ? '$adlar de ilgileniyor' : '$adlar ilgileniyor',
                        style: PusulaYazi.metin(13, renk: PusulaRenk.yesilYazi, agirlik: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            if (!onayladim)
              BirincilDugme(
                metin: 'İlgileniyorum',
                ikon: LucideIcons.check,
                zemin: PusulaRenk.lacivert,
                yazi: PusulaRenk.beyaz,
                onPressed: () => depo.ilgileniyorum(eslesme),
              )
            else
              BirincilDugme(
                metin: 'İletişimi aç · ${lira(depo.fiyat)}',
                ikon: LucideIcons.lockOpen,
                onPressed: hazir ? onOdeme : null,
              ),
            const SizedBox(height: 8),
            Text(
              onayladim
                  ? 'İkiniz de onayladınız. Tek seferlik ödeme, abonelik yok.'
                  : 'Ödeme, iki taraf da onaylayınca istenir.',
              textAlign: TextAlign.center,
              style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
            ),
          ] else
            BirincilDugme(
              metin: 'Dilekçeni hazırla',
              ikon: LucideIcons.fileText,
              zemin: PusulaRenk.lacivert,
              yazi: PusulaRenk.beyaz,
              onPressed: onDilekce,
            ),
        ],
      ),
    );
  }
}

class _KisiSatiri extends StatelessWidget {
  const _KisiSatiri({required this.ilan, required this.kisi, required this.renk});

  final Ilan ilan;

  /// Ödeme yapılana kadar null; sunucu yetki vermeden bu bilgi gelmez.
  final KisiBilgisi? kisi;
  final (Color, Color) renk;

  @override
  Widget build(BuildContext context) {
    final k = kisi;
    final acik = k != null;
    final ad = k?.tamAd ?? ilan.gorunenAd;
    final tel = k?.telefon ?? '05•• ••• •• ••';
    final mail = k?.eposta ?? '••••••@••••.gov.tr';
    final veri = PusulaYazi.metin(
      13,
      renk: acik ? PusulaRenk.lacivert : PusulaRenk.soluk,
    ).copyWith(letterSpacing: acik ? 0 : 1);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: PusulaRenk.cizgi, width: 1.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: renk.$1, shape: BoxShape.circle),
            child: Text(ad.characters.first, style: PusulaYazi.baslik(17, renk: renk.$2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ad, style: PusulaYazi.metin(15, agirlik: FontWeight.w700)),
                Text('${ilan.unvan} · ${ilan.mevcutIl} → ${ilan.hedefIller.first}',
                    style: PusulaYazi.metin(12, renk: PusulaRenk.soluk)),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(LucideIcons.phone, size: 13, color: PusulaRenk.soluk),
                  const SizedBox(width: 6),
                  Text(tel, style: veri),
                ]),
                Row(children: [
                  const Icon(LucideIcons.mail, size: 13, color: PusulaRenk.soluk),
                  const SizedBox(width: 6),
                  Expanded(child: Text(mail, overflow: TextOverflow.ellipsis, style: veri)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Uygulama içi satın alma onayı (biyometrik). Gerçek sürümde mağaza ödeme
/// ekranı açılır; burada [BecayisDeposu.odemeYap] çağrılır.
class _OdemeSayfasi extends StatefulWidget {
  const _OdemeSayfasi({required this.depo, required this.eslesme});

  final BecayisDeposu depo;
  final Eslesme eslesme;

  @override
  State<_OdemeSayfasi> createState() => _OdemeSayfasiState();
}

class _OdemeSayfasiState extends State<_OdemeSayfasi> {
  bool _bekliyor = false;
  String? _hata;

  Future<void> _ode() async {
    setState(() {
      _bekliyor = true;
      _hata = null;
    });
    final ok = await widget.depo.odemeYap(widget.eslesme);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        _bekliyor = false;
        _hata = 'Ödeme tamamlanamadı. Tekrar dene.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_bekliyor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('İletişimi aç', style: PusulaYazi.baslik(22, aralik: -0.9)),
                Text(lira(widget.depo.fiyat), style: PusulaYazi.baslik(22, aralik: -0.9)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: PusulaRenk.zemin, borderRadius: BorderRadius.circular(20)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Madde('Bu ilandaki tüm eşleşmelerin iletişimi açılır'),
                  SizedBox(height: 9),
                  _Madde('Tek seferlik; abonelik ve yenileme yok'),
                  SizedBox(height: 9),
                  _Madde('Dilekçen otomatik hazırlanır'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.shield, size: 18, color: PusulaRenk.lacivert),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ödeme App Store / Google Play hesabınla yapılır; kart bilgisi uygulamada tutulmaz.',
                    style: PusulaYazi.metin(12, renk: PusulaRenk.soluk),
                  ),
                ),
              ],
            ),
            if (_hata != null) ...[
              const SizedBox(height: 10),
              Text(_hata!, style: PusulaYazi.metin(13, renk: PusulaRenk.kirmizi, agirlik: FontWeight.w700)),
            ],
            const SizedBox(height: 14),
            BirincilDugme(
              yukseklik: 56,
              metin: 'Onayla ve öde',
              ikon: LucideIcons.fingerprintPattern,
              yukleniyor: _bekliyor,
              yukleniyorMetni: 'Ödeme onaylanıyor',
              onPressed: _ode,
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: _bekliyor ? null : () => Navigator.pop(context),
              child: Text('Vazgeç', style: PusulaYazi.metin(14, agirlik: FontWeight.w700)),
            ),
          ],
        ),
      );
}

class _Madde extends StatelessWidget {
  const _Madde(this.metin);

  final String metin;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Icon(LucideIcons.check, size: 18, color: PusulaRenk.yesilYazi),
          const SizedBox(width: 8),
          Expanded(child: Text(metin, style: PusulaYazi.metin(14))),
        ],
      );
}
