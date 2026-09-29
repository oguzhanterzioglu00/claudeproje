import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/tema.dart';
import '../data/becayis_deposu.dart';
import '../domain/eslesme.dart';
import '../domain/statu.dart';
import 'becayis_dilekce_sayfasi.dart';
import 'becayis_eslesme_sayfasi.dart';
import 'becayis_ilan_ver_sayfasi.dart';
import 'becayis_ilanlar_sayfasi.dart';
import 'becayis_panel_sayfasi.dart';

/// Becayiş sekmesi: panel ve ona bağlı ekranlar. Yalnızca 657 memurlarına
/// açıktır; diğer statülerde nedenini anlatan sayfa gösterilir.
class BecayisSekmesi extends StatelessWidget {
  const BecayisSekmesi({super.key, required this.profil, required this.depo});

  final Profil profil;
  final BecayisDeposu depo;

  Future<T?> _git<T>(BuildContext context, Widget sayfa) =>
      Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => sayfa));

  void _eslesmeAc(BuildContext context, Eslesme e) => _git<void>(
        context,
        BecayisEslesmeSayfasi(
          depo: depo,
          ilkEslesme: e,
          dilekceAc: (e) => _git<void>(context, BecayisDilekceSayfasi(depo: depo, eslesme: e)),
        ),
      );

  void _ilanVer(BuildContext context) => _git<void>(context, BecayisIlanVerSayfasi(depo: depo));

  @override
  Widget build(BuildContext context) {
    final neden = profil.becayisKapaliNedeni;
    if (neden != null) return BecayisKapaliSayfasi(neden: neden);

    return ListenableBuilder(
      listenable: depo,
      builder: (context, _) => Scaffold(
        body: BecayisPanelSayfasi(
          benim: depo.benim,
          eslesmeler: depo.eslesmeler,
          eslesmeAc: (e) => _eslesmeAc(context, e),
          ilanlariGor: () => _git<void>(
            context,
            BecayisIlanlarSayfasi(
              depo: depo,
              eslesmeAc: (e) => _eslesmeAc(context, e),
              ilanVer: () => _ilanVer(context),
            ),
          ),
          ilaniDuzenle: () => _ilanVer(context),
        ),
      ),
    );
  }
}

/// 657 memuru olmayan (veya adaylığı süren) kullanıcılar için açıklama.
class BecayisKapaliSayfasi extends StatelessWidget {
  const BecayisKapaliSayfasi({super.key, required this.neden});

  final String neden;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(color: PusulaRenk.cizgi, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.lock, size: 36, color: PusulaRenk.lacivert),
                  ),
                  const SizedBox(height: 18),
                  Text('Becayiş sende kapalı', style: PusulaYazi.baslik(24, aralik: -1)),
                  const SizedBox(height: 10),
                  Text(
                    neden,
                    textAlign: TextAlign.center,
                    style: PusulaYazi.metin(15, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)
                        .copyWith(height: 1.45),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
