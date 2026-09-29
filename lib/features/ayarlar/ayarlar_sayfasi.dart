import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/bilesenler.dart';
import '../../core/tema.dart';
import '../../core/yukselen.dart';
import '../hesap/domain/hesap.dart';
import '../profil/domain/profil.dart';
import 'kisisel_veri_dokumu.dart';
import 'uygulama_bilgisi.dart';
import 'yasal_metinler.dart';
import 'yasal_sayfasi.dart';

/// Ayarlar: hakkında, gizlilik ve yasal metinler, verilerimi kopyala, lisanslar.
class AyarlarSayfasi extends StatelessWidget {
  const AyarlarSayfasi({super.key, this.hesap, this.profil, this.fotografVar = false});

  final Hesap? hesap;
  final Profil? profil;
  final bool fotografVar;

  void _sayfaAc(BuildContext context, Widget sayfa) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => sayfa));

  Future<void> _verileriKopyala(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final dokum = KisiselVeriDokumu.uret(hesap: hesap, profil: profil, fotografVar: fotografVar);
    await Clipboard.setData(ClipboardData(text: dokum));
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Verilerin panoya kopyalandı. İstediğin yere yapıştırabilirsin.',
          style: PusulaYazi.metin(14, renk: PusulaRenk.beyaz, agirlik: FontWeight.w600),
        ),
        backgroundColor: PusulaRenk.lacivert,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 32),
            children: [
              const Yukselen(child: GeriBaslik(ustYazi: 'Kamu Pusulası', baslik: 'Ayarlar', sag: SizedBox.shrink())),
              const SizedBox(height: 22),
              const _Baslik('Gizlilik ve yasal'),
              _Satir(
                ikon: LucideIcons.shieldCheck,
                metin: 'Aydınlatma Metni',
                alt: 'Verilerin nasıl işlendiği (KVKK)',
                onTap: () => _sayfaAc(context, const YasalSayfasi(metin: YasalMetinler.aydinlatma)),
              ),
              const SizedBox(height: 8),
              _Satir(
                ikon: LucideIcons.fileText,
                metin: 'Kullanım Koşulları',
                alt: 'Hizmetin kapsamı ve sınırları',
                onTap: () => _sayfaAc(context, const YasalSayfasi(metin: YasalMetinler.kosullar)),
              ),
              const SizedBox(height: 22),
              const _Baslik('Verilerim'),
              _Satir(
                ikon: LucideIcons.copy,
                metin: 'Verilerimi kopyala',
                alt: 'Cihazdaki bilgilerinin dökümünü panoya al',
                onTap: () => _verileriKopyala(context),
              ),
              const SizedBox(height: 8),
              const _Bilgi(
                'Profilini ve hesabını silmek için Profil sayfasındaki "Profil bilgilerimi sil" ve '
                '"Hesabımı ve verilerimi sil" düğmelerini kullanabilirsin.',
              ),
              const SizedBox(height: 22),
              const _Baslik('Hakkında'),
              _Satir(
                ikon: LucideIcons.scrollText,
                metin: 'Açık kaynak lisansları',
                alt: 'Kullanılan yazı tipleri ve kütüphaneler',
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: UygulamaBilgisi.ad,
                  applicationVersion: UygulamaBilgisi.surumMetni,
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Column(
                  children: [
                    Text(UygulamaBilgisi.ad, style: PusulaYazi.metin(14, agirlik: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('Sürüm ${UygulamaBilgisi.surumMetni}',
                        style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _Baslik extends StatelessWidget {
  const _Baslik(this.metin);

  final String metin;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(metin, style: PusulaYazi.baslik(18, agirlik: FontWeight.w700, aralik: -0.4)),
      );
}

class _Bilgi extends StatelessWidget {
  const _Bilgi(this.metin);

  final String metin;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(metin,
            style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500).copyWith(height: 1.45)),
      );
}

class _Satir extends StatelessWidget {
  const _Satir({required this.ikon, required this.metin, required this.alt, required this.onTap});

  final IconData ikon;
  final String metin;
  final String alt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        button: true,
        label: '$metin. $alt',
        excludeSemantics: true,
        onTap: onTap,
        child: Material(
          color: PusulaRenk.beyaz,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: PusulaRenk.cizgi, borderRadius: BorderRadius.circular(14)),
                    child: Icon(ikon, size: 20, color: PusulaRenk.lacivert),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(metin, style: PusulaYazi.metin(15, agirlik: FontWeight.w700)),
                        Text(alt, style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight, size: 18, color: PusulaRenk.soluk),
                ],
              ),
            ),
          ),
        ),
      );
}
