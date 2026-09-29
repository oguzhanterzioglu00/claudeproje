import 'package:flutter/material.dart';

import 'core/tema.dart';
import 'core/ucgenler.dart';
import 'features/kabuk/pusula_kabugu.dart';
import 'features/profil/data/profil_deposu.dart';
import 'features/profil/data/profil_kaydi.dart';
import 'features/profil/presentation/ilk_kurulum_sayfasi.dart';

void main() => runApp(const PusulaUygulamasi());

/// Uygulama kökü: profil yüklenir; profil yoksa karşılama ve ilk kurulum, varsa ana kabuk açılır.
class PusulaUygulamasi extends StatefulWidget {
  const PusulaUygulamasi({super.key, this.profilKaydi = const YerelProfilKaydi()});

  final ProfilKaydi profilKaydi;

  @override
  State<PusulaUygulamasi> createState() => _PusulaUygulamasiState();
}

class _PusulaUygulamasiState extends State<PusulaUygulamasi> {
  late final ProfilDeposu _profil = ProfilDeposu(widget.profilKaydi);

  @override
  void initState() {
    super.initState();
    _profil.yukle();
  }

  @override
  void dispose() {
    _profil.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Kamu Pusulası',
        debugShowCheckedModeBanner: false,
        theme: pusulaTema(),
        home: ListenableBuilder(
          listenable: _profil,
          builder: (context, _) {
            if (!_profil.yuklendi) return const _Acilis();
            if (_profil.profil == null) {
              // Kayıt tamamlanınca depo değişir ve kabuk kendiliğinden açılır.
              return IlkKurulumSayfasi(depo: _profil);
            }
            return PusulaKabugu(profilDeposu: _profil);
          },
        ),
      );
}

/// Profil okunurken kısa açılış ekranı.
class _Acilis extends StatelessWidget {
  const _Acilis();

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: PusulaRenk.lacivert,
        body: Center(child: PusulaUcgenler(boyut: 96, orta: PusulaRenk.mavi)),
      );
}
