import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/bilesenler.dart';
import '../../../core/tema.dart';
import '../../../core/yukselen.dart';
import '../../profil/presentation/profil_alanlari.dart';
import '../data/kimlik_servisi.dart';
import '../data/oturum_deposu.dart';
import '../domain/hesap.dart';
import 'hesap_parcalari.dart';

/// E-posta hesabının şifresini değiştirir: mevcut şifre doğrulanır, yeni şifre kurala uymalı.
class SifreDegistirSayfasi extends StatefulWidget {
  const SifreDegistirSayfasi({super.key, required this.oturum});

  final OturumDeposu oturum;

  @override
  State<SifreDegistirSayfasi> createState() => _SifreDegistirSayfasiState();
}

class _SifreDegistirSayfasiState extends State<SifreDegistirSayfasi> {
  final _eski = TextEditingController();
  final _yeni = TextEditingController();
  final _tekrar = TextEditingController();
  bool _gizli = true;
  bool _bitti = false;
  String? _hata;

  @override
  void dispose() {
    _eski.dispose();
    _yeni.dispose();
    _tekrar.dispose();
    super.dispose();
  }

  bool get _eslesiyor => _yeni.text == _tekrar.text;

  bool get _gonderilebilir =>
      !widget.oturum.mesgul && _eski.text.isNotEmpty && HesapKurali.sifreHatasi(_yeni.text) == null && _eslesiyor;

  Future<void> _kaydet() async {
    if (!_gonderilebilir) return;
    setState(() => _hata = null);
    try {
      await widget.oturum.sifreDegistir(_eski.text, _yeni.text);
      if (mounted) setState(() => _bitti = true);
    } on KimlikHatasi catch (h) {
      if (mounted) setState(() => _hata = h.mesaj);
    }
  }

  Widget _goz() => Semantics(
        button: true,
        label: _gizli ? 'Şifreleri göster' : 'Şifreleri gizle',
        excludeSemantics: true,
        onTap: () => setState(() => _gizli = !_gizli),
        child: IconButton(
          onPressed: () => setState(() => _gizli = !_gizli),
          icon: Icon(_gizli ? LucideIcons.eye : LucideIcons.eyeOff, size: 20, color: PusulaRenk.lacivert),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: _bitti
              ? _Basari(onTamam: () => Navigator.of(context).maybePop())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
                  children: [
                    const Yukselen(
                      child: GeriBaslik(ustYazi: 'Hesap ve güvenlik', baslik: 'Şifre değiştir', sag: SizedBox.shrink()),
                    ),
                    const SizedBox(height: 22),
                    MetinAlani(
                      etiket: 'Mevcut şifre',
                      denetleyici: _eski,
                      onDegis: () => setState(() {}),
                      gizli: _gizli,
                      otomatikDoldur: const [AutofillHints.password],
                      klavyeEylemi: TextInputAction.next,
                      sonEk: _goz(),
                    ),
                    const SizedBox(height: 16),
                    MetinAlani(
                      etiket: 'Yeni şifre',
                      denetleyici: _yeni,
                      onDegis: () => setState(() {}),
                      gizli: _gizli,
                      otomatikDoldur: const [AutofillHints.newPassword],
                      klavyeEylemi: TextInputAction.next,
                    ),
                    const SizedBox(height: 10),
                    SifreKurallari(sifre: _yeni.text),
                    const SizedBox(height: 16),
                    MetinAlani(
                      etiket: 'Yeni şifre (tekrar)',
                      denetleyici: _tekrar,
                      onDegis: () => setState(() {}),
                      gizli: _gizli,
                      klavyeEylemi: TextInputAction.done,
                      onGonder: _kaydet,
                      hata: _tekrar.text.isNotEmpty && !_eslesiyor ? 'Şifreler eşleşmiyor' : null,
                    ),
                    if (_hata != null) ...[
                      const SizedBox(height: 14),
                      HataKutusu(mesaj: _hata!),
                    ],
                    const SizedBox(height: 22),
                    ListenableBuilder(
                      listenable: widget.oturum,
                      builder: (context, _) => BirincilDugme(
                        yukseklik: 58,
                        metin: 'Şifreyi güncelle',
                        yukleniyor: widget.oturum.mesgul,
                        yukleniyorMetni: 'Güncelleniyor',
                        onPressed: _gonderilebilir ? _kaydet : null,
                      ),
                    ),
                  ],
                ),
        ),
      );
}

class _Basari extends StatelessWidget {
  const _Basari({required this.onTamam});

  final VoidCallback onTamam;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: MediaQuery.disableAnimationsOf(context) ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (context, v, child) => Transform.scale(scale: v.clamp(0.0, 1.4), child: child),
              child: Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(color: PusulaRenk.yesilZemin, shape: BoxShape.circle),
                child: const Icon(LucideIcons.check, size: 44, color: PusulaRenk.yesilYazi),
              ),
            ),
            const SizedBox(height: 20),
            Text('Şifren güncellendi', style: PusulaYazi.baslik(24, aralik: -1)),
            const SizedBox(height: 8),
            Text('Bir sonraki girişte yeni şifreni kullan.',
                textAlign: TextAlign.center,
                style: PusulaYazi.metin(14, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)),
            const SizedBox(height: 28),
            BirincilDugme(yukseklik: 56, metin: 'Tamam', onPressed: onTamam),
          ],
        ),
      );
}
