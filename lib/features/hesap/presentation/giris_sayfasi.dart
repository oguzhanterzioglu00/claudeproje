import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/bilesenler.dart';
import '../../../core/logo.dart';
import '../../../core/marka_ikonlari.dart';
import '../../../core/tema.dart';
import '../../../core/yukselen.dart';
import '../../profil/presentation/profil_alanlari.dart';
import '../../ayarlar/yasal_metinler.dart';
import '../../ayarlar/yasal_sayfasi.dart';
import '../data/kimlik_servisi.dart';
import '../data/oturum_deposu.dart';
import '../domain/hesap.dart';
import 'hesap_parcalari.dart';

/// Giriş yap / hesap oluştur; Google ve Apple ile hızlı giriş.
///
/// Bu sürümde hesaplar yalnızca cihazda tutulur ve Google/Apple girişi örnektir
/// (bkz. `YerelKimlikServisi`); ekranda "ÖRNEK" rozeti bunu belirtir.
class GirisSayfasi extends StatefulWidget {
  const GirisSayfasi({super.key, required this.oturum, this.appleGoster = true, this.sosyalGiris = true});

  final OturumDeposu oturum;

  /// Apple ile giriş düğmesi (yalnızca Apple platformlarında ya da web'de gerekli olabilir).
  final bool appleGoster;

  /// Google/Apple düğmeleri. Gerçek giriş bağlanana kadar mağaza sürümünde kapalıdır (yalnızca örnek hesap açar).
  final bool sosyalGiris;

  @override
  State<GirisSayfasi> createState() => _GirisSayfasiState();
}

class _GirisSayfasiState extends State<GirisSayfasi> {
  final _eposta = TextEditingController();
  final _sifre = TextEditingController();
  bool _kayit = false;
  bool _sifreGizli = true;
  String? _hata;

  @override
  void dispose() {
    _eposta.dispose();
    _sifre.dispose();
    super.dispose();
  }

  bool get _gonderilebilir {
    if (widget.oturum.mesgul) return false;
    if (!HesapKurali.epostaGecerli(_eposta.text)) return false;
    return _kayit ? HesapKurali.sifreHatasi(_sifre.text) == null : _sifre.text.isNotEmpty;
  }

  void _kipDegistir(bool kayit) => setState(() {
    _kayit = kayit;
    _hata = null;
  });

  Future<void> _gonder() async {
    if (!_gonderilebilir) return;
    setState(() => _hata = null);
    try {
      if (_kayit) {
        await widget.oturum.kayitOl(_eposta.text, _sifre.text);
      } else {
        await widget.oturum.girisYap(_eposta.text, _sifre.text);
      }
    } on KimlikHatasi catch (h) {
      if (mounted) setState(() => _hata = h.mesaj);
    }
  }

  Future<void> _saglayici(GirisSaglayici s) async {
    final devam = await AltSayfa.goster<bool>(context, builder: (c) => _OrnekGirisOnayi(saglayici: s));
    if (devam != true || !mounted) return;
    setState(() => _hata = null);
    try {
      await widget.oturum.saglayiciIleGiris(s);
    } on KimlikHatasi catch (h) {
      if (mounted) setState(() => _hata = h.mesaj);
    }
  }

  void _yasalAc(YasalMetin metin) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => YasalSayfasi(metin: metin)));

  Future<void> _sifremiUnuttum() => AltSayfa.goster<void>(
    context,
    builder: (c) => _SifreSifirlama(oturum: widget.oturum, baslangic: _eposta.text.trim()),
  );

  @override
  Widget build(BuildContext context) {
    final klavyeAcik = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      backgroundColor: PusulaRenk.lacivert,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: widget.oturum,
          builder: (context, _) => Column(
            children: [
              if (!klavyeAcik)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
                  child: Row(
                    children: [
                      const AnimasyonluPusulaLogo(boyut: 64, arkaplan: false),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kamu Pusulası', style: PusulaYazi.baslik(24, renk: PusulaRenk.beyaz, aralik: -1)),
                            const SizedBox(height: 2),
                            Text(
                              'Kamu çalışanlarının rehberi',
                              style: PusulaYazi.metin(13, renk: const Color(0xFFC9D2EC), agirlik: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const OrnekRozeti(),
                    ],
                  ),
                )
              else
                const SizedBox(height: 12),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: PusulaRenk.zemin,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(22, 22, 22, 22 + MediaQuery.viewPaddingOf(context).bottom),
                    children: [
                      Yukselen(
                        child: _KipSecici(kayit: _kayit, onDegis: _kipDegistir),
                      ),
                      const SizedBox(height: 20),
                      Yukselen(
                        gecikme: const Duration(milliseconds: 80),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            MetinAlani(
                              etiket: 'E-posta',
                              denetleyici: _eposta,
                              ipucu: 'ornek@eposta.com',
                              onDegis: () => setState(() {}),
                              eposta: true,
                              otomatikDoldur: const [AutofillHints.email],
                              klavyeEylemi: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),
                            MetinAlani(
                              etiket: 'Şifre',
                              denetleyici: _sifre,
                              onDegis: () => setState(() {}),
                              gizli: _sifreGizli,
                              otomatikDoldur: [_kayit ? AutofillHints.newPassword : AutofillHints.password],
                              klavyeEylemi: TextInputAction.done,
                              onGonder: _gonder,
                              sonEk: Semantics(
                                button: true,
                                label: _sifreGizli ? 'Şifreyi göster' : 'Şifreyi gizle',
                                excludeSemantics: true,
                                onTap: () => setState(() => _sifreGizli = !_sifreGizli),
                                child: IconButton(
                                  onPressed: () => setState(() => _sifreGizli = !_sifreGizli),
                                  icon: Icon(
                                    _sifreGizli ? LucideIcons.eye : LucideIcons.eyeOff,
                                    size: 20,
                                    color: PusulaRenk.lacivert,
                                  ),
                                ),
                              ),
                            ),
                            if (_kayit) ...[
                              const SizedBox(height: 10),
                              SifreKurallari(sifre: _sifre.text),
                            ] else
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _sifremiUnuttum,
                                  child: Text(
                                    'Şifremi unuttum',
                                    style: PusulaYazi.metin(13, renk: PusulaRenk.mavi, agirlik: FontWeight.w700),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_hata != null) ...[const SizedBox(height: 10), HataKutusu(mesaj: _hata!)],
                      const SizedBox(height: 16),
                      Yukselen(
                        gecikme: const Duration(milliseconds: 140),
                        child: BirincilDugme(
                          yukseklik: 58,
                          metin: _kayit ? 'Hesap oluştur' : 'Giriş yap',
                          yukleniyor: widget.oturum.mesgul,
                          yukleniyorMetni: _kayit ? 'Hesap oluşturuluyor' : 'Giriş yapılıyor',
                          onPressed: _gonderilebilir ? _gonder : null,
                        ),
                      ),
                      if (widget.sosyalGiris) ...[
                        const SizedBox(height: 20),
                        Yukselen(
                          gecikme: const Duration(milliseconds: 200),
                          child: Row(
                            children: [
                              const Expanded(child: Divider(color: PusulaRenk.cizgi, thickness: 1.5)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'veya',
                                  style: PusulaYazi.metin(13, renk: PusulaRenk.soluk, agirlik: FontWeight.w600),
                                ),
                              ),
                              const Expanded(child: Divider(color: PusulaRenk.cizgi, thickness: 1.5)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Yukselen(
                          gecikme: const Duration(milliseconds: 260),
                          child: _HizliGirisDugmesi(
                            metin: 'Google ile devam et',
                            ikon: const GoogleGIkonu(boyut: 22),
                            onPressed: widget.oturum.mesgul ? null : () => _saglayici(GirisSaglayici.google),
                          ),
                        ),
                        if (widget.appleGoster) ...[
                          const SizedBox(height: 12),
                          Yukselen(
                            gecikme: const Duration(milliseconds: 320),
                            child: _HizliGirisDugmesi(
                              metin: 'Apple ile devam et',
                              ikon: const Icon(LucideIcons.apple, size: 22, color: PusulaRenk.lacivert),
                              onPressed: widget.oturum.mesgul ? null : () => _saglayici(GirisSaglayici.apple),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 22),
                      Text(
                        'Devam ederek aşağıdaki metinleri kabul etmiş olursun. '
                        'Bu sürümde hesabın yalnızca bu cihazda tutulur. Kamu Pusulası resmî bir kurum uygulaması değildir.',
                        textAlign: TextAlign.center,
                        style: PusulaYazi.metin(
                          12,
                          renk: PusulaRenk.soluk,
                          agirlik: FontWeight.w500,
                        ).copyWith(height: 1.45),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => _yasalAc(YasalMetinler.kosullar),
                            child: Text(
                              'Kullanım Koşulları',
                              style: PusulaYazi.metin(13, renk: PusulaRenk.mavi, agirlik: FontWeight.w700),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _yasalAc(YasalMetinler.aydinlatma),
                            child: Text(
                              'Aydınlatma Metni',
                              style: PusulaYazi.metin(13, renk: PusulaRenk.mavi, agirlik: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KipSecici extends StatelessWidget {
  const _KipSecici({required this.kayit, required this.onDegis});

  final bool kayit;
  final ValueChanged<bool> onDegis;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: PusulaRenk.beyaz,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: PusulaRenk.lacivert, width: 1.5),
    ),
    child: Row(
      children: [
        Expanded(
          child: _Sekme(etiket: 'Giriş yap', secili: !kayit, onTap: () => onDegis(false)),
        ),
        Expanded(
          child: _Sekme(etiket: 'Hesap oluştur', secili: kayit, onTap: () => onDegis(true)),
        ),
      ],
    ),
  );
}

class _Sekme extends StatelessWidget {
  const _Sekme({required this.etiket, required this.secili, required this.onTap});

  final String etiket;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: secili,
    child: Material(
      color: secili ? PusulaRenk.lacivert : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              etiket,
              style: PusulaYazi.metin(
                14,
                renk: secili ? PusulaRenk.beyaz : PusulaRenk.lacivert,
                agirlik: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _HizliGirisDugmesi extends StatelessWidget {
  const _HizliGirisDugmesi({required this.metin, required this.ikon, required this.onPressed});

  final String metin;
  final Widget ikon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    label: metin,
    excludeSemantics: true,
    onTap: onPressed,
    child: Material(
      color: PusulaRenk.beyaz,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onPressed,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ikon,
              const SizedBox(width: 12),
              Text(metin, style: PusulaYazi.metin(15, agirlik: FontWeight.w700)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Google/Apple örnek girişinin ne olduğunu açıklar; kullanıcı onaylamadan giriş yapılmaz.
class _OrnekGirisOnayi extends StatelessWidget {
  const _OrnekGirisOnayi({required this.saglayici});

  final GirisSaglayici saglayici;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('${saglayici.etiket} ile devam et', style: PusulaYazi.baslik(22, aralik: -0.9)),
      const SizedBox(height: 10),
      Text(
        'Bu örnek sürümde gerçek ${saglayici.etiket} girişi henüz bağlı değil. '
        'Devam edersen bu cihazda örnek bir ${saglayici.etiket} hesabıyla oturum açılır; '
        'hiçbir bilgin ${saglayici.etiket}\'a ya da bir sunucuya gitmez.',
        style: PusulaYazi.metin(14, renk: PusulaRenk.soluk, agirlik: FontWeight.w500).copyWith(height: 1.45),
      ),
      const SizedBox(height: 18),
      BirincilDugme(yukseklik: 56, metin: 'Örnek hesapla devam et', onPressed: () => Navigator.pop(context, true)),
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text(
          'Vazgeç',
          style: PusulaYazi.metin(14, renk: PusulaRenk.soluk, agirlik: FontWeight.w700),
        ),
      ),
    ],
  );
}

class _SifreSifirlama extends StatefulWidget {
  const _SifreSifirlama({required this.oturum, required this.baslangic});

  final OturumDeposu oturum;
  final String baslangic;

  @override
  State<_SifreSifirlama> createState() => _SifreSifirlamaState();
}

class _SifreSifirlamaState extends State<_SifreSifirlama> {
  late final _eposta = TextEditingController(text: widget.baslangic);
  bool _gonderildi = false;
  String? _hata;

  @override
  void dispose() {
    _eposta.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    setState(() => _hata = null);
    try {
      await widget.oturum.sifreSifirlamaIste(_eposta.text.trim());
      if (mounted) setState(() => _gonderildi = true);
    } on KimlikHatasi catch (h) {
      if (mounted) setState(() => _hata = h.mesaj);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Şifreni sıfırla', style: PusulaYazi.baslik(22, aralik: -0.9)),
      const SizedBox(height: 8),
      if (_gonderildi) ...[
        Text(
          'Bu e-posta ile kayıtlı bir hesap varsa şifre sıfırlama bağlantısı gönderilir. '
          'Örnek sürümde e-posta gönderilmez; gerçek sürümde bağlantı gelen kutuna düşecek.',
          style: PusulaYazi.metin(14, renk: PusulaRenk.soluk, agirlik: FontWeight.w500).copyWith(height: 1.45),
        ),
        const SizedBox(height: 16),
        BirincilDugme(yukseklik: 54, metin: 'Tamam', onPressed: () => Navigator.pop(context)),
      ] else ...[
        Text(
          'Hesabının e-posta adresini yaz; sıfırlama bağlantısını oraya gönderelim.',
          style: PusulaYazi.metin(14, renk: PusulaRenk.soluk, agirlik: FontWeight.w500).copyWith(height: 1.45),
        ),
        const SizedBox(height: 14),
        MetinAlani(etiket: 'E-posta', denetleyici: _eposta, onDegis: () => setState(() {}), eposta: true, hata: _hata),
        const SizedBox(height: 16),
        ListenableBuilder(
          listenable: widget.oturum,
          builder: (context, _) => BirincilDugme(
            yukseklik: 54,
            metin: 'Bağlantı gönder',
            yukleniyor: widget.oturum.mesgul,
            yukleniyorMetni: 'Gönderiliyor',
            onPressed: HesapKurali.epostaGecerli(_eposta.text) ? _gonder : null,
          ),
        ),
      ],
    ],
  );
}
