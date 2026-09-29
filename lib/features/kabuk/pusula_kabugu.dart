import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/alt_cubuk.dart';
import '../ana_sayfa/ana_sayfa.dart';
import '../ana_sayfa/ana_sayfa_verisi.dart';
import '../asistan/asistan_sayfasi.dart';
import '../becayis/data/becayis_deposu.dart';
import '../ilanlar/ilanlar_sayfasi.dart';
import '../becayis/domain/statu.dart';
import '../becayis/presentation/becayis_sekmesi.dart';
import '../maas/presentation/maas_sayfasi.dart';

/// Uygulama kabuğu: beş sekme ve yüzen alt çubuk. Sekmeler değişince durumları
/// korunur ([IndexedStack]).
class PusulaKabugu extends StatefulWidget {
  const PusulaKabugu({
    super.key,
    required this.profil,
    required this.becayisDeposu,
    this.anaSayfaVerisi = AnaSayfaVerisi.ornekVeri,
    this.bugun,
    this.baslangicSekmesi = 0,
  });

  final Profil profil;
  final BecayisDeposu becayisDeposu;
  final AnaSayfaVerisi anaSayfaVerisi;
  final DateTime? bugun;
  final int baslangicSekmesi;

  /// Sekme sırası; kısayollar bu sabitlerle yönlendirir.
  static const anaSayfa = 0;
  static const maas = 1;
  static const asistan = 2;
  static const becayis = 3;
  static const ilanlar = 4;

  @override
  State<PusulaKabugu> createState() => _PusulaKabuguState();
}

class _PusulaKabuguState extends State<PusulaKabugu> {
  static const _sekmeler = [
    AltSekme(etiket: 'Ana sayfa', ikon: LucideIcons.house),
    AltSekme(etiket: 'Maaş', ikon: LucideIcons.calculator),
    AltSekme(etiket: 'Asistan', ikon: LucideIcons.sparkles),
    AltSekme(etiket: 'Becayiş', ikon: LucideIcons.arrowRightLeft),
    AltSekme(etiket: 'İlanlar', ikon: LucideIcons.briefcase),
  ];

  late int _secili = widget.baslangicSekmesi;

  void _git(int i) => setState(() => _secili = i);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(
          index: _secili,
          children: [
            AnaSayfa(
              veri: widget.anaSayfaVerisi,
              bugun: widget.bugun,
              maasaGit: () => _git(PusulaKabugu.maas),
              asistanaGit: () => _git(PusulaKabugu.asistan),
              becayisiAc: () => _git(PusulaKabugu.becayis),
            ),
            MaasSayfasi(ay: widget.bugun?.month),
            const AsistanSayfasi(),
            BecayisSekmesi(profil: widget.profil, depo: widget.becayisDeposu),
            IlanlarSayfasi(bugun: widget.bugun),
          ],
        ),
        bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
            ? null
            : PusulaAltCubuk(sekmeler: _sekmeler, secili: _secili, onSec: _git),
      );
}
