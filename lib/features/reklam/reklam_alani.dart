import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/baglanti.dart';
import '../../core/tema.dart';

class SponsorBanneri {
  const SponsorBanneri({
    required this.firma,
    required this.baslik,
    required this.aciklama,
    required this.hedef,
    this.gorsel,
  });

  final String firma;
  final String baslik;
  final String aciklama;
  final Uri hedef;
  final Uri? gorsel;
}

/// Sponsor olduğunda firma bannerını, boşken reklam başvurusu çağrısını gösterir.
class ReklamAlani extends StatelessWidget {
  const ReklamAlani({super.key, this.sponsor, this.baglantiAcici});

  final SponsorBanneri? sponsor;
  final BaglantiAcici? baglantiAcici;

  static final reklamBasvurusu = Uri.https('wa.me', '/905529316903', {
    'text': 'Merhaba, Kamu Pusulası uygulamasına reklam vermek istiyorum.',
  });

  @override
  Widget build(BuildContext context) {
    final veri = sponsor;
    final hedef = veri?.hedef ?? reklamBasvurusu;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Semantics(
        button: true,
        label: veri == null
            ? 'Buraya reklam verebilirsiniz'
            : '${veri.firma} sponsorlu içerik',
        child: Material(
          color: PusulaRenk.lacivert,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => baglantiAc(context, hedef, acici: baglantiAcici),
            child: SizedBox(
              height: 112,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (veri?.gorsel != null)
                      Image.network(
                        veri!.gorsel.toString(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            PusulaRenk.lacivert.withValues(alpha: 0.96),
                            PusulaRenk.mavi.withValues(alpha: 0.72),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: PusulaRenk.amber,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              veri == null
                                  ? LucideIcons.megaphone
                                  : LucideIcons.badgeCheck,
                              color: PusulaRenk.lacivert,
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  veri?.baslik ??
                                      'Buraya reklam verebilirsiniz',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PusulaYazi.baslik(
                                    16,
                                    renk: PusulaRenk.beyaz,
                                    aralik: -0.35,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  veri?.aciklama ??
                                      'Markanı kamu çalışanlarına ulaştırmak için WhatsApp’tan bize yaz.',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: PusulaYazi.metin(
                                    12,
                                    renk: const Color(0xFFDCE3FF),
                                    agirlik: FontWeight.w500,
                                  ),
                                ),
                                if (veri != null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    'REKLAM · ${veri.firma}',
                                    style: PusulaYazi.metin(
                                      9,
                                      renk: PusulaRenk.amber,
                                      agirlik: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(
                            LucideIcons.arrowUpRight,
                            color: PusulaRenk.beyaz,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
