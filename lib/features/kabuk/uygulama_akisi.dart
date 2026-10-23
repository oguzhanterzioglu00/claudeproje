import 'package:flutter/material.dart';

import '../../core/depolama.dart';
import '../../core/logo.dart';
import '../../core/tema.dart';
import '../becayis/data/becayis_deposu.dart';
import '../haberler/haber_kaynagi.dart';
import '../haberler/yeni_haber_takibi.dart';
import '../hatirlatici/hatirlatici_deposu.dart';
import '../ilanlar/arka_plan.dart';
import '../ilanlar/kayitli_ilanlar.dart';
import '../ilanlar/ilan_alarmi.dart';
import '../ilanlar/ilan_kaynagi.dart';
import '../ilanlar/yeni_ilan_takibi.dart';
import '../hatirlatici/hatirlatici_servisi.dart';
import '../hesap/data/oturum_deposu.dart';
import '../hesap/domain/hesap.dart';
import '../hesap/presentation/giris_sayfasi.dart';
import '../hesap/presentation/yeni_sifre_sayfasi.dart';
import '../profil/data/fotograf_deposu.dart';
import '../profil/data/profil_deposu.dart';
import '../profil/data/profil_kaydi.dart';
import '../profil/domain/profil.dart';
import '../profil/presentation/hazirlaniyor_sayfasi.dart';
import '../profil/presentation/ilk_kurulum_sayfasi.dart';
import '../profil/presentation/karsilama_sayfasi.dart';
import 'pusula_kabugu.dart';

/// Bir hesaba ait cihaz içi kullanıcı verisi (profil ve fotoğraf).
class _KullaniciVerisi {
  _KullaniciVerisi(
    this.hesapId,
    this.profil,
    this.fotograf,
    this.hatirlatici,
    this.ilanTakibi,
    this.kayitliIlanlar,
    this.ilanAlarmlari,
    this.haberTakibi,
  );

  final String hesapId;
  final ProfilDeposu profil;
  final FotografDeposu fotograf;
  final HatirlaticiDeposu? hatirlatici;
  final YeniIlanTakibi? ilanTakibi;
  final KayitliIlanlar kayitliIlanlar;
  final IlanAlarmlari ilanAlarmlari;
  final YeniHaberTakibi? haberTakibi;

  bool get yuklendi => profil.yuklendi && fotograf.yuklendi;

  void dispose() {
    profil.dispose();
    fotograf.dispose();
    hatirlatici?.dispose();
    ilanTakibi?.dispose();
    kayitliIlanlar.dispose();
    ilanAlarmlari.dispose();
    haberTakibi?.dispose();
  }
}

/// Uygulamanın giriş akışı:
/// tanıtım (yalnızca ilk kez) → giriş/kayıt → profil kurulumu → "hazırlanıyor" → ana kabuk.
/// Oturum kapanınca giriş ekranına, hesap değişince o hesabın verisine geçilir.
class UygulamaAkisi extends StatefulWidget {
  const UygulamaAkisi({
    super.key,
    required this.oturum,
    required this.depolama,
    required this.profilKaydiUret,
    required this.fotografKaynagi,
    this.appleGoster = true,
    this.sosyalGiris = true,
    this.becayisAcik = true,
    this.becayisDeposuUret,
    this.kabukUret,
    this.hatirlatici,
    this.ilanKaynagi,
    this.haberKaynagi,
    this.arkaPlan,
  });

  final OturumDeposu oturum;
  final AnahtarDeger depolama;

  /// Hesap kimliğinden o hesabın profil kaydını üretir.
  final ProfilKaydi Function(String hesapId) profilKaydiUret;
  final FotografKaynagi fotografKaynagi;
  final bool appleGoster;

  /// Google/Apple giriş düğmeleri (gerçek giriş bağlanana kadar mağaza sürümünde kapalı).
  final bool sosyalGiris;

  /// Becayiş eşleştirme (arka uç ve ödeme bağlanana kadar mağaza sürümünde kapalı; "Yakında" gösterilir).
  final bool becayisAcik;
  final BecayisDeposu Function(Profil)? becayisDeposuUret;

  /// Verilirse kullanıcı hatırlatıcıları (kademe vb.) ayarlardan açabilir.
  final HatirlaticiServisi? hatirlatici;

  /// Boşsa kabuğun varsayılan (örnek) kaynakları kullanılır; uygulamada gerçek akış kaynakları verilir.
  final IlanKaynagi? ilanKaynagi;
  final HaberKaynagi? haberKaynagi;

  /// Uygulama kapalıyken yeni ilan kontrolü (Android); boşsa yalnızca uygulama açıkken kontrol edilir.
  final ArkaPlanZamanlayici? arkaPlan;

  /// Ana kabuğu üretir; testlerde örnek servislerle değiştirilebilir.
  final Widget Function(
    BuildContext context,
    ProfilDeposu profil,
    FotografDeposu fotograf,
  )?
  kabukUret;

  static const tanitimAnahtari = 'tanitim_goruldu_v1';

  /// Kullanıcı hesap açmadan devam etmeyi seçtiyse '1' (App Store 5.1.1(v): hesap zorunlu değildir).
  static const misafirAnahtari = 'misafir_modu_v1';

  /// Hesapsız kullanımda verilerin cihazda tutulduğu sabit kimlik.
  static const misafirHesap = Hesap(id: 'misafir', saglayici: GirisSaglayici.eposta);

  @override
  State<UygulamaAkisi> createState() => _UygulamaAkisiState();
}

class _UygulamaAkisiState extends State<UygulamaAkisi> {
  bool? _tanitimGoruldu;
  bool _misafir = false;
  _KullaniciVerisi? _veri;

  /// Gerçek hesap yoksa ve kullanıcı hesapsız devam ettiyse yerel misafir hesabı geçerlidir.
  Hesap? get _etkinHesap => widget.oturum.hesap ?? (_misafir ? UygulamaAkisi.misafirHesap : null);

  /// Bu oturumda kurulum ekranı gösterildiyse, bitince "hazırlanıyor" akışı da gösterilir.
  bool _kurulumGoruldu = false;
  bool _hazirlandi = false;

  @override
  void initState() {
    super.initState();
    widget.oturum.addListener(_oturumDegisti);
    _tanitimOku();
    _oturumDegisti();
  }

  @override
  void dispose() {
    widget.oturum.removeListener(_oturumDegisti);
    _veri?.dispose();
    super.dispose();
  }

  Future<void> _tanitimOku() async {
    final deger = await widget.depolama.oku(UygulamaAkisi.tanitimAnahtari);
    final misafir = await widget.depolama.oku(UygulamaAkisi.misafirAnahtari);
    if (!mounted) return;
    _misafir = misafir == '1';
    setState(() => _tanitimGoruldu = deger == '1');
    _oturumDegisti();
  }

  /// "Hesap açmadan devam et": giriş ekranı atlanır, veriler yalnızca bu cihazda tutulur.
  Future<void> _misafirBaslat() async {
    setState(() => _misafir = true);
    _oturumDegisti();
    await widget.depolama.yaz(UygulamaAkisi.misafirAnahtari, '1');
  }

  /// Profilden "Giriş yap / hesap oluştur": giriş ekranı açılır, oturum açılınca kapanır.
  void _girisAc() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _GirisRotasi(
          oturum: widget.oturum,
          appleGoster: widget.appleGoster,
          sosyalGiris: widget.sosyalGiris || widget.oturum.gercek,
        ),
      ),
    );
  }

  Future<void> _tanitimBitti() async {
    setState(() => _tanitimGoruldu = true);
    await widget.depolama.yaz(UygulamaAkisi.tanitimAnahtari, '1');
  }

  /// Oturumdaki hesap değişince kullanıcı verisi o hesaba göre yeniden kurulur.
  void _oturumDegisti() {
    final Hesap? hesap = _etkinHesap;
    if (hesap?.id == _veri?.hesapId) return;
    // Hesap değişince/çıkılınca eski hesabın bildirimleri bu cihazdan kaldırılır.
    _veri?.hatirlatici?.hepsiniIptal();
    _veri?.ilanTakibi?.oturumKapandi();
    _veri?.haberTakibi?.oturumKapandi();
    _veri?.dispose();
    _veri = null;
    _kurulumGoruldu = false;
    _hazirlandi = false;
    if (hesap != null) {
      final v = _KullaniciVerisi(
        hesap.id,
        ProfilDeposu(widget.profilKaydiUret(hesap.id)),
        FotografDeposu(widget.depolama, anahtar: 'profil_foto_v1_${hesap.id}'),
        widget.hatirlatici == null
            ? null
            : HatirlaticiDeposu(
                widget.hatirlatici!,
                widget.depolama,
                hesapId: hesap.id,
              ),
        widget.hatirlatici == null || widget.ilanKaynagi == null
            ? null
            : YeniIlanTakibi(
                kaynak: widget.ilanKaynagi!,
                servis: widget.hatirlatici!,
                depolama: widget.depolama,
                hesapId: hesap.id,
                arkaPlan: widget.arkaPlan,
              ),
        KayitliIlanlar(widget.depolama, hesapId: hesap.id),
        IlanAlarmlari(widget.depolama, hesapId: hesap.id),
        widget.hatirlatici == null || widget.haberKaynagi == null
            ? null
            : YeniHaberTakibi(
                kaynak: widget.haberKaynagi!,
                servis: widget.hatirlatici!,
                depolama: widget.depolama,
                hesapId: hesap.id,
                arkaPlan: widget.arkaPlan,
              ),
      );
      _veri = v;
      v.kayitliIlanlar.yukle();
      v.ilanAlarmlari.yukle();
      v.profil.yukle();
      v.fotograf.yukle();
      v.profil.addListener(_veriDegisti);
      v.fotograf.addListener(_veriDegisti);
    }
    if (mounted) setState(() {});
  }

  void _veriDegisti() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.oturum,
    builder: (context, _) {
      if (!widget.oturum.yuklendi || _tanitimGoruldu == null) {
        return const AcilisEkrani();
      }

      // E-postadaki şifre sıfırlama bağlantısından gelindiyse önce yeni şifre alınır.
      if (widget.oturum.sifreKurtarmaBekliyor) {
        return YeniSifreSayfasi(oturum: widget.oturum);
      }

      final hesap = _etkinHesap;
      if (hesap == null) {
        return _tanitimGoruldu!
            ? GirisSayfasi(
                oturum: widget.oturum,
                appleGoster: widget.appleGoster,
                sosyalGiris: widget.sosyalGiris || widget.oturum.gercek,
                onMisafir: _misafirBaslat,
              )
            : KarsilamaSayfasi(
                onBasla: _tanitimBitti,
                becayisAcik: widget.becayisAcik,
              );
      }

      final veri = _veri;
      if (veri == null || !veri.yuklendi) return const AcilisEkrani();

      if (veri.profil.profil == null) {
        _kurulumGoruldu = true;
        return IlkKurulumSayfasi(
          depo: veri.profil,
          fotograf: veri.fotograf,
          fotografKaynagi: widget.fotografKaynagi,
          ilkAd: hesap.ad,
          adSor: false,
          becayisAdimi: false,
        );
      }

      if (_kurulumGoruldu && !_hazirlandi) {
        return HazirlaniyorSayfasi(
          ad: veri.profil.profil!.ad,
          memur: veri.profil.profil!.statu == Statu.memur657,
          onBitti: () {
            if (mounted) setState(() => _hazirlandi = true);
          },
        );
      }

      return widget.kabukUret != null
          ? widget.kabukUret!(context, veri.profil, veri.fotograf)
          : PusulaKabugu(
              profilDeposu: veri.profil,
              fotograf: veri.fotograf,
              fotografKaynagi: widget.fotografKaynagi,
              oturum: widget.oturum,
              girisAc: _girisAc,
              hatirlatici: veri.hatirlatici,
              ilanTakibi: veri.ilanTakibi,
              kayitliIlanlar: veri.kayitliIlanlar,
              ilanAlarmlari: veri.ilanAlarmlari,
              haberTakibi: veri.haberTakibi,
              becayisAcik: widget.becayisAcik,
              becayisDeposuUret: widget.becayisDeposuUret ?? BecayisDeposu.bos,
              ilanKaynagi: widget.ilanKaynagi ?? const OrnekIlanKaynagi(),
              haberKaynagi: widget.haberKaynagi ?? const OrnekHaberKaynagi(),
            );
    },
  );
}

/// Profilden açılan giriş ekranı; oturum açılınca (kayıt/giriş) tüm ara ekranlar kapanıp ana kabuğa dönülür.
class _GirisRotasi extends StatefulWidget {
  const _GirisRotasi({required this.oturum, required this.appleGoster, required this.sosyalGiris});

  final OturumDeposu oturum;
  final bool appleGoster;
  final bool sosyalGiris;

  @override
  State<_GirisRotasi> createState() => _GirisRotasiState();
}

class _GirisRotasiState extends State<_GirisRotasi> {
  @override
  void initState() {
    super.initState();
    widget.oturum.addListener(_degisti);
  }

  @override
  void dispose() {
    widget.oturum.removeListener(_degisti);
    super.dispose();
  }

  void _degisti() {
    if (widget.oturum.hesap == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) => GirisSayfasi(
    oturum: widget.oturum,
    appleGoster: widget.appleGoster,
    sosyalGiris: widget.sosyalGiris,
    onVazgec: () => Navigator.of(context).pop(),
  );
}

/// Veriler okunurken kısa açılış ekranı (ibresi yerine oturan logo).
class AcilisEkrani extends StatelessWidget {
  const AcilisEkrani({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: PusulaRenk.lacivert,
    body: Center(child: AnimasyonluPusulaLogo(boyut: 132, arkaplan: false)),
  );
}
