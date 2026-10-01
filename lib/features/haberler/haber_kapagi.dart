import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/hareket.dart';
import '../../core/tema.dart';
import '../../core/ucgenler.dart';
import 'haber_modeli.dart';

/// Haber illüstrasyonunun türü. Her tür, aynı `viewBox`taki üç SVG katmanından (zemin, orta, ön)
/// oluşur: `assets/gorsel/haber/<ad>_zemin|orta|on.svg`.
enum HaberGorselTuru {
  mevzuat,
  maas,
  duyuru,
  atama,

  /// Resmî Gazete'nin günlük sayı özeti.
  gazete;

  static final _gunlukSayi = RegExp(r'^rg-\d{8}$');

  static HaberGorselTuru sec(Haber h) {
    if (h.kaynakAdi == 'Resmî Gazete' && _gunlukSayi.hasMatch(h.id)) return gazete;
    return switch (h.tur) {
      HaberTuru.mevzuat => mevzuat,
      HaberTuru.maas => maas,
      HaberTuru.duyuru => duyuru,
      HaberTuru.atama => atama,
    };
  }

  String get _ad => name;
  String get zemin => 'assets/gorsel/haber/${_ad}_zemin.svg';
  String get orta => 'assets/gorsel/haber/${_ad}_orta.svg';
  String get on => 'assets/gorsel/haber/${_ad}_on.svg';

  /// Ekran okuyucu için kısa açıklama.
  String get aciklama => switch (this) {
    mevzuat => 'Kanun kitabı ve adalet terazisi çizimi',
    maas => 'Maaş bordrosu ve madeni paralar çizimi',
    duyuru => 'Megafon ve bildirim balonları çizimi',
    atama => 'Kimlik kartı ve onay işareti çizimi',
    gazete => 'Gazete ve takvim çizimi',
  };

  /// Katmanlar: arkadan öne. Arka katman yavaş "nefes alır", ortadaki yumuşakça süzülür,
  /// öndeki daha hızlı ve geniş salınır.
  List<GorselKatmani> get katmanlar => [
    GorselKatmani(zemin, nefes: 0.035, hiz: 1, derinlik: 0.3),
    GorselKatmani(orta, suzulme: 4, hiz: 2, faz: 0.25, derinlik: 0.7),
    GorselKatmani(on, suzulme: 7, donme: 0.03, hiz: 3, faz: 0.5, derinlik: 1.2),
  ];
}

/// Haberin tür simgesi ve rengi; liste kartları ve slaytlar ortak kullanır.
abstract final class HaberGorunumu {
  static IconData ikon(HaberTuru t) => switch (t) {
    HaberTuru.mevzuat => LucideIcons.scale,
    HaberTuru.maas => LucideIcons.banknote,
    HaberTuru.duyuru => LucideIcons.megaphone,
    HaberTuru.atama => LucideIcons.userCheck,
  };

  static Color renk(HaberTuru t) => switch (t) {
    HaberTuru.mevzuat => PusulaRenk.mor,
    HaberTuru.maas => PusulaRenk.amber,
    HaberTuru.duyuru => PusulaRenk.mavi,
    HaberTuru.atama => PusulaRenk.turkuaz,
  };

  static Color ikonRengi(HaberTuru t) => switch (t) {
    HaberTuru.mevzuat || HaberTuru.duyuru => PusulaRenk.beyaz,
    HaberTuru.maas || HaberTuru.atama => PusulaRenk.lacivert,
  };

  /// Kapak çiziminin koyu degrade renkleri (üzerine beyaz yazı okunur).
  static (Color, Color) degrade(HaberTuru t) => switch (t) {
    HaberTuru.mevzuat => (PusulaRenk.mor, PusulaRenk.lacivert),
    HaberTuru.maas => (PusulaRenk.mavi, PusulaRenk.lacivert),
    HaberTuru.duyuru => (PusulaRenk.lacivert, PusulaRenk.mavi),
    HaberTuru.atama => (const Color(0xFF0E7C93), PusulaRenk.lacivert),
  };
}

/// Haberin kapak görseli: [Haber.gorsel] varsa ağdan yüklenir; yoksa, yüklenirken
/// ya da hata olursa türe göre çizilmiş kapak gösterilir (uygulama görselsiz de güzel görünür).
class HaberKapagi extends StatelessWidget {
  const HaberKapagi({super.key, required this.haber, this.kaydirma, this.yaziAlanli = false});

  final Haber haber;

  /// Kapağın üstünde etiketler, altında başlık yazısı varsa (slayt) çizim ikisinin arasındaki boşluğa sığdırılır.
  /// Yazısız kapakta (haber ayrıntısı) çizim alanı doldurur.
  final bool yaziAlanli;

  /// Slayt paralaksı için (−1..1); verilmezse katmanlar yalnızca kendi ritminde hareket eder.
  final ValueListenable<double>? kaydirma;

  @override
  Widget build(BuildContext context) {
    final cizim = _CizimKapak(haber: haber, kaydirma: kaydirma, yaziAlanli: yaziAlanli);
    final adres = haber.gorsel;
    if (adres == null) return cizim;
    return Stack(
      fit: StackFit.expand,
      children: [
        cizim,
        Image.network(
          adres.toString(),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          excludeFromSemantics: true,
          errorBuilder: (context, hata, iz) => const SizedBox.shrink(),
          frameBuilder: (context, child, kare, senkron) => AnimatedOpacity(
            opacity: kare == null ? 0 : 1,
            duration: const Duration(milliseconds: 400),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _CizimKapak extends StatelessWidget {
  const _CizimKapak({required this.haber, this.kaydirma, this.yaziAlanli = false});

  final Haber haber;
  final bool yaziAlanli;
  final ValueListenable<double>? kaydirma;

  @override
  Widget build(BuildContext context) {
    final (a, b) = HaberGorunumu.degrade(haber.tur);
    final gorsel = HaberGorselTuru.sec(haber);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [a, b]),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            right: -40,
            top: -30,
            child: Opacity(
              opacity: 0.12,
              child: PusulaUcgenler(boyut: 210, orta: PusulaRenk.beyaz),
            ),
          ),
          // Çizim üst-sağda durur; başlık ve etiketler alttan yukarı doğru okunur.
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, kisit) {
                // Yazılı kapakta üst şerit etiketlere, alt kısım başlığa ayrılır; çizim aradaki boşluğa oturur.
                final yukseklik = yaziAlanli
                    ? (kisit.maxHeight * 0.44).clamp(0.0, 120.0)
                    : (kisit.maxHeight * 0.82).clamp(0.0, 190.0);
                return Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(top: yaziAlanli ? 40 : 6, right: 4),
                    child: SizedBox(
                      height: yukseklik,
                      child: HareketliGorsel(
                        katmanlar: gorsel.katmanlar,
                        kaydirma: kaydirma,
                        anlamEtiketi: gorsel.aciklama,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Liste satırı için küçük, durağan görsel: türün renk geçişi üzerinde illüstrasyonun orta katmanı.
class HaberKucukGorsel extends StatelessWidget {
  const HaberKucukGorsel({super.key, required this.haber, this.boyut = 64});

  final Haber haber;
  final double boyut;

  @override
  Widget build(BuildContext context) {
    final (a, b) = HaberGorunumu.degrade(haber.tur);
    final gorsel = HaberGorselTuru.sec(haber);
    return Container(
      width: boyut,
      height: boyut,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [a, b]),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Orta katmanın kenar boşluğu büyük; kırparak kadrajı doldurur.
          Transform.scale(
            scale: 1.5,
            child: ExcludeSemantics(child: SvgPicture.asset(gorsel.orta, fit: BoxFit.contain)),
          ),
        ],
      ),
    );
  }
}
