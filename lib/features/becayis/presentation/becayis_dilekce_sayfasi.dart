import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/bilesenler.dart';
import '../../../core/metin.dart';
import '../../../core/tema.dart';
import '../../../core/yukselen.dart';
import '../data/becayis_deposu.dart';
import '../domain/eslesme.dart';
import '../domain/ilan.dart';
import '../domain/kisi_bilgisi.dart';

/// Taraf bilgileriyle otomatik doldurulan dilekçe önizlemesi.
///
/// Şablon metin hukuki gözden geçirmeden sonra sabitlenmelidir
/// (bkz. docs/becayis-spec.md §7). PDF üretimi arka uç/paket bağlanınca eklenir.
class BecayisDilekceSayfasi extends StatefulWidget {
  const BecayisDilekceSayfasi({
    super.key,
    required this.depo,
    required this.eslesme,
    this.bugun,
  });

  final BecayisDeposu depo;
  final Eslesme eslesme;

  /// Testlerde sabit tarih vermek için; boşsa bugünün tarihi.
  final DateTime? bugun;

  @override
  State<BecayisDilekceSayfasi> createState() => _BecayisDilekceSayfasiState();
}

class _BecayisDilekceSayfasiState extends State<BecayisDilekceSayfasi> {
  bool _indirildi = false;

  static String _tarih(DateTime t) =>
      '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';

  @override
  Widget build(BuildContext context) {
    final benim = widget.depo.benim;
    final ben = widget.depo.kisi(benim.id);
    final digerler = widget.eslesme.ilanlar.where((i) => i.id != benim.id).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
          children: [
            const Yukselen(
              child: GeriBaslik(ustYazi: '657 sayılı Kanun · Madde 73', baslik: 'Dilekçe'),
            ),
            const SizedBox(height: 14),
            const Yukselen(
              gecikme: Duration(milliseconds: 80),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Hap(
                  'Sarı alanlar otomatik dolduruldu',
                  zemin: Color(0xFFFFF1D6),
                  yazi: PusulaRenk.lacivert,
                  ikon: LucideIcons.badgeCheck,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Yukselen(
              gecikme: const Duration(milliseconds: 140),
              child: _Kagit(
                benim: benim,
                ben: ben,
                digerler: digerler,
                kisiler: [for (final d in digerler) widget.depo.kisi(d.id)],
                zincir: widget.eslesme.tip == EslesmeTipi.zincir,
                tarih: _tarih(widget.bugun ?? DateTime.now()),
              ),
            ),
            const SizedBox(height: 14),
            Yukselen(
              gecikme: const Duration(milliseconds: 220),
              child: Row(
                children: [
                  Expanded(
                    child: BirincilDugme(
                      yukseklik: 56,
                      metin: _indirildi ? 'İndirildi' : 'PDF indir',
                      ikon: _indirildi ? LucideIcons.check : LucideIcons.download,
                      zemin: _indirildi ? PusulaRenk.yesilZemin : PusulaRenk.amber,
                      yazi: _indirildi ? PusulaRenk.yesilYazi : PusulaRenk.lacivert,
                      onPressed: () => setState(() => _indirildi = true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.maybePop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PusulaRenk.lacivert,
                        backgroundColor: PusulaRenk.beyaz,
                        side: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: Text('Eşleşme', style: PusulaYazi.metin(15, agirlik: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(LucideIcons.info, size: 18, color: PusulaRenk.soluk),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'İki taraf da dilekçesini aynı gün, disiplin amiri kanalıyla atamaya yetkili amire verir. '
                    'Yer değişikliği o amirin uygun bulmasına bağlıdır; Pusula resmî işlem yapmaz. '
                    'Bu metin örnek taslaktır.',
                    style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)
                        .copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Kagit extends StatelessWidget {
  const _Kagit({
    required this.benim,
    required this.ben,
    required this.digerler,
    required this.kisiler,
    required this.zincir,
    required this.tarih,
  });

  final Ilan benim;
  final KisiBilgisi? ben;
  final List<Ilan> digerler;
  final List<KisiBilgisi?> kisiler;
  final bool zincir;
  final String tarih;

  static const _dolu = TextStyle(backgroundColor: Color(0xFFFFF1D6), fontWeight: FontWeight.w700);

  /// Otomatik doldurulan alan: sarı zemin, kalın.
  TextSpan _d(String s) => TextSpan(text: s, style: _dolu);

  @override
  Widget build(BuildContext context) {
    final govde = PusulaYazi.metin(13, agirlik: FontWeight.w500).copyWith(height: 1.55);
    final adim = ben?.tamAd ?? benim.gorunenAd;

    final ilkParagraf = Text.rich(TextSpan(style: govde, children: [
      const TextSpan(text: 'Bakanlığınız '),
      _d(benim.mevcutIl),
      const TextSpan(text: ' ilinde '),
      _d(benim.unvan),
      const TextSpan(text: ' unvanıyla görev yapmaktayım.'),
    ]));

    final ikinciParagraf = Text.rich(TextSpan(style: govde, children: [
      const TextSpan(text: "657 sayılı Devlet Memurları Kanunu'nun 73. maddesi uyarınca, "),
      if (!zincir) ...[
        _d(digerler.first.mevcutIl),
        const TextSpan(text: ' ilinde aynı kurum ve sınıfta görev yapan '),
        _d(kisiler.first?.tamAd ?? digerler.first.gorunenAd),
        const TextSpan(text: ' (Sicil No: '),
        _d(kisiler.first?.sicilNo ?? '—'),
        const TextSpan(text: ') ile karşılıklı olarak anlaşarak yer değiştirmek (becayiş) istiyorum.'),
      ] else ...[
        const TextSpan(text: 'aynı kurum ve sınıfta görev yapan '),
        for (var k = 0; k < digerler.length; k++) ...[
          _d(kisiler[k]?.tamAd ?? digerler[k].gorunenAd),
          TextSpan(text: ' (${digerler[k].mevcutIl}, Sicil No: '),
          _d(kisiler[k]?.sicilNo ?? '—'),
          TextSpan(text: k < digerler.length - 1 ? '), ' : ') '),
        ],
        const TextSpan(text: 'ile üç kişilik karşılıklı yer değiştirme yapmak istiyoruz. Ben '),
        _d(digerler.first.mevcutIl),
        const TextSpan(text: ' iline atanmayı talep ediyorum.'),
      ],
    ]));

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: PusulaRenk.beyaz,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PusulaRenk.cizgi),
        boxShadow: [
          BoxShadow(
            color: PusulaRenk.lacivert.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text.rich(TextSpan(style: govde, children: [_d(tarih)])),
          ),
          const SizedBox(height: 12),
          Text(
            '${buyukHarf(benim.kurumAdi)} MAKAMINA',
            textAlign: TextAlign.center,
            style: PusulaYazi.metin(13, agirlik: FontWeight.w700).copyWith(letterSpacing: 0.3),
          ),
          const SizedBox(height: 12),
          ilkParagraf,
          const SizedBox(height: 12),
          ikinciParagraf,
          const SizedBox(height: 12),
          Text('Gereğini bilgilerinize arz ederim.', style: govde),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(TextSpan(style: govde, children: [_d(adim)])),
                Text.rich(
                  TextSpan(
                    style: PusulaYazi.metin(12, renk: PusulaRenk.soluk),
                    children: [
                      TextSpan(text: '${benim.unvan} · Sicil No: '),
                      _d(ben?.sicilNo ?? '—'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(width: 120, height: 1.5, color: PusulaRenk.lacivert),
                Text('İmza', style: PusulaYazi.metin(11, renk: PusulaRenk.soluk)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
