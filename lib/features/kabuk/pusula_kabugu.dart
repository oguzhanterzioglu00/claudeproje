import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/alt_cubuk.dart';
import '../../core/bilesenler.dart';
import '../ana_sayfa/ana_sayfa.dart';
import '../ana_sayfa/ana_sayfa_verisi.dart';
import '../ana_sayfa/bildirimler.dart';
import '../araclar/presentation/araclar_bolumu.dart';
import '../araclar/presentation/derece_tablosu_sayfasi.dart';
import '../araclar/presentation/izin_sayfasi.dart';
import '../araclar/presentation/zam_sayfasi.dart';
import '../asistan/asistan_servisi.dart';
import '../asistan/asistan_sayfasi.dart';
import '../asistan/bilgi_bankasi.dart';
import '../becayis/data/becayis_deposu.dart';
import '../becayis/data/ornek_veri.dart';
import '../becayis/domain/eslesme.dart';
import '../becayis/presentation/becayis_sekmesi.dart';
import '../haberler/gundem_bolumu.dart';
import '../haberler/haber_kaynagi.dart';
import '../haberler/haber_modeli.dart';
import '../ilanlar/ilan_kaynagi.dart';
import '../ilanlar/ilanlar_bolumu.dart';
import '../ilanlar/ilanlar_sayfasi.dart';
import '../ilanlar/kayitli_ilanlar.dart';
import '../ilanlar/yeni_ilan_takibi.dart';
import '../maas/domain/memur_maas_hesaplayici.dart';
import '../maas/presentation/maas_sayfasi.dart';
import '../hatirlatici/hatirlatici_deposu.dart';
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
    this.asistan = const YerelMevzuatAsistani(),
    this.ilanKaynagi = const OrnekIlanKaynagi(),
    this.haberKaynagi = const OrnekHaberKaynagi(),
    this.haberOtomatik = true,
    this.bugun,
    this.baslangicSekmesi = 0,
    this.fotograf,
    this.fotografKaynagi = const ImagePickerFotografKaynagi(),
    this.oturum,
    this.hatirlatici,
    this.ilanTakibi,
    this.kayitliIlanlar,
  });

  final ProfilDeposu profilDeposu;

  /// Profilden becayiş deposu kurar; profil bilgileri değişince yeniden çağrılır.
  final BecayisDeposu Function(Profil) becayisDeposuUret;
  final MevzuatAsistani asistan;
  final IlanKaynagi ilanKaynagi;
  final HaberKaynagi haberKaynagi;

  /// Haber slaytlarının kendiliğinden ilerlemesi (testlerde kapatılır).
  final bool haberOtomatik;
  final DateTime? bugun;
  final int baslangicSekmesi;

  /// Profil fotoğrafı ve hesap işlemleri; verilmezse ilgili bölümler görünmez.
  final FotografDeposu? fotograf;
  final FotografKaynagi fotografKaynagi;
  final OturumDeposu? oturum;

  /// Verilirse ayarlarda hatırlatıcı tercihleri görünür ve profile göre bildirimler kurulur.
  final HatirlaticiDeposu? hatirlatici;

  /// Verilirse yeni ilan bildirimi (ayarlarda açılır) çalışır: uygulama açılınca, ön plana gelince ve
  /// açıkken 15 dakikada bir ilan akışı kontrol edilir.
  final YeniIlanTakibi? ilanTakibi;

  /// Kaydedilen ilanlar (cihazda kalıcı); verilmezse İlanlar sekmesi bellekte tutar.
  final KayitliIlanlar? kayitliIlanlar;

  /// Sekme sırası; kısayollar bu sabitlerle yönlendirir.
  static const anaSayfa = 0;
  static const maas = 1;
  static const asistanSekmesi = 2;
  static const becayis = 3;
  static const ilanlar = 4;

  @override
  State<PusulaKabugu> createState() => _PusulaKabuguState();
}

class _PusulaKabuguState extends State<PusulaKabugu> with WidgetsBindingObserver {
  Timer? _ilanZamanlayici;

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
    widget.hatirlatici?.yukle().then((_) => widget.hatirlatici?.esitle(widget.profilDeposu.profil));
    if (widget.ilanTakibi != null) {
      WidgetsBinding.instance.addObserver(this);
      widget.ilanTakibi!.yukle().then((_) {
        _ilanlariKontrolEt();
        unawaited(widget.ilanTakibi?.arkaPlaniSenkronla());
      });
      _ilanZamanlayici = Timer.periodic(const Duration(minutes: 15), (_) => _ilanlariKontrolEt());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState durum) {
    if (durum == AppLifecycleState.resumed) _ilanlariKontrolEt();
  }

  void _ilanlariKontrolEt() {
    final takip = widget.ilanTakibi;
    if (takip != null) unawaited(takip.kontrolEt());
  }

  @override
  void dispose() {
    _ilanZamanlayici?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.profilDeposu.removeListener(_profilDegisti);
    _becayis.dispose();
    super.dispose();
  }

  void _profilDegisti() {
    final p = widget.profilDeposu.profil;
    if (p == null || !mounted) return;
    widget.hatirlatici?.esitle(p);
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
        hatirlatici: widget.hatirlatici,
        ilanTakibi: widget.ilanTakibi,
        kayitliIlanlar: widget.kayitliIlanlar,
      ),
    ),
  );

  /// Zincirler ayrı sayıldığı için ana sayfada yalnızca ikili eşleşmeler görünür.
  int get _ikiliSayisi => _becayis.eslesmeler.where((e) => e.tip == EslesmeTipi.ikili).length;

  static const _ornekMaas = MaasGirdisi(derece: 8, kademe: 3, hizmetYili: 10);

  void _sayfaAc(Widget sayfa) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => sayfa));

  void _izinAc() => _sayfaAc(IzinSayfasi(baslangicHizmetYili: _profil.maas?.hizmetYili ?? 5));

  void _zamAc() => _sayfaAc(ZamSayfasi(girdi: _profil.maas ?? _ornekMaas, profildenMi: _profil.maas != null));

  void _tabloAc() => _sayfaAc(DereceTablosuSayfasi(derece: _profil.maas?.derece ?? 8, kademe: _profil.maas?.kademe));

  List<Bildirim> _bildirimler(Profil p) =>
      bildirimleriUret(p, becayisYayinda: _becayis.yayinda, ikiliEslesme: _ikiliSayisi);

  Future<void> _bildirimleriAc() async {
    final secilen = await AltSayfa.goster<Bildirim>(
      context,
      builder: (c) => BildirimListesi(bildirimler: _bildirimler(_profil), onSec: (b) => Navigator.pop(c, b)),
    );
    if (secilen == null || !mounted) return;
    switch (secilen.hedef) {
      case BildirimHedefi.profil:
        _profilAc();
      case BildirimHedefi.maas:
        _git(PusulaKabugu.maas);
      case BildirimHedefi.becayis:
        _git(PusulaKabugu.becayis);
    }
  }

  /// Asistanın kullanıcıya uygun mevzuatı seçmesi için çalışan grubu; diğer statülerde (akademik vb.) belirsizdir.
  static Kitle? _kitle(Statu s) => switch (s) {
    Statu.memur657 => Kitle.memur,
    Statu.isci => Kitle.isci,
    Statu.sozlesmeli => Kitle.sozlesmeli,
    _ => null,
  };

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
          listenable: Listenable.merge([widget.profilDeposu, _becayis, if (widget.fotograf != null) widget.fotograf!]),
          builder: (context, _) {
            final p = _profil;
            return AnaSayfa(
              veri: AnaSayfaVerisi.profilden(
                p,
                bugun: widget.bugun ?? DateTime.now(),
                becayisAlt: _becayisAlt(p),
                bildirimVar: _bildirimler(p).isNotEmpty,
              ),
              bugun: widget.bugun,
              bildirimAc: _bildirimleriAc,
              maasaGit: () => _git(PusulaKabugu.maas),
              asistanaGit: () => _git(PusulaKabugu.asistanSekmesi),
              becayisiAc: () => _git(PusulaKabugu.becayis),
              profilAc: _profilAc,
              avatarFoto: widget.fotograf?.foto,
              avatarAd: p.ad,
              araclar: p.statu == Statu.memur657
                  ? AraclarBolumu(izinAc: _izinAc, zamAc: _zamAc, tabloAc: _tabloAc)
                  : null,
              ilanlar: widget.ilanKaynagi is OrnekIlanKaynagi
                  ? null
                  : IlanlarBolumu(
                      kaynak: widget.ilanKaynagi,
                      turler: IlanBildirimTercihi.varsayilan(p.statu),
                      tumunuAc: () => _git(PusulaKabugu.ilanlar),
                      bugun: widget.bugun,
                    ),
              gundem: GundemBolumu(kaynak: widget.haberKaynagi, bugun: widget.bugun, otomatik: widget.haberOtomatik),
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
              baslangicGrup: switch (p.statu) {
                Statu.sozlesmeli => 1,
                Statu.isci => 2,
                _ => 0,
              },
              kayitliBrut: p.brutUcret,
              kaydetBrut: p.statu.brutUcretliMi ? (b) => widget.profilDeposu.kaydet(p.kopya(brutUcret: b)) : null,
              haberler: GundemBolumu(
                kaynak: widget.haberKaynagi,
                bugun: widget.bugun,
                baslik: 'Maaş ve mevzuat haberleri',
                turler: const {HaberTuru.maas, HaberTuru.mevzuat},
                otomatik: widget.haberOtomatik,
              ),
              kaydet: p.statu == Statu.memur657 ? (g) => widget.profilDeposu.kaydet(p.kopya(maas: g)) : null,
            );
          },
        ),
        ListenableBuilder(
          listenable: widget.profilDeposu,
          builder: (context, _) => AsistanSayfasi(asistan: widget.asistan, kitle: _kitle(_profil.statu)),
        ),
        ListenableBuilder(
          listenable: widget.profilDeposu,
          builder: (context, _) => BecayisSekmesi(profil: _profil, depo: _becayis, profilAc: _profilAc),
        ),
        IlanlarSayfasi(kaynak: widget.ilanKaynagi, bugun: widget.bugun, kayitlar: widget.kayitliIlanlar),
      ],
    ),
    bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
        ? null
        : PusulaAltCubuk(sekmeler: _sekmeler, secili: _secili, onSec: _git),
  );
}
