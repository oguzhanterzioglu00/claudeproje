import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/avatar.dart';
import '../../../core/bilesenler.dart';
import '../../../core/tema.dart';
import '../../../core/yukselen.dart';
import '../../ayarlar/ayarlar_sayfasi.dart';
import '../../hatirlatici/hatirlatici_deposu.dart';
import '../../haberler/yeni_haber_takibi.dart';
import '../../ilanlar/kayitli_ilanlar.dart';
import '../../ilanlar/yeni_ilan_takibi.dart';
import '../../hesap/data/oturum_deposu.dart';
import '../../hesap/presentation/hesap_bolumu.dart';
import '../data/fotograf_deposu.dart';
import '../data/profil_deposu.dart';
import '../domain/profil.dart';
import 'fotograf_sayfasi.dart';
import 'profil_alanlari.dart';
import 'secim_sayfasi.dart';

/// Profil: statü, görev bilgileri ve (memurlar için) becayiş/dilekçe bilgileri.
/// İlk kurulum için bkz. [IlkKurulumSayfasi].
class ProfilSayfasi extends StatefulWidget {
  const ProfilSayfasi({
    super.key,
    required this.depo,
    this.onBitti,
    this.fotograf,
    this.fotografKaynagi = const ImagePickerFotografKaynagi(),
    this.oturum,
    this.hatirlatici,
        this.ilanTakibi,
        this.kayitliIlanlar,
    this.haberTakibi,
    this.tarihSec = _varsayilanTarihSec,
  });

  final ProfilDeposu depo;

  /// Verilirse profilde fotoğraf değiştirilebilir.
  final FotografDeposu? fotograf;
  final FotografKaynagi fotografKaynagi;

  /// Verilirse "Hesap ve güvenlik" bölümü (şifre, çıkış, hesap silme) görünür.
  final OturumDeposu? oturum;

  /// Verilirse Ayarlar'da hatırlatıcı tercihleri görünür; hesap silinince tercih de silinir.
  final HatirlaticiDeposu? hatirlatici;

  /// Verilirse Ayarlar'da yeni ilan bildirimi tercihleri görünür.
    final YeniIlanTakibi? ilanTakibi;

  /// Verilirse hesap silinirken kaydedilen ilanlar da silinir.
    final KayitliIlanlar? kayitliIlanlar;

  /// Verilirse Ayarlar'da Resmî Gazete bildirimi görünür.
  final YeniHaberTakibi? haberTakibi;



  /// Tarih seçici; testlerde değiştirilir. Vazgeçilirse null döner.
  final Future<DateTime?> Function(BuildContext context, DateTime baslangic, DateTime ilk, DateTime son) tarihSec;

  static Future<DateTime?> _varsayilanTarihSec(BuildContext context, DateTime baslangic, DateTime ilk, DateTime son) =>
      showDatePicker(
          context: context, initialDate: baslangic, firstDate: ilk, lastDate: son, helpText: 'Kademeye geliş tarihi');

  /// Kaydedildikten sonra çağrılır; boşsa sayfa kapanır.
  final VoidCallback? onBitti;

  @override
  State<ProfilSayfasi> createState() => _ProfilSayfasiState();
}

class _ProfilSayfasiState extends State<ProfilSayfasi> {
  late final Profil? _mevcut = widget.depo.profil;

  late final _ad = TextEditingController(text: _mevcut?.ad ?? '');
  late final _unvan = TextEditingController(text: _mevcut?.unvan ?? '');
  late final _sicil = TextEditingController(text: _mevcut?.sicilNo ?? '');
  late final _eposta = TextEditingController(text: _mevcut?.kurumsalEposta ?? '');

  late Statu? _statu = _mevcut?.statu;
  late bool _aday = _mevcut?.adayMemur ?? false;
  late String _kurum = _mevcut?.kurumAdi ?? '';
  late String _sinif = _mevcut?.sinif ?? '';
  late String _il = _mevcut?.il ?? '';
  late DateTime? _kademeTarihi = _mevcut?.kademeTarihi;
  bool _kaydediliyor = false;

  bool get _memur => _statu == Statu.memur657;
  bool get _epostaGecerli => _eposta.text.trim().isEmpty || _eposta.text.contains('@');
  bool get _kaydedilebilir => _ad.text.trim().isNotEmpty && _statu != null && _epostaGecerli;

  @override
  void dispose() {
    _ad.dispose();
    _unvan.dispose();
    _sicil.dispose();
    _eposta.dispose();
    super.dispose();
  }

  Future<void> _sec(String baslik, List<String> secenekler, String secili, ValueChanged<String> yaz,
      {bool serbest = false}) async {
    final s =
        await SecimSayfasi.goster(context, baslik: baslik, secenekler: secenekler, secili: secili, serbest: serbest);
    if (s != null) setState(() => yaz(s));
  }

  static String _tarihMetni(DateTime t) =>
      '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';

  Future<void> _kademeTarihiSec() async {
    final bugun = DateTime.now();
    final t = await widget.tarihSec(context, _kademeTarihi ?? bugun, DateTime(bugun.year - 45), bugun);
    if (t != null && mounted) setState(() => _kademeTarihi = DateTime(t.year, t.month, t.day));
  }

  Future<void> _kaydet() async {
    if (!_kaydedilebilir || _kaydediliyor) return;
    setState(() => _kaydediliyor = true);
    final p = Profil(
      ad: _ad.text.trim(),
      statu: _statu!,
      adayMemur: _memur && _aday,
      kurumAdi: _kurum,
      sinif: _memur ? _sinif : '',
      unvan: _unvan.text.trim(),
      il: _il,
      sicilNo: _memur ? _sicil.text.trim() : '',
      kurumsalEposta: _eposta.text.trim(),
      maas: _mevcut?.maas,
      kademeTarihi: _memur ? _kademeTarihi : null,
      brutUcret: _statu!.brutUcretliMi ? _mevcut?.brutUcret : null,
    );
    await widget.depo.kaydet(p);
    if (!mounted) return;
    setState(() => _kaydediliyor = false);
    if (widget.onBitti != null) {
      widget.onBitti!();
    } else {
      Navigator.maybePop(context);
    }
  }

  Future<void> _sil() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Profil silinsin mi?', style: PusulaYazi.baslik(18, aralik: -0.5)),
        content: Text(
          'Tüm profil bilgilerin bu cihazdan silinir. Uygulamayı yeniden kullanmak için profilini baştan girersin.',
          style: PusulaYazi.metin(14, agirlik: FontWeight.w500),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text('Sil', style: PusulaYazi.metin(14, renk: PusulaRenk.kirmizi, agirlik: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (onay != true) return;
    await widget.depo.sil();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 16),
                  children: [
                    const Yukselen(
                      child: GeriBaslik(ustYazi: 'Kamu Pusulası', baslik: 'Profilim', sag: SizedBox.shrink()),
                    ),
                    if (widget.fotograf != null) ...[
                      const SizedBox(height: 18),
                      _FotografSatiri(
                        depo: widget.fotograf!,
                        ad: _ad.text,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => FotografSayfasi(
                              depo: widget.fotograf!,
                              kaynak: widget.fotografKaynagi,
                              ad: _ad.text,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.shield, size: 18, color: PusulaRenk.mavi),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bilgilerin yalnızca bu cihazda saklanır. Profilini istediğin zaman silebilirsin.',
                            style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    MetinAlani(
                      etiket: 'Adın',
                      denetleyici: _ad,
                      onDegis: () => setState(() {}),
                      capitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    Text('Statün', style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w700)),
                    const SizedBox(height: 8),
                    for (final s in Statu.values) ...[
                      StatuKarti(statu: s, secili: s == _statu, onTap: () => setState(() => _statu = s)),
                      const SizedBox(height: 8),
                    ],
                    if (_memur) ...[
                      const SizedBox(height: 4),
                      AdayMemurKarti(deger: _aday, onDegis: (v) => setState(() => _aday = v)),
                    ],
                    if (_statu != null) ...[
                      const SizedBox(height: 20),
                      Text('Görev bilgilerin', style: PusulaYazi.baslik(18, agirlik: FontWeight.w700, aralik: -0.4)),
                      const SizedBox(height: 10),
                      SecimAlani(
                        etiket: 'Kurum',
                        deger: _kurum,
                        ipucu: 'Kurumunu seç veya yaz',
                        onTap: () =>
                            _sec('Kurum', ProfilSecenekleri.kurumlar, _kurum, (s) => _kurum = s, serbest: true),
                      ),
                      if (_memur) ...[
                        const SizedBox(height: 12),
                        SecimAlani(
                          etiket: 'Hizmet sınıfı',
                          deger: _sinif,
                          ipucu: 'Sınıfını seç',
                          onTap: () => _sec('Hizmet sınıfı', ProfilSecenekleri.siniflar, _sinif, (s) => _sinif = s),
                        ),
                      ],
                      const SizedBox(height: 12),
                      MetinAlani(
                          etiket: 'Unvan',
                          denetleyici: _unvan,
                          ipucu: 'Ör. Hemşire',
                          onDegis: () => setState(() {}),
                          capitalization: TextCapitalization.words),
                      const SizedBox(height: 12),
                      SecimAlani(
                        etiket: 'Çalıştığın il',
                        deger: _il,
                        ipucu: 'İlini seç',
                        onTap: () => _sec('İl', ProfilSecenekleri.iller, _il, (s) => _il = s),
                      ),
                      if (_memur) ...[
                        const SizedBox(height: 12),
                        SecimAlani(
                          etiket: 'Kademeye geliş tarihi',
                          deger: _kademeTarihi == null ? '' : _tarihMetni(_kademeTarihi!),
                          ipucu: 'İsteğe bağlı — kademe sayacı için',
                          onTap: _kademeTarihiSec,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Bordronda ya da özlük belgende yazar. Ana sayfada en erken kademe ilerlemesine kaç gün kaldığını gösterir (657 md. 64: kademede en az 1 yıl).',
                                  style: PusulaYazi.metin(11, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)
                                      .copyWith(height: 1.4),
                                ),
                              ),
                              if (_kademeTarihi != null)
                                TextButton(
                                  onPressed: () => setState(() => _kademeTarihi = null),
                                  child: Text('Temizle',
                                      style: PusulaYazi.metin(12, renk: PusulaRenk.kirmizi, agirlik: FontWeight.w700)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    if (_memur) ...[
                      const SizedBox(height: 20),
                      Text('Becayiş ve dilekçe', style: PusulaYazi.baslik(18, agirlik: FontWeight.w700, aralik: -0.4)),
                      const SizedBox(height: 4),
                      Text('Yalnızca becayiş dilekçeni doldurmak ve ilanını doğrulamak için kullanılır.',
                          style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)),
                      const SizedBox(height: 10),
                      MetinAlani(
                          etiket: 'Sicil no', denetleyici: _sicil, onDegis: () => setState(() {}), sayisal: true),
                      const SizedBox(height: 12),
                      MetinAlani(
                        etiket: 'Kurumsal e-posta',
                        denetleyici: _eposta,
                        ipucu: 'ad.soyad@kurum.gov.tr',
                        onDegis: () => setState(() {}),
                        eposta: true,
                        hata: _epostaGecerli ? null : 'Geçerli bir e-posta adresi gir',
                      ),
                    ],
                    const SizedBox(height: 26),
                    _AyarlarSatiri(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AyarlarSayfasi(
                            hesap: widget.oturum?.hesap,
                            profil: widget.depo.profil,
                            fotografVar: widget.fotograf?.foto != null,
                            hatirlatici: widget.hatirlatici,
                                                        ilanTakibi: widget.ilanTakibi,
                            haberTakibi: widget.haberTakibi,

                          ),
                        ),
                      ),
                    ),
                    if (widget.oturum != null) ...[
                      const SizedBox(height: 26),
                      HesapBolumu(
                        oturum: widget.oturum!,
                        veriSil: () async {
                          await widget.hatirlatici?.tercihiSil();
                          await widget.ilanTakibi?.tercihiSil();
                          await widget.kayitliIlanlar?.temizle();
                          await widget.haberTakibi?.tercihiSil();
                          await widget.depo.sil();
                          await widget.fotograf?.kaldir();
                        },
                      ),
                    ],
                    if (_mevcut != null) ...[
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton.icon(
                          onPressed: _sil,
                          icon: const Icon(LucideIcons.trash2, size: 18, color: PusulaRenk.kirmizi),
                          label: Text('Profil bilgilerimi sil',
                              style: PusulaYazi.metin(14, renk: PusulaRenk.kirmizi, agirlik: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: BirincilDugme(
                  yukseklik: 58,
                  metin: 'Kaydet',
                  yukleniyor: _kaydediliyor,
                  yukleniyorMetni: 'Kaydediliyor',
                  onPressed: _kaydedilebilir ? _kaydet : null,
                ),
              ),
            ],
          ),
        ),
      );
}

/// Profil sayfasının üstündeki avatar ve "fotoğrafı değiştir" satırı.
class _FotografSatiri extends StatelessWidget {
  const _FotografSatiri({required this.depo, required this.ad, required this.onTap});

  final FotografDeposu depo;
  final String ad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: depo,
        builder: (context, _) => Semantics(
          button: true,
          label: depo.foto == null ? 'Profil fotoğrafı ekle' : 'Profil fotoğrafını değiştir',
          excludeSemantics: true,
          onTap: onTap,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  ProfilAvatar(boyut: 72, foto: depo.foto, ad: ad, kamera: true),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ad.trim().isEmpty ? 'Profilin' : ad.trim(),
                            overflow: TextOverflow.ellipsis, style: PusulaYazi.baslik(20, aralik: -0.6)),
                        const SizedBox(height: 2),
                        Text(depo.foto == null ? 'Fotoğraf ekle' : 'Fotoğrafı değiştir',
                            style: PusulaYazi.metin(13, renk: PusulaRenk.mavi, agirlik: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight, size: 20, color: PusulaRenk.soluk),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Profil sayfasında "Ayarlar ve yasal" satırı.
class _AyarlarSatiri extends StatelessWidget {
  const _AyarlarSatiri({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        button: true,
        label: 'Ayarlar ve yasal',
        excludeSemantics: true,
        onTap: onTap,
        child: Material(
          color: PusulaRenk.beyaz,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
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
                    const Icon(LucideIcons.settings, size: 20, color: PusulaRenk.lacivert),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Ayarlar ve yasal', style: PusulaYazi.metin(15, agirlik: FontWeight.w700)),
                    ),
                    const Icon(LucideIcons.chevronRight, size: 18, color: PusulaRenk.soluk),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
