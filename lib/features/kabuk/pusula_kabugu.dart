import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/alt_cubuk.dart';
import '../ana_sayfa/ana_sayfa.dart';
import '../ana_sayfa/ana_sayfa_verisi.dart';
import '../asistan/asistan_servisi.dart';
import '../asistan/asistan_sayfasi.dart';
import '../becayis/data/becayis_deposu.dart';
import '../becayis/data/ornek_veri.dart';
import '../becayis/domain/eslesme.dart';
import '../becayis/presentation/becayis_sekmesi.dart';
import '../haberler/gundem_bolumu.dart';
import '../haberler/haber_kaynagi.dart';
import '../ilanlar/ilan_kaynagi.dart';
import '../ilanlar/ilanlar_sayfasi.dart';
import '../maas/domain/memur_maas_hesaplayici.dart';
import '../maas/presentation/maas_sayfasi.dart';
import '../hesap/data/oturum_deposu.dart';
import '../profil/data/fotograf_deposu.dart';
import '../profil/data/profil_deposu.dart';
import '../profil/domain/profil.dart';
import '../profil/presentation/profil_sayfasi.dart';

/// Uygulama kabuğu: beş sekme ve yüzen alt çubuk. Sekmeler değişince durumları
/// korunur ([IndexedStack]). Ana sayfa, maaş ve becayiş kullanıcının profilinden beslenir.
class PusulaKabugu extends StatefulWidget {
  const PusulaKabugu({
    super.key,
    required this.profilDeposu,
    this.becayisDeposuUret = BecayisOrnekVeri.depoProfilden,
    this.asistan = const SahteAsistan(),
    this.ilanKaynagi = const OrnekIlanKaynagi(),
    this.haberKaynagi = const OrnekHaberKaynagi(),
    this.bugun,
    this.baslangicSekmesi = 0,
    this.fotograf,
    this.fotografKaynagi = const ImagePickerFotografKaynagi(),
    this.oturum,
  });

  final ProfilDeposu profilDeposu;

  /// Profilden becayiş deposu kurar; profil bilgileri değişince yeniden çağrılır.
  final BecayisDeposu Function(Profil) becayisDeposuUret;
  final MevzuatAsistani asistan;
  final IlanKaynagi ilanKaynagi;
  final HaberKaynagi haberKaynagi;
  final DateTime? bugun;
  final int baslangicSekmesi;

  /// Profil fotoğrafı ve hesap işlemleri; verilmezse ilgili bölümler görünmez.
  final FotografDeposu? fotograf;
  final FotografKaynagi fotografKaynagi;
  final OturumDeposu? oturum;

  /// Sekme sırası; kısayollar bu sabitlerle yönlendirir.
  static const anaSayfa = 0;
  static const maas = 1;
  static const asistanSekmesi = 2;
  static const becayis = 3;
  static const ilanlar = 4;

  @override
  State<PusulaKabugu> createState() => _PusulaKabuguState();
}

class _PusulaKabuguState extends State<PusulaKabugu> {
  static const _sekmeler = [
    AltSekme(etiket: 'Ana sayfa', ikon: LucideIcons.house),
    AltSekme(etiket: 'Maaş', ikon: LucideIcons.calculator),
    AltSekme(etiket: 'Asistan', ikon: LucideIcons.sparkles),
    AltSekme(etiket: 'Becayiş', ikon: LucideIcons.arrowRightLeft),
    AltSekme(etiket: 'İlanlar', ikon: LucideIcons.briefcase),
  ];

  late int _secili = widget.baslangicSekmesi;
  late BecayisDeposu _becayis;
  late String _anahtar;

  Profil get _profil => widget.profilDeposu.profil!;

  /// Becayiş ilanını etkileyen alanlar değişince depo yeniden kurulur.
  static String _becayisAnahtari(Profil p) =>
      [p.ad, p.kurumAdi, p.sinif, p.unvan, p.il, p.sicilNo, p.kurumsalEposta].join('|');

  @override
  void initState() {
    super.initState();
    _becayis = widget.becayisDeposuUret(_profil);
    _anahtar = _becayisAnahtari(_profil);
    widget.profilDeposu.addListener(_profilDegisti);
  }

  @override
  void dispose() {
    widget.profilDeposu.removeListener(_profilDegisti);
    _becayis.dispose();
    super.dispose();
  }

  void _profilDegisti() {
    final p = widget.profilDeposu.profil;
    if (p == null || !mounted) return;
    final yeni = _becayisAnahtari(p);
    if (yeni != _anahtar) {
      final eski = _becayis;
      setState(() {
        _becayis = widget.becayisDeposuUret(p);
        _anahtar = yeni;
      });
      eski.dispose();
    }
  }

  void _git(int i) => setState(() => _secili = i);

  void _profilAc() => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProfilSayfasi(
            depo: widget.profilDeposu,
            fotograf: widget.fotograf,
            fotografKaynagi: widget.fotografKaynagi,
            oturum: widget.oturum,
          ),
        ),
      );

  /// Zincirler ayrı sayıldığı için ana sayfada yalnızca ikili eşleşmeler görünür.
  int get _ikiliSayisi => _becayis.eslesmeler.where((e) => e.tip == EslesmeTipi.ikili).length;

  String _becayisAlt(Profil p) {
    if (p.becayisKapaliNedeni != null) return 'Yalnızca memurlar';
    if (p.eksikBecayisAlanlari.isNotEmpty) return 'Profilini tamamla';
    if (!_becayis.yayinda) return 'İlan ver';
    final n = _ikiliSayisi;
    return n > 0 ? '$n eşleşme' : 'Eşleşme bekleniyor';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(
          index: _secili,
          children: [
            ListenableBuilder(
              listenable:
                  Listenable.merge([widget.profilDeposu, _becayis, if (widget.fotograf != null) widget.fotograf!]),
              builder: (context, _) {
                final p = _profil;
                final yeni = p.becayisYapabilir && p.eksikBecayisAlanlari.isEmpty ? _ikiliSayisi : 0;
                return AnaSayfa(
                  veri: AnaSayfaVerisi.profilden(
                    p,
                    bugun: widget.bugun ?? DateTime.now(),
                    becayisAlt: _becayisAlt(p),
                    bildirimVar: yeni > 0,
                  ),
                  bugun: widget.bugun,
                  maasaGit: () => _git(PusulaKabugu.maas),
                  asistanaGit: () => _git(PusulaKabugu.asistanSekmesi),
                  becayisiAc: () => _git(PusulaKabugu.becayis),
                  profilAc: _profilAc,
                  avatarFoto: widget.fotograf?.foto,
                  avatarAd: p.ad,
                  gundem: GundemBolumu(kaynak: widget.haberKaynagi, bugun: widget.bugun),
                );
              },
            ),
            ListenableBuilder(
              listenable: widget.profilDeposu,
              builder: (context, _) {
                final p = _profil;
                return MaasSayfasi(
                  ay: widget.bugun?.month,
                  baslangic: p.maas ?? const MaasGirdisi(derece: 8, kademe: 3, hizmetYili: 10),
                  kayitliGirdi: p.maas,
                  kaydet: p.statu == Statu.memur657 ? (g) => widget.profilDeposu.kaydet(p.kopya(maas: g)) : null,
                );
              },
            ),
            AsistanSayfasi(asistan: widget.asistan),
            ListenableBuilder(
              listenable: widget.profilDeposu,
              builder: (context, _) => BecayisSekmesi(profil: _profil, depo: _becayis, profilAc: _profilAc),
            ),
            IlanlarSayfasi(kaynak: widget.ilanKaynagi, bugun: widget.bugun),
          ],
        ),
        bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
            ? null
            : PusulaAltCubuk(sekmeler: _sekmeler, secili: _secili, onSec: _git),
      );
}
