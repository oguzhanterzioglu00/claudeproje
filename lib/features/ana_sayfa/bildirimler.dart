import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/tema.dart';
import '../profil/domain/profil.dart';

/// Bildirime dokununca gidilecek yer.
enum BildirimHedefi { profil, maas, becayis }

/// Uygulama içi bildirim: profil ve durumdan türetilen, kullanıcının yapabileceği bir sonraki adım.
class Bildirim {
  const Bildirim({required this.baslik, required this.aciklama, required this.hedef, required this.ikon});

  final String baslik;
  final String aciklama;
  final BildirimHedefi hedef;
  final IconData ikon;
}

/// Bildirimleri profilden ve becayiş durumundan üretir. Uydurma içerik yoktur:
/// her bildirim gerçekten eksik bir bilgiye ya da bulunmuş bir eşleşmeye dayanır.
List<Bildirim> bildirimleriUret(Profil p, {required bool becayisYayinda, required int ikiliEslesme}) {
  final becayisAcik = p.becayisYapabilir;
  return [
    if (becayisAcik && p.eksikBecayisAlanlari.isNotEmpty)
      Bildirim(
        baslik: 'Becayiş için profilini tamamla',
        aciklama: 'Eksik: ${p.eksikBecayisAlanlari.join(', ')}',
        hedef: BildirimHedefi.profil,
        ikon: LucideIcons.userRoundCog,
      ),
    if (becayisAcik && p.eksikBecayisAlanlari.isEmpty && !becayisYayinda)
      const Bildirim(
        baslik: 'Becayiş ilanı ver',
        aciklama: 'İlan vermek ücretsiz; eşleşmeleri senin için ararız.',
        hedef: BildirimHedefi.becayis,
        ikon: LucideIcons.arrowRightLeft,
      ),
    if (becayisAcik && becayisYayinda && ikiliEslesme > 0)
      Bildirim(
        baslik: '$ikiliEslesme yeni becayiş eşleşmesi',
        aciklama: 'Eşleşmelere bak ve ilgilendiğini bildir.',
        hedef: BildirimHedefi.becayis,
        ikon: LucideIcons.partyPopper,
      ),
    if (p.statu == Statu.memur657 && p.maas == null)
      const Bildirim(
        baslik: 'Maaşını hesapla',
        aciklama: 'Derece ve kademeni girince tahmini net maaşını ana sayfada görürsün.',
        hedef: BildirimHedefi.maas,
        ikon: LucideIcons.calculator,
      ),
  ];
}

/// Bildirim listesi (alt sayfa içeriği). Bir öğeye dokunulunca [onSec] çağrılır.
class BildirimListesi extends StatelessWidget {
  const BildirimListesi({super.key, required this.bildirimler, required this.onSec});

  final List<Bildirim> bildirimler;
  final ValueChanged<Bildirim> onSec;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Bildirimler', style: PusulaYazi.baslik(22, aralik: -0.9)),
          const SizedBox(height: 14),
          if (bildirimler.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: PusulaRenk.cizgi, borderRadius: BorderRadius.circular(18)),
                    child: const Icon(LucideIcons.bellOff, size: 24, color: PusulaRenk.lacivert),
                  ),
                  const SizedBox(height: 10),
                  Text('Yeni bildirim yok', style: PusulaYazi.metin(16, agirlik: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Yeni bir gelişme olunca burada görürsün.',
                      style: PusulaYazi.metin(13, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)),
                ],
              ),
            )
          else
            for (final b in bildirimler) ...[
              Semantics(
                container: true,
                button: true,
                label: '${b.baslik}. ${b.aciklama}',
                excludeSemantics: true,
                onTap: () => onSec(b),
                child: Material(
                  color: PusulaRenk.zemin,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => onSec(b),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: PusulaRenk.amber, borderRadius: BorderRadius.circular(14)),
                            child: Icon(b.ikon, size: 22, color: PusulaRenk.lacivert),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b.baslik, style: PusulaYazi.metin(15, agirlik: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(b.aciklama,
                                    style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)
                                        .copyWith(height: 1.35)),
                              ],
                            ),
                          ),
                          const Icon(LucideIcons.chevronRight, size: 18, color: PusulaRenk.soluk),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      );
}
