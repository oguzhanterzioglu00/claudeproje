import 'package:flutter/material.dart';

import 'core/tema.dart';
import 'features/becayis/data/becayis_deposu.dart';
import 'features/becayis/data/ornek_veri.dart';
import 'features/becayis/domain/statu.dart';
import 'features/becayis/presentation/becayis_sekmesi.dart';

void main() => runApp(const PusulaUygulamasi());

class PusulaUygulamasi extends StatefulWidget {
  const PusulaUygulamasi({super.key});

  @override
  State<PusulaUygulamasi> createState() => _PusulaUygulamasiState();
}

class _PusulaUygulamasiState extends State<PusulaUygulamasi> {
  // Uygulama kabuğu (alt gezinme, ana sayfa, maaş, asistan) eklenene kadar
  // açılışta Becayiş sekmesi örnek verilerle gösterilir.
  static const _profil = Profil(ad: 'Ayşe Yılmaz', statu: Statu.memur657);
  final BecayisDeposu _depo = BecayisOrnekVeri.depo();

  @override
  void dispose() {
    _depo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Kamu Pusulası',
        debugShowCheckedModeBanner: false,
        theme: pusulaTema(),
        home: BecayisSekmesi(profil: _profil, depo: _depo),
      );
}
