import 'package:flutter/material.dart';

import '../../../core/bilesenler.dart';
import '../../../core/metin.dart';
import '../../../core/tema.dart';
import '../../../core/yukselen.dart';
import '../../maas/domain/gosterge_tablosu.dart';
import '../../maas/domain/maas_parametreleri.dart';
import '../domain/derece_tablosu.dart';
import 'arac_parcalari.dart';

/// Derece ve kademeye göre gösterge ve temel aylık tablosu (657 md. 154 gösterge cetveli).
class DereceTablosuSayfasi extends StatefulWidget {
  const DereceTablosuSayfasi({super.key, this.derece = 8, this.kademe});

  /// Açılışta seçili derece ve (varsa) vurgulanacak kademe.
  final int derece;
  final int? kademe;

  @override
  State<DereceTablosuSayfasi> createState() => _DereceTablosuSayfasiState();
}

class _DereceTablosuSayfasiState extends State<DereceTablosuSayfasi> {
  late int _derece = widget.derece.clamp(1, GostergeTablosu.enUstDerece);

  @override
  Widget build(BuildContext context) {
    final satirlar = DereceTablosu.satirlar(_derece);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
          children: [
            const Yukselen(child: GeriBaslik(ustYazi: 'Araçlar', baslik: 'Derece tablosu', sag: SizedBox.shrink())),
            const SizedBox(height: 16),
            Text('Derece', style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w700)),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: GostergeTablosu.enUstDerece,
                separatorBuilder: (context, i) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final d = i + 1;
                  final secili = d == _derece;
                  return Semantics(
                    button: true,
                    selected: secili,
                    label: 'Derece $d',
                    excludeSemantics: true,
                    onTap: () => setState(() => _derece = d),
                    child: Material(
                      color: secili ? PusulaRenk.amber : PusulaRenk.beyaz,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _derece = d),
                        child: SizedBox.square(
                          dimension: 44,
                          child: Center(
                              child: Text('$d', style: PusulaYazi.baslik(14, aralik: 0, agirlik: FontWeight.w700))),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            PusulaKart(
              radius: 24,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Column(
                children: [
                  const _Baslik(),
                  const Divider(color: PusulaRenk.cizgi, height: 14),
                  for (final s in satirlar)
                    _Satir(
                      satir: s,
                      vurgulu: widget.kademe != null && widget.derece == _derece && widget.kademe == s.kademe,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            NotSatiri(
              'Katsayılar: ${MaasParametreleri.temmuzAralik2026.donem} '
              '(aylık katsayı ${MaasParametreleri.temmuzAralik2026.aylikKatsayi}). '
              '"Temel aylık" = gösterge aylığı + taban aylık (brüt). Ek gösterge, kıdem aylığı, yan ödeme, '
              'özel hizmet tazminatı ve diğer kalemler dahil değildir; kendi maaşın için Maaş sekmesini kullan.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Baslik extends StatelessWidget {
  const _Baslik();

  @override
  Widget build(BuildContext context) {
    final st = PusulaYazi.metin(11, renk: PusulaRenk.soluk, agirlik: FontWeight.w700);
    return Row(
      children: [
        SizedBox(width: 44, child: Text('Kademe', style: st)),
        Expanded(child: Text('Gösterge', textAlign: TextAlign.end, style: st)),
        Expanded(flex: 2, child: Text('Temel aylık (brüt)', textAlign: TextAlign.end, style: st)),
      ],
    );
  }
}

class _Satir extends StatelessWidget {
  const _Satir({required this.satir, required this.vurgulu});

  final DereceSatiri satir;
  final bool vurgulu;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: 'Derece ${satir.derece}, kademe ${satir.kademe}: gösterge ${satir.gosterge}, '
            'temel aylık ${binlik(satir.temelAylik.round())} lira${vurgulu ? ', senin kademen' : ''}',
        excludeSemantics: true,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
          decoration: BoxDecoration(
            color: vurgulu ? PusulaRenk.amber.withValues(alpha: 0.35) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(width: 44, child: Text('${satir.kademe}', style: PusulaYazi.baslik(15, aralik: 0))),
              Expanded(
                child: Text('${satir.gosterge}',
                    textAlign: TextAlign.end, style: PusulaYazi.metin(14, agirlik: FontWeight.w600)),
              ),
              Expanded(
                flex: 2,
                child: Text(liraTam(satir.temelAylik.round()),
                    textAlign: TextAlign.end, style: PusulaYazi.metin(14, agirlik: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
}
