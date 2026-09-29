import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/bilesenler.dart';
import '../../core/tema.dart';
import '../../core/yukselen.dart';
import '../hatirlatici/hatirlatici_deposu.dart';
import '../ilanlar/ilan_modeli.dart';
import '../ilanlar/yeni_ilan_takibi.dart';
import '../hesap/domain/hesap.dart';
import '../profil/domain/profil.dart';
import 'kisisel_veri_dokumu.dart';
import 'uygulama_bilgisi.dart';
import 'yasal_metinler.dart';
import 'yasal_sayfasi.dart';

/// Ayarlar: hakkında, gizlilik ve yasal metinler, verilerimi kopyala, lisanslar.
class AyarlarSayfasi extends StatelessWidget {
  const AyarlarSayfasi({
    super.key,
    this.hesap,
    this.profil,
    this.fotografVar = false,
    this.hatirlatici,
    this.ilanTakibi,
  });

  final Hesap? hesap;
  final Profil? profil;
  final bool fotografVar;

  /// Verilir ve platform destekliyorsa "Hatırlatıcılar" bölümü görünür.
  final HatirlaticiDeposu? hatirlatici;

  /// Verilir ve platform destekliyorsa "Yeni ilan bildirimi" bölümü görünür.
  final YeniIlanTakibi? ilanTakibi;

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
          const Yukselen(
            child: GeriBaslik(ustYazi: 'Kamu Pusulası', baslik: 'Ayarlar', sag: SizedBox.shrink()),
          ),
          if (hatirlatici != null && hatirlatici!.destekleniyor) ...[
            const SizedBox(height: 22),
            _Hatirlaticilar(depo: hatirlatici!, profil: profil),
          ],
          if (ilanTakibi != null && ilanTakibi!.destekleniyor) ...[
            const SizedBox(height: 14),
            _YeniIlanBildirimi(takip: ilanTakibi!, statu: profil?.statu),
          ],
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
                Text(
                  'Sürüm ${UygulamaBilgisi.surumMetni}',
                  style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
                ),
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
    child: Text(
      metin,
      style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500).copyWith(height: 1.45),
    ),
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
                    Text(
                      alt,
                      style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
                    ),
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

/// Kademe ilerlemesi hatırlatıcısı anahtarı. Bildirimler yalnızca bu cihazda kurulur.
class _Hatirlaticilar extends StatelessWidget {
  const _Hatirlaticilar({required this.depo, required this.profil});

  final HatirlaticiDeposu depo;
  final Profil? profil;

  bool get _kademeVar => profil?.statu == Statu.memur657 && profil?.kademeTarihi != null;

  Future<void> _degistir(BuildContext context, bool ac) async {
    final messenger = ScaffoldMessenger.of(context);
    final tamam = await depo.kademeAyarla(ac, profil);
    if (tamam) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Bildirim izni verilmedi. İstersen telefonun ayarlarından izin verebilirsin.',
          style: PusulaYazi.metin(14, renk: PusulaRenk.beyaz, agirlik: FontWeight.w600),
        ),
        backgroundColor: PusulaRenk.lacivert,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: depo,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Baslik('Hatırlatıcılar'),
        PusulaKart(
          radius: 22,
          padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
          child: Semantics(
            container: true,
            toggled: depo.kademeAcik,
            label: 'Kademe hatırlatıcısı',
            child: Row(
              children: [
                const Icon(LucideIcons.bellRing, size: 20, color: PusulaRenk.lacivert),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kademe hatırlatıcısı', style: PusulaYazi.metin(15, agirlik: FontWeight.w700)),
                      Text(
                        '1 hafta önce ve süre dolduğu gün',
                        style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: depo.kademeAcik,
                  activeThumbColor: PusulaRenk.lacivert,
                  activeTrackColor: PusulaRenk.amber,
                  onChanged: (v) => _degistir(context, v),
                ),
              ],
            ),
          ),
        ),
        if (depo.kademeAcik && !_kademeVar) ...[
          const SizedBox(height: 8),
          const _Bilgi('Bildirim kurulması için Profil sayfasından kademeye geliş tarihini girmelisin.'),
        ],
      ],
    ),
  );
}

/// Yeni kamu ilanı bildirimi: anahtar ve hangi ilan türleri için bildirim gösterileceği.
class _YeniIlanBildirimi extends StatelessWidget {
  const _YeniIlanBildirimi({required this.takip, required this.statu});

  final YeniIlanTakibi takip;
  final Statu? statu;

  Future<void> _degistir(BuildContext context, bool ac) async {
    final messenger = ScaffoldMessenger.of(context);
    final tamam = await takip.ayarla(ac, statu: statu);
    if (tamam) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Bildirim izni verilmedi. İstersen telefonun ayarlarından izin verebilirsin.',
          style: PusulaYazi.metin(14, renk: PusulaRenk.beyaz, agirlik: FontWeight.w600),
        ),
        backgroundColor: PusulaRenk.lacivert,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: takip,
    builder: (context, _) {
      final tercih = takip.tercih;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PusulaKart(
            radius: 22,
            padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
            child: Semantics(
              container: true,
              toggled: tercih.acik,
              label: 'Yeni ilan bildirimi',
              child: Row(
                children: [
                  const Icon(LucideIcons.briefcase, size: 20, color: PusulaRenk.lacivert),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Yeni ilan bildirimi', style: PusulaYazi.metin(15, agirlik: FontWeight.w700)),
                        Text(
                          'Kamu işe alım ilanları yayımlanınca haber ver',
                          style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: tercih.acik,
                    activeThumbColor: PusulaRenk.lacivert,
                    activeTrackColor: PusulaRenk.amber,
                    onChanged: (v) => _degistir(context, v),
                  ),
                ],
              ),
            ),
          ),
          if (tercih.acik) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in IlanTuru.values)
                  FilterChip(
                    label: Text(t.etiket, style: PusulaYazi.metin(13, agirlik: FontWeight.w700)),
                    selected: tercih.turler.contains(t),
                    onSelected: (v) => takip.turAyarla(t, v),
                    selectedColor: PusulaRenk.amber,
                    checkmarkColor: PusulaRenk.lacivert,
                    backgroundColor: PusulaRenk.beyaz,
                    side: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const _Bilgi(
              'Uygulamayı açtığında, ön plana getirdiğinde ve açıkken 15 dakikada bir yeni ilanlara bakılır. '
              'Uygulama kapalıyken bildirim gelmez. Kaynak: Kariyer Kapısı (kariyerkapisi.gov.tr).',
            ),
          ],
        ],
      );
    },
  );
}
