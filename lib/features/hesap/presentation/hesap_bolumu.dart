import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/bilesenler.dart';
import '../../../core/tema.dart';
import '../data/kimlik_servisi.dart';
import '../data/oturum_deposu.dart';
import '../domain/hesap.dart';
import 'sifre_degistir_sayfasi.dart';

/// Profil ekranındaki "Hesap ve güvenlik" bölümü: giriş yöntemi, şifre değiştirme,
/// çıkış ve hesabı silme.
class HesapBolumu extends StatelessWidget {
  const HesapBolumu({super.key, required this.oturum, this.veriSil});

  final OturumDeposu oturum;

  /// Hesap silinirken cihazdaki kullanıcı verilerini de temizler (profil, fotoğraf).
  final Future<void> Function()? veriSil;

  String _saglayiciAciklamasi(Hesap h) => switch (h.saglayici) {
        GirisSaglayici.eposta => h.eposta,
        GirisSaglayici.google => h.eposta.isEmpty
            ? 'Google ile giriş${oturum.gercek ? '' : ' (örnek)'}'
            : 'Google ile giriş · ${h.eposta}',
        GirisSaglayici.apple => 'Apple ile giriş${oturum.gercek ? '' : ' (örnek)'}',
      };

  static IconData _ikon(GirisSaglayici s) => switch (s) {
        GirisSaglayici.eposta => LucideIcons.mail,
        GirisSaglayici.google => LucideIcons.globe,
        GirisSaglayici.apple => LucideIcons.apple,
      };

  void _mesajGoster(ScaffoldMessengerState messenger, String metin) {
    messenger.showSnackBar(SnackBar(
      content: Text(metin, style: PusulaYazi.metin(14, renk: PusulaRenk.beyaz, agirlik: FontWeight.w600)),
      backgroundColor: PusulaRenk.lacivert,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<bool> _onay(BuildContext context,
      {required String baslik, required String metin, required String dugme, bool tehlike = false}) async {
    final s = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(baslik, style: PusulaYazi.baslik(18, aralik: -0.5)),
        content: Text(metin, style: PusulaYazi.metin(14, agirlik: FontWeight.w500)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(dugme,
                style: PusulaYazi.metin(14,
                    renk: tehlike ? PusulaRenk.kirmizi : PusulaRenk.lacivert, agirlik: FontWeight.w700)),
          ),
        ],
      ),
    );
    return s == true;
  }

  Future<void> _cikis(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!await _onay(context,
        baslik: 'Çıkış yapılsın mı?',
        metin: 'Verilerin bu cihazda kalır; tekrar giriş yapınca geri gelir.',
        dugme: 'Çıkış yap')) {
      return;
    }
    try {
      await oturum.cikisYap();
      navigator.popUntil((r) => r.isFirst);
    } on KimlikHatasi catch (h) {
      _mesajGoster(messenger, h.mesaj);
    }
  }

  Future<void> _hesapSil(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!await _onay(context,
        baslik: 'Hesabın silinsin mi?',
        metin: 'Hesabın, profil bilgilerin ve fotoğrafın bu cihazdan kalıcı olarak silinir. Bu işlem geri alınamaz.',
        dugme: 'Hesabımı sil',
        tehlike: true)) {
      return;
    }
    try {
      await oturum.hesabiSil();
      await veriSil?.call();
      navigator.popUntil((r) => r.isFirst);
    } on KimlikHatasi catch (h) {
      _mesajGoster(messenger, h.mesaj);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: oturum,
        builder: (context, _) {
          final hesap = oturum.hesap;
          if (hesap == null) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Hesap ve güvenlik', style: PusulaYazi.baslik(18, agirlik: FontWeight.w700, aralik: -0.4)),
              const SizedBox(height: 10),
              PusulaKart(
                radius: 22,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: PusulaRenk.cizgi, borderRadius: BorderRadius.circular(14)),
                      child: Icon(_ikon(hesap.saglayici), size: 20, color: PusulaRenk.lacivert),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Giriş yöntemi',
                              style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w700)),
                          Text(_saglayiciAciklamasi(hesap),
                              overflow: TextOverflow.ellipsis, style: PusulaYazi.metin(15, agirlik: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (hesap.sifreliHesap)
                _Satir(
                  ikon: LucideIcons.keyRound,
                  metin: 'Şifreyi değiştir',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => SifreDegistirSayfasi(oturum: oturum)),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    '${hesap.saglayici.etiket} hesabınla giriş yaptığın için şifren orada yönetilir.',
                    style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
                  ),
                ),
              const SizedBox(height: 8),
              _Satir(ikon: LucideIcons.logOut, metin: 'Çıkış yap', onTap: () => _cikis(context)),
              const SizedBox(height: 8),
              _Satir(
                ikon: LucideIcons.userX,
                metin: 'Hesabımı ve verilerimi sil',
                tehlike: true,
                onTap: () => _hesapSil(context),
              ),
            ],
          );
        },
      );
}

class _Satir extends StatelessWidget {
  const _Satir({required this.ikon, required this.metin, required this.onTap, this.tehlike = false});

  final IconData ikon;
  final String metin;
  final VoidCallback onTap;
  final bool tehlike;

  @override
  Widget build(BuildContext context) {
    final renk = tehlike ? PusulaRenk.kirmizi : PusulaRenk.lacivert;
    return Semantics(
      button: true,
      label: metin,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: PusulaRenk.beyaz,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: renk, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(ikon, size: 20, color: renk),
                  const SizedBox(width: 12),
                  Expanded(child: Text(metin, style: PusulaYazi.metin(15, renk: renk, agirlik: FontWeight.w700))),
                  if (!tehlike) const Icon(LucideIcons.chevronRight, size: 18, color: PusulaRenk.soluk),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
