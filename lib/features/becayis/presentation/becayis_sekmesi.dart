import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/bilesenler.dart';
import '../../../core/tema.dart';
import '../../../core/ucgenler.dart';
import '../data/becayis_deposu.dart';
import '../domain/eslesme.dart';
import '../../profil/domain/profil.dart';
import 'becayis_dilekce_sayfasi.dart';
import 'becayis_eslesme_sayfasi.dart';
import 'becayis_ilan_ver_sayfasi.dart';
import 'becayis_ilanlar_sayfasi.dart';
import 'becayis_panel_sayfasi.dart';

/// Becayiş sekmesi: panel ve ona bağlı ekranlar. Yalnızca 657 memurlarına
/// açıktır; diğer statülerde nedenini anlatan sayfa gösterilir.
class BecayisSekmesi extends StatelessWidget {
  const BecayisSekmesi({super.key, required this.profil, required this.depo, this.profilAc});

  final Profil profil;
  final BecayisDeposu depo;

  /// Profil eksikken "Profili düzenle" düğmesi; boşsa düğme gösterilmez.
  final VoidCallback? profilAc;

  Future<T?> _git<T>(BuildContext context, Widget sayfa) =>
      Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => sayfa));

  void _eslesmeAc(BuildContext context, Eslesme e) => _git<void>(
    context,
    BecayisEslesmeSayfasi(
      depo: depo,
      ilkEslesme: e,
      dilekceAc: (e) => _git<void>(context, BecayisDilekceSayfasi(depo: depo, eslesme: e)),
    ),
  );

  void _ilanVer(BuildContext context) => _git<void>(context, BecayisIlanVerSayfasi(depo: depo));

  @override
  Widget build(BuildContext context) {
    final neden = profil.becayisKapaliNedeni;
    if (neden != null) return BecayisKapaliSayfasi(neden: neden);

    final eksik = profil.eksikBecayisAlanlari;
    if (eksik.isNotEmpty) return BecayisProfilEksikSayfasi(eksik: eksik, profilAc: profilAc);

    return ListenableBuilder(
      listenable: depo,
      builder: (context, _) => Scaffold(
        body: !depo.yayinda
            ? BecayisIlansizSayfasi(
                profil: profil,
                ilanVer: () => _ilanVer(context),
                ilanlariGor: () => _git<void>(
                  context,
                  BecayisIlanlarSayfasi(
                    depo: depo,
                    eslesmeAc: (e) => _eslesmeAc(context, e),
                    ilanVer: () => _ilanVer(context),
                  ),
                ),
              )
            : BecayisPanelSayfasi(
                benim: depo.benim,
                eslesmeler: depo.eslesmeler,
                eslesmeAc: (e) => _eslesmeAc(context, e),
                ilanlariGor: () => _git<void>(
                  context,
                  BecayisIlanlarSayfasi(
                    depo: depo,
                    eslesmeAc: (e) => _eslesmeAc(context, e),
                    ilanVer: () => _ilanVer(context),
                  ),
                ),
                ilaniDuzenle: () => _ilanVer(context),
              ),
      ),
    );
  }
}

/// Becayiş eşleştirme (sunucu ve ödeme) henüz açık değilken gösterilen sayfa. Örnek kişi ya da sahte
/// ödeme göstermez; yalnızca durumu ve becayişin yasal çerçevesini anlatır.
class BecayisYakindaSayfasi extends StatelessWidget {
  const BecayisYakindaSayfasi({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(color: PusulaRenk.cizgi, shape: BoxShape.circle),
                child: const Icon(LucideIcons.arrowRightLeft, size: 36, color: PusulaRenk.lacivert),
              ),
              const SizedBox(height: 18),
              Text('Becayiş yakında', style: PusulaYazi.baslik(24, aralik: -1)),
              const SizedBox(height: 10),
              Text(
                'Aynı kurum ve sınıftaki memurlarla karşılıklı yer değiştirme eşleştirmesi hazırlanıyor. '
                'Şimdilik hakkını "Hakkım ne?" bölümünden sorabilirsin. Becayiş, kurumun atamaya yetkili '
                'amirinin uygun bulmasına bağlıdır (657 sayılı Kanun md. 73).',
                textAlign: TextAlign.center,
                style: PusulaYazi.metin(15, renk: PusulaRenk.soluk, agirlik: FontWeight.w500).copyWith(height: 1.45),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// 657 memuru olmayan (veya adaylığı süren) kullanıcılar için açıklama.
class BecayisKapaliSayfasi extends StatelessWidget {
  const BecayisKapaliSayfasi({super.key, required this.neden});

  final String neden;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(color: PusulaRenk.cizgi, shape: BoxShape.circle),
                child: const Icon(LucideIcons.lock, size: 36, color: PusulaRenk.lacivert),
              ),
              const SizedBox(height: 18),
              Text('Becayiş sende kapalı', style: PusulaYazi.baslik(24, aralik: -1)),
              const SizedBox(height: 10),
              Text(
                neden,
                textAlign: TextAlign.center,
                style: PusulaYazi.metin(15, renk: PusulaRenk.soluk, agirlik: FontWeight.w500).copyWith(height: 1.45),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Profilde becayiş için gereken bilgiler eksikse yönlendirme sayfası.
class BecayisProfilEksikSayfasi extends StatelessWidget {
  const BecayisProfilEksikSayfasi({super.key, required this.eksik, this.profilAc});

  final List<String> eksik;
  final VoidCallback? profilAc;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(color: PusulaRenk.cizgi, shape: BoxShape.circle),
                child: const Icon(LucideIcons.userRound, size: 36, color: PusulaRenk.lacivert),
              ),
              const SizedBox(height: 18),
              Text('Profilini tamamla', style: PusulaYazi.baslik(24, aralik: -1)),
              const SizedBox(height: 10),
              Text(
                'Becayiş eşleşmesi kurum, hizmet sınıfı ve ilinle yapılır. Profilinde eksik olanlar: '
                '${eksik.join(', ')}.',
                textAlign: TextAlign.center,
                style: PusulaYazi.metin(15, renk: PusulaRenk.soluk, agirlik: FontWeight.w500).copyWith(height: 1.45),
              ),
              if (profilAc != null) ...[
                const SizedBox(height: 22),
                BirincilDugme(yukseklik: 56, metin: 'Profili düzenle', onPressed: profilAc),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// Kullanıcının henüz becayiş ilanı yokken gösterilen karşılama.
class BecayisIlansizSayfasi extends StatelessWidget {
  const BecayisIlansizSayfasi({super.key, required this.profil, required this.ilanVer, required this.ilanlariGor});

  final Profil profil;
  final VoidCallback ilanVer;
  final VoidCallback ilanlariGor;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
      children: [
        Text(
          'Karşılıklı yer değiştirme',
          style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w700),
        ),
        Text('Becayiş', style: PusulaYazi.baslik(26, aralik: -1.2)),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            color: PusulaRenk.lacivert,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Stack(
              children: [
                const Positioned(
                  right: -80,
                  top: -90,
                  child: Opacity(opacity: 0.45, child: PusulaUcgenler(boyut: 210, orta: PusulaRenk.mavi)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Henüz ilanın yok', style: PusulaYazi.baslik(26, renk: PusulaRenk.beyaz, aralik: -1.1)),
                    const SizedBox(height: 8),
                    Text(
                      '${profil.unvan} · ${profil.kurumAdi} · ${profil.il}',
                      style: PusulaYazi.metin(14, renk: const Color(0xFFC9D0E0)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'İlan vermek ücretsiz. Gitmek istediğin illeri seç; aynı kurum ve sınıftaki karşılıklı '
                      'eşleşmeleri senin için ararız.',
                      style: PusulaYazi.metin(
                        14,
                        renk: const Color(0xFFDCE3FF),
                        agirlik: FontWeight.w500,
                      ).copyWith(height: 1.4),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        BirincilDugme(yukseklik: 58, ikon: LucideIcons.plus, metin: 'İlan ver', onPressed: ilanVer),
        const SizedBox(height: 10),
        BirincilDugme(
          yukseklik: 54,
          ikon: LucideIcons.search,
          metin: 'İlanları gör',
          zemin: PusulaRenk.beyaz,
          yazi: PusulaRenk.lacivert,
          onPressed: ilanlariGor,
        ),
      ],
    ),
  );
}
