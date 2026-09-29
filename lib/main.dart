import 'package:flutter/material.dart';

import 'core/depolama.dart';
import 'core/tema.dart';
import 'features/hesap/data/kimlik_servisi.dart';
import 'features/hesap/data/oturum_deposu.dart';
import 'features/hesap/data/yerel_kimlik_servisi.dart';
import 'features/kabuk/uygulama_akisi.dart';
import 'features/profil/data/fotograf_deposu.dart';
import 'features/profil/data/profil_kaydi.dart';

void main() => runApp(const PusulaUygulamasi());

/// Uygulama kökü. Bağımlılıklar (kimlik servisi, depolama, fotoğraf kaynağı)
/// testlerde ve ileride gerçek arka uçla değiştirilebilir.
class PusulaUygulamasi extends StatefulWidget {
  const PusulaUygulamasi({
    super.key,
    this.kimlik,
    this.depolama = const YerelDepolama(),
    this.profilKaydiUret,
    this.fotografKaynagi = const ImagePickerFotografKaynagi(),
    this.appleGoster = true,
  });

  /// Boşsa cihazda çalışan örnek servis ([YerelKimlikServisi]).
  final KimlikServisi? kimlik;
  final AnahtarDeger depolama;
  final ProfilKaydi Function(String hesapId)? profilKaydiUret;
  final FotografKaynagi fotografKaynagi;
  final bool appleGoster;

  @override
  State<PusulaUygulamasi> createState() => _PusulaUygulamasiState();
}

class _PusulaUygulamasiState extends State<PusulaUygulamasi> {
  late final OturumDeposu _oturum = OturumDeposu(widget.kimlik ?? YerelKimlikServisi(depolama: widget.depolama));

  @override
  void initState() {
    super.initState();
    _oturum.yukle();
  }

  @override
  void dispose() {
    _oturum.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Kamu Pusulası',
        debugShowCheckedModeBanner: false,
        theme: pusulaTema(),
        home: UygulamaAkisi(
          oturum: _oturum,
          depolama: widget.depolama,
          profilKaydiUret: widget.profilKaydiUret ?? (id) => YerelProfilKaydi(hesapId: id),
          fotografKaynagi: widget.fotografKaynagi,
          appleGoster: widget.appleGoster,
        ),
      );
}
