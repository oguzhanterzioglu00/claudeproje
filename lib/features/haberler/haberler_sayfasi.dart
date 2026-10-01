import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/baglanti.dart';
import '../../core/bilesenler.dart';
import '../../core/bos_durum.dart';
import '../../core/iskelet.dart';
import '../../core/tema.dart';
import '../../core/yukselen.dart';
import 'haber_kapagi.dart';
import 'haber_kaynagi.dart';
import 'haber_modeli.dart';

/// Haber ayrıntısını alt sayfada açar; ana sayfadaki bölüm ve tam liste ortak kullanır.
Future<void> haberAyrintisiAc(
  BuildContext context,
  Haber haber, {
  DateTime? bugun,
  ValueChanged<Haber>? kaynagiAc,
}) =>
    AltSayfa.goster<void>(
      context,
      builder: (c) => _Ayrinti(haber: haber, bugun: bugun ?? DateTime.now(), kaynagiAc: kaynagiAc),
    );

/// Kamu çalışanlarına yönelik haberler: tür süzgeci, kaynak ve zaman bilgisiyle.
class HaberlerSayfasi extends StatefulWidget {
  const HaberlerSayfasi({
    super.key,
    this.kaynak = const OrnekHaberKaynagi(),
    this.bugun,
    this.kaynagiAc,
  });

  final HaberKaynagi kaynak;

  /// Testlerde sabit tarih vermek için; boşsa bugün.
  final DateTime? bugun;

  /// "Kaynağı aç" düğmesi; gerçek sürümde tarayıcıda resmî sayfa açılır.
  final ValueChanged<Haber>? kaynagiAc;

  @override
  State<HaberlerSayfasi> createState() => _HaberlerSayfasiState();
}

class _HaberlerSayfasiState extends State<HaberlerSayfasi> {
  late Future<List<Haber>> _haberler = widget.kaynak.getir();
  HaberTuru? _tur;

  DateTime get _bugun => widget.bugun ?? DateTime.now();

  void _yenile() {
    setState(() {
      _haberler = widget.kaynak.getir();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: FutureBuilder<List<Haber>>(
            future: _haberler,
            builder: (context, snap) {
              final yukleniyor = snap.connectionState != ConnectionState.done;
              final liste = snap.hasData
                  ? snap.data!.where((h) => _tur == null || h.tur == _tur).toList()
                  : const <Haber>[];

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
                children: [
                  Yukselen(
                    child: GeriBaslik(
                      ustYazi: 'Kamu çalışanları için',
                      baslik: 'Gündem',
                      sag: widget.kaynak is OrnekHaberKaynagi ? const OrnekRozeti() : const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Yukselen(
                    gecikme: const Duration(milliseconds: 80),
                    child: SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _Suzgec(etiket: 'Tümü', secili: _tur == null, onTap: () => setState(() => _tur = null)),
                          for (final t in HaberTuru.values) ...[
                            const SizedBox(width: 8),
                            _Suzgec(etiket: t.etiket, secili: _tur == t, onTap: () => setState(() => _tur = t)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (yukleniyor)
                    const IskeletListe()
                  else if (snap.hasError)
                    BosDurum(
                      gorsel: BosGorselTuru.baglanti,
                      baslik: 'Haberler yüklenemedi',
                      alt: 'Bağlantını kontrol edip tekrar dene.',
                      dugme: 'Tekrar dene',
                      onDugme: _yenile,
                    )
                  else if (liste.isEmpty)
                    const BosDurum(
                      gorsel: BosGorselTuru.haber,
                      baslik: 'Haber bulunamadı',
                      alt: 'Başka bir türü seçmeyi dene.',
                    )
                  else
                    for (var k = 0; k < liste.length; k++) ...[
                      Yukselen(
                        gecikme: Duration(milliseconds: 140 + k * 70),
                        child: HaberKarti(
                          haber: liste[k],
                          bugun: _bugun,
                          onTap: () => haberAyrintisiAc(
                            context,
                            liste[k],
                            bugun: _bugun,
                            kaynagiAc: widget.kaynagiAc,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                ],
              );
            },
          ),
        ),
      );
}

class _Suzgec extends StatelessWidget {
  const _Suzgec({required this.etiket, required this.secili, required this.onTap});

  final String etiket;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: secili,
        child: Material(
          color: secili ? PusulaRenk.lacivert : PusulaRenk.beyaz,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: Text(
                  etiket,
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
}

/// Tek bir haber satırı: tür simgesi, başlık, kaynak ve zaman.
class HaberKarti extends StatelessWidget {
  const HaberKarti({super.key, required this.haber, required this.bugun, required this.onTap});

  final Haber haber;
  final DateTime bugun;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PusulaKart(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HaberKucukGorsel(haber: haber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(haber.baslik, style: PusulaYazi.metin(15, agirlik: FontWeight.w700).copyWith(height: 1.25)),
                  const SizedBox(height: 6),
                  Text(
                    '${haber.kaynakAdi} · ${haber.zamanEtiketi(bugun)}',
                    style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
                  ),
                  if (haber.resmiKaynak) ...[
                    const SizedBox(height: 8),
                    const Hap('Resmî kaynak',
                        zemin: PusulaRenk.yesilZemin, yazi: PusulaRenk.yesilYazi, ikon: LucideIcons.badgeCheck, boyut: 11),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class _Ayrinti extends StatelessWidget {
  const _Ayrinti({required this.haber, required this.bugun, this.kaynagiAc});

  final Haber haber;
  final DateTime bugun;
  final ValueChanged<Haber>? kaynagiAc;

  static String _tarih(DateTime t) =>
      '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(height: 168, child: HaberKapagi(haber: haber)),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Hap(haber.tur.etiket, zemin: HaberGorunumu.renk(haber.tur), yazi: HaberGorunumu.ikonRengi(haber.tur), ikon: HaberGorunumu.ikon(haber.tur)),
            const SizedBox(width: 8),
            if (haber.resmiKaynak)
              const Hap('Resmî kaynak',
                  zemin: PusulaRenk.yesilZemin, yazi: PusulaRenk.yesilYazi, ikon: LucideIcons.badgeCheck),
          ]),
          const SizedBox(height: 12),
          Text(haber.baslik, style: PusulaYazi.baslik(22, aralik: -0.9)),
          const SizedBox(height: 6),
          Text('${haber.kaynakAdi} · ${_tarih(haber.yayinTarihi)}',
              style: PusulaYazi.metin(13, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)),
          if (haber.ozet.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: PusulaRenk.zemin, borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (haber.otomatikOzet) ...[
                    Row(children: [
                      const Icon(LucideIcons.sparkles, size: 14, color: PusulaRenk.mor),
                      const SizedBox(width: 6),
                      Text('Otomatik özet',
                          style: PusulaYazi.metin(12, renk: PusulaRenk.mor, agirlik: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 6),
                  ],
                  Text(haber.ozet, style: PusulaYazi.metin(14, agirlik: FontWeight.w500).copyWith(height: 1.4)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.info, size: 18, color: PusulaRenk.soluk),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  haber.otomatikOzet
                      ? 'Bu özet otomatik üretildi ve hata içerebilir; kesin bilgi için kaynağa bak.'
                      : 'Haberler otomatik derlenir; işlem yapmadan önce kaynağı doğrula.',
                  style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500).copyWith(height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          BirincilDugme(
            yukseklik: 56,
            metin: 'Kaynağı aç',
            ikon: LucideIcons.externalLink,
            // Bağlantısı olmayan haberde düğme pasif; olanda tarayıcıda açılır (testte [kaynagiAc]).
            onPressed: haber.baglanti == null
                ? null
                : () => kaynagiAc != null ? kaynagiAc!(haber) : baglantiAc(context, haber.baglanti),
          ),
        ],
      );
}
