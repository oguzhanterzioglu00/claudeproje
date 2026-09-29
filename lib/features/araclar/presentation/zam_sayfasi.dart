import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/bilesenler.dart';
import '../../../core/metin.dart';
import '../../../core/tema.dart';
import '../../../core/yukselen.dart';
import '../../maas/domain/memur_maas_hesaplayici.dart';
import '../domain/zam_senaryosu.dart';
import 'arac_parcalari.dart';

/// "Zam gelirse ne olur?": kullanıcının seçtiği zam oranıyla tahmini net maaş değişimi.
class ZamSayfasi extends StatefulWidget {
  const ZamSayfasi({super.key, required this.girdi, this.profildenMi = false});

  final MaasGirdisi girdi;

  /// Girdi kullanıcının profilindeki bordro bilgisiyse true (ekranda belirtilir).
  final bool profildenMi;

  @override
  State<ZamSayfasi> createState() => _ZamSayfasiState();
}

class _ZamSayfasiState extends State<ZamSayfasi> {
  static const _hazirOranlar = [10, 15, 20, 25, 30, 40];
  double _yuzde = 20;

  @override
  Widget build(BuildContext context) {
    final s = ZamSenaryosu.hesapla(widget.girdi, oran: _yuzde / 100);
    final fark = s.netFark.round();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
          children: [
            const Yukselen(child: GeriBaslik(ustYazi: 'Araçlar', baslik: 'Zam senaryosu', sag: SizedBox.shrink())),
            const SizedBox(height: 16),
            Yukselen(
              gecikme: const Duration(milliseconds: 80),
              child: SonucKarti(
                etiket: 'Tahmini yeni net maaş (Ocak)',
                deger: liraTam(s.yeni.net.round()),
                altYazi: '+${liraTam(fark)} · net %${(s.netYuzde * 100).toStringAsFixed(1)} artış',
                anlamsalEtiket:
                    'Yüzde ${_yuzde.toStringAsFixed(1)} zamla tahmini net maaş ${binlik(s.yeni.net.round())} lira, '
                    'şimdikine göre ${binlik(fark)} lira fazla',
                satirlar: [
                  ('Şimdiki net', liraTam(s.eski.net.round())),
                  ('Yeni brüt', liraTam(s.yeni.brut.round())),
                  ('Brüt artış', '+${liraTam(s.brutFark.round())}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PusulaKart(
              radius: 24,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Zam oranı', style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w700)),
                      Text('%${_yuzde.toStringAsFixed(_yuzde % 1 == 0 ? 0 : 1)}',
                          style: PusulaYazi.baslik(24, aralik: -0.8)),
                    ],
                  ),
                  Slider(
                    value: _yuzde,
                    min: 0,
                    max: 60,
                    divisions: 120,
                    activeColor: PusulaRenk.lacivert,
                    inactiveColor: PusulaRenk.cizgi,
                    thumbColor: PusulaRenk.amber,
                    label: '%${_yuzde.toStringAsFixed(1)}',
                    semanticFormatterCallback: (v) => 'Yüzde ${v.toStringAsFixed(1)} zam',
                    onChanged: (v) => setState(() => _yuzde = v),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final o in _hazirOranlar)
                        Semantics(
                          container: true,
                          button: true,
                          selected: _yuzde == o,
                          label: 'Yüzde $o zam',
                          excludeSemantics: true,
                          onTap: () => setState(() => _yuzde = o.toDouble()),
                          child: Material(
                            color: _yuzde == o ? PusulaRenk.lacivert : PusulaRenk.beyaz,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => setState(() => _yuzde = o.toDouble()),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                child: Text('%$o',
                                    style: PusulaYazi.metin(13,
                                        renk: _yuzde == o ? PusulaRenk.beyaz : PusulaRenk.lacivert,
                                        agirlik: FontWeight.w700)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 16),
            NotSatiri(
              widget.profildenMi
                  ? 'Hesap, profilindeki derece/kademe/hizmet yılı ve bordro bilgilerinle yapıldı.'
                  : 'Profilinde bordro bilgisi yok; örnek bir derece ve kademeyle (8/3, 10 yıl) hesaplandı. '
                      'Maaş sekmesinde bilgilerini girip profiline kaydedersen kendi maaşınla hesaplanır.',
              ikon: LucideIcons.user,
            ),
            const SizedBox(height: 10),
            const NotSatiri(
              'Bu bir tahmindir: gerçek zam oranı toplu sözleşme/kanunla belirlenir. Zam; aylık, taban aylık ve yan '
              'ödeme katsayılarına aynı oranda uygulandı. Vergi dilimleri ve asgari ücret istisnası yıl başında '
              'yeniden belirlenir, burada bugünkü değerler kullanıldı; bu yüzden net artış zam oranından biraz düşük çıkar. '
              'Ocak ayı için (kümülatif vergi etkisi olmadan) hesaplandı.',
            ),
          ],
        ),
      ),
    );
  }
}
