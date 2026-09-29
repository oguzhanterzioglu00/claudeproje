import 'package:flutter/material.dart';

import '../../core/depolama.dart';
import '../../core/logo.dart';
import '../../core/tema.dart';
import '../hesap/data/oturum_deposu.dart';
import '../hesap/domain/hesap.dart';
import '../hesap/presentation/giris_sayfasi.dart';
import '../profil/data/fotograf_deposu.dart';
import '../profil/data/profil_deposu.dart';
import '../profil/data/profil_kaydi.dart';
import '../profil/domain/profil.dart';
import '../profil/presentation/hazirlaniyor_sayfasi.dart';
import '../profil/presentation/ilk_kurulum_sayfasi.dart';
import '../profil/presentation/karsilama_sayfasi.dart';
import 'pusula_kabugu.dart';

/// Bir hesaba ait cihaz içi kullanıcı verisi (profil ve fotoğraf).
class _KullaniciVerisi {
  _KullaniciVerisi(this.hesapId, this.profil, this.fotograf);

  final String hesapId;
  final ProfilDeposu profil;
  final FotografDeposu fotograf;

  bool get yuklendi => profil.yuklendi && fotograf.yuklendi;

  void dispose() {
    profil.dispose();
    fotograf.dispose();
  }
}

/// Uygulamanın giriş akışı:
/// tanıtım (yalnızca ilk kez) → giriş/kayıt → profil kurulumu → "hazırlanıyor" → ana kabuk.
/// Oturum kapanınca giriş ekranına, hesap değişince o hesabın verisine geçilir.
class UygulamaAkisi extends StatefulWidget {
  const UygulamaAkisi({
    super.key,
    required this.oturum,
    required this.depolama,
    required this.profilKaydiUret,
    required this.fotografKaynagi,
    this.appleGoster = true,
    this.kabukUret,
  });

  final OturumDeposu oturum;
  final AnahtarDeger depolama;

  /// Hesap kimliğinden o hesabın profil kaydını üretir.
  final ProfilKaydi Function(String hesapId) profilKaydiUret;
  final FotografKaynagi fotografKaynagi;
  final bool appleGoster;

  /// Ana kabuğu üretir; testlerde örnek servislerle değiştirilebilir.
  final Widget Function(BuildContext context, ProfilDeposu profil, FotografDeposu fotograf)? kabukUret;

  static const tanitimAnahtari = 'tanitim_goruldu_v1';

  @override
  State<UygulamaAkisi> createState() => _UygulamaAkisiState();
}

class _UygulamaAkisiState extends State<UygulamaAkisi> {
  bool? _tanitimGoruldu;
  _KullaniciVerisi? _veri;

  /// Bu oturumda kurulum ekranı gösterildiyse, bitince "hazırlanıyor" akışı da gösterilir.
  bool _kurulumGoruldu = false;
  bool _hazirlandi = false;

  @override
  void initState() {
    super.initState();
    widget.oturum.addListener(_oturumDegisti);
    _tanitimOku();
    _oturumDegisti();
  }

  @override
  void dispose() {
    widget.oturum.removeListener(_oturumDegisti);
    _veri?.dispose();
    super.dispose();
  }

  Future<void> _tanitimOku() async {
    final deger = await widget.depolama.oku(UygulamaAkisi.tanitimAnahtari);
    if (mounted) setState(() => _tanitimGoruldu = deger == '1');
  }

  Future<void> _tanitimBitti() async {
    setState(() => _tanitimGoruldu = true);
    await widget.depolama.yaz(UygulamaAkisi.tanitimAnahtari, '1');
  }

  /// Oturumdaki hesap değişince kullanıcı verisi o hesaba göre yeniden kurulur.
  void _oturumDegisti() {
    final Hesap? hesap = widget.oturum.hesap;
    if (hesap?.id == _veri?.hesapId) return;
    _veri?.dispose();
    _veri = null;
    _kurulumGoruldu = false;
    _hazirlandi = false;
    if (hesap != null) {
      final v = _KullaniciVerisi(
        hesap.id,
        ProfilDeposu(widget.profilKaydiUret(hesap.id)),
        FotografDeposu(widget.depolama, anahtar: 'profil_foto_v1_${hesap.id}'),
      );
      _veri = v;
      v.profil.yukle();
      v.fotograf.yukle();
      v.profil.addListener(_veriDegisti);
      v.fotograf.addListener(_veriDegisti);
    }
    if (mounted) setState(() {});
  }

  void _veriDegisti() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.oturum,
        builder: (context, _) {
          if (!widget.oturum.yuklendi || _tanitimGoruldu == null) return const AcilisEkrani();

          final hesap = widget.oturum.hesap;
          if (hesap == null) {
            return _tanitimGoruldu!
                ? GirisSayfasi(oturum: widget.oturum, appleGoster: widget.appleGoster)
                : KarsilamaSayfasi(onBasla: _tanitimBitti);
          }

          final veri = _veri;
          if (veri == null || !veri.yuklendi) return const AcilisEkrani();

          if (veri.profil.profil == null) {
            _kurulumGoruldu = true;
            return IlkKurulumSayfasi(
              depo: veri.profil,
              fotograf: veri.fotograf,
              fotografKaynagi: widget.fotografKaynagi,
              ilkAd: hesap.ad,
            );
          }

          if (_kurulumGoruldu && !_hazirlandi) {
            return HazirlaniyorSayfasi(
              ad: veri.profil.profil!.ad,
              memur: veri.profil.profil!.statu == Statu.memur657,
              onBitti: () {
                if (mounted) setState(() => _hazirlandi = true);
              },
            );
          }

          return widget.kabukUret != null
              ? widget.kabukUret!(context, veri.profil, veri.fotograf)
              : PusulaKabugu(
                  profilDeposu: veri.profil,
                  fotograf: veri.fotograf,
                  fotografKaynagi: widget.fotografKaynagi,
                  oturum: widget.oturum,
                );
        },
      );
}

/// Veriler okunurken kısa açılış ekranı (ibresi yerine oturan logo).
class AcilisEkrani extends StatelessWidget {
  const AcilisEkrani({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: PusulaRenk.lacivert,
        body: Center(child: AnimasyonluPusulaLogo(boyut: 132, arkaplan: false)),
      );
}
