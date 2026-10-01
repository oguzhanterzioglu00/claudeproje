import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/bilesenler.dart';
import '../../../core/tema.dart';
import '../../profil/presentation/profil_alanlari.dart';
import '../data/kimlik_servisi.dart';
import '../data/oturum_deposu.dart';
import '../domain/hesap.dart';
import 'hesap_parcalari.dart';

/// E-postadaki şifre sıfırlama bağlantısına dokunulunca açılır: yeni şifre belirlenir ve oturum açık kalır.
class YeniSifreSayfasi extends StatefulWidget {
  const YeniSifreSayfasi({super.key, required this.oturum});

  final OturumDeposu oturum;

  @override
  State<YeniSifreSayfasi> createState() => _YeniSifreSayfasiState();
}

class _YeniSifreSayfasiState extends State<YeniSifreSayfasi> {
  final _sifre = TextEditingController();
  String? _hata;

  @override
  void dispose() {
    _sifre.dispose();
    super.dispose();
  }

  bool get _uygun => HesapKurali.sifreHatasi(_sifre.text) == null;

  Future<void> _kaydet() async {
    if (!_uygun) return;
    setState(() => _hata = null);
    try {
      await widget.oturum.yeniSifreBelirle(_sifre.text);
    } on KimlikHatasi catch (h) {
      if (mounted) setState(() => _hata = h.mesaj);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListenableBuilder(
        listenable: widget.oturum,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(22, 40, 22, 28),
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: PusulaRenk.amber, borderRadius: BorderRadius.circular(18)),
              child: const Icon(LucideIcons.keyRound, size: 28, color: PusulaRenk.lacivert),
            ),
            const SizedBox(height: 18),
            Text('Yeni şifre belirle', style: PusulaYazi.baslik(28, aralik: -1.1)),
            const SizedBox(height: 8),
            Text(
              'Hesabını kurtardık. Bundan sonra kullanacağın yeni şifreyi yaz.',
              style: PusulaYazi.metin(14, renk: PusulaRenk.soluk, agirlik: FontWeight.w500).copyWith(height: 1.45),
            ),
            const SizedBox(height: 20),
            MetinAlani(
              etiket: 'Yeni şifre',
              denetleyici: _sifre,
              onDegis: () => setState(() {}),
              gizli: true,
              hata: _sifre.text.isNotEmpty ? HesapKurali.sifreHatasi(_sifre.text) : null,
            ),
            if (_hata != null) ...[const SizedBox(height: 12), HataKutusu(mesaj: _hata!)],
            const SizedBox(height: 18),
            BirincilDugme(
              yukseklik: 56,
              metin: 'Şifreyi kaydet',
              yukleniyor: widget.oturum.mesgul,
              yukleniyorMetni: 'Kaydediliyor',
              onPressed: _uygun ? _kaydet : null,
            ),
            TextButton(
              onPressed: widget.oturum.mesgul ? null : widget.oturum.kurtarmadanVazgec,
              child: Text('Vazgeç', style: PusulaYazi.metin(14, renk: PusulaRenk.soluk, agirlik: FontWeight.w700)),
            ),
          ],
        ),
      ),
    ),
  );
}
