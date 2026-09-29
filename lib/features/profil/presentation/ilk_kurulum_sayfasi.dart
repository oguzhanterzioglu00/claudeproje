import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/bilesenler.dart';
import '../../../core/tema.dart';
import '../data/profil_deposu.dart';
import '../domain/profil.dart';
import 'karsilama_sayfasi.dart';
import 'profil_alanlari.dart';
import 'secim_sayfasi.dart';

/// İlk açılış akışı: karşılama → adım adım profil kurulumu.
/// Kayıt tamamlanınca [ProfilDeposu] değişir; uygulama kökü ana kabuğa geçer.
class IlkKurulumSayfasi extends StatefulWidget {
  const IlkKurulumSayfasi({super.key, required this.depo});

  final ProfilDeposu depo;

  @override
  State<IlkKurulumSayfasi> createState() => _IlkKurulumSayfasiState();
}

class _IlkKurulumSayfasiState extends State<IlkKurulumSayfasi> {
  final _ad = TextEditingController();
  final _unvan = TextEditingController();
  final _sicil = TextEditingController();
  final _eposta = TextEditingController();

  /// 0: karşılama; 1..[_adimSayisi]: kurulum adımları.
  int _adim = 0;
  bool _ileri = true;
  Statu? _statu;
  bool _aday = false;
  String _kurum = '';
  String _sinif = '';
  String _il = '';
  bool _kaydediliyor = false;

  bool get _memur => _statu == Statu.memur657;
  int get _adimSayisi => _memur ? 3 : 2;
  bool get _epostaGecerli => _eposta.text.trim().isEmpty || _eposta.text.contains('@');

  bool get _devamEdilebilir => switch (_adim) {
        1 => _ad.text.trim().isNotEmpty && _statu != null,
        3 => _epostaGecerli,
        _ => true,
      };

  @override
  void dispose() {
    _ad.dispose();
    _unvan.dispose();
    _sicil.dispose();
    _eposta.dispose();
    super.dispose();
  }

  void _git(int adim) => setState(() {
        _ileri = adim > _adim;
        _adim = adim;
      });

  Future<void> _sec(String baslik, List<String> secenekler, String secili, ValueChanged<String> yaz,
      {bool serbest = false}) async {
    final s = await SecimSayfasi.goster(context, baslik: baslik, secenekler: secenekler, secili: secili, serbest: serbest);
    if (s != null) setState(() => yaz(s));
  }

  Future<void> _devam({bool atla = false}) async {
    if (!_devamEdilebilir && !atla) return;
    if (_adim < _adimSayisi) {
      _git(_adim + 1);
      return;
    }
    if (_kaydediliyor) return;
    setState(() => _kaydediliyor = true);
    final sicilVeEposta = _memur && !atla;
    await widget.depo.kaydet(Profil(
      ad: _ad.text.trim(),
      statu: _statu!,
      adayMemur: _memur && _aday,
      kurumAdi: _kurum,
      sinif: _memur ? _sinif : '',
      unvan: _unvan.text.trim(),
      il: _il,
      sicilNo: sicilVeEposta ? _sicil.text.trim() : '',
      kurumsalEposta: sicilVeEposta ? _eposta.text.trim() : '',
    ));
    if (mounted) setState(() => _kaydediliyor = false);
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: _adim == 0,
        onPopInvokedWithResult: (geciyor, _) {
          if (!geciyor) _git(_adim - 1);
        },
        child: _adim == 0 ? KarsilamaSayfasi(onBasla: () => _git(1)) : _kurulum(),
      );

  Widget _kurulum() {
    final hareketsiz = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: _UstCubuk(adim: _adim, toplam: _adimSayisi, onGeri: () => _git(_adim - 1)),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: hareketsiz ? Duration.zero : const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(begin: Offset(_ileri ? 0.06 : -0.06, 0), end: Offset.zero).animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_adim),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
                    children: switch (_adim) {
                      1 => _kimsin(),
                      2 => _gorev(),
                      _ => _becayis(),
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Column(
                children: [
                  BirincilDugme(
                    yukseklik: 58,
                    metin: _adim == _adimSayisi ? 'Tamamla' : 'Devam',
                    ikon: _adim == _adimSayisi ? LucideIcons.check : LucideIcons.arrowRight,
                    yukleniyor: _kaydediliyor,
                    yukleniyorMetni: 'Kaydediliyor',
                    onPressed: _devamEdilebilir ? _devam : null,
                  ),
                  if (_adim > 1)
                    TextButton(
                      onPressed: _kaydediliyor ? null : () => _devam(atla: true),
                      child: Text('Şimdilik atla',
                          style: PusulaYazi.metin(14, renk: PusulaRenk.soluk, agirlik: FontWeight.w700)),
                    )
                  else
                    const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _baslik(String ust, String baslik, String alt) => [
        Text(ust, style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(baslik, style: PusulaYazi.baslik(30, aralik: -1.4)),
        const SizedBox(height: 8),
        Text(alt,
            style: PusulaYazi.metin(14, renk: PusulaRenk.soluk, agirlik: FontWeight.w500).copyWith(height: 1.45)),
        const SizedBox(height: 22),
      ];

  List<Widget> _kimsin() => [
        ..._baslik('Adım 1', 'Seni tanıyalım',
            'Sana uygun maaş, hak ve ilan bilgilerini gösterebilmemiz için birkaç bilgiye ihtiyacımız var.'),
        MetinAlani(
          etiket: 'Adın',
          denetleyici: _ad,
          onDegis: () => setState(() {}),
          capitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 20),
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
      ];

  List<Widget> _gorev() => [
        ..._baslik('Adım 2', 'Görev bilgilerin',
            'Becayiş eşleşmesi ve ilan uyumu kurum, hizmet sınıfı ve ilinle yapılır.'),
        SecimAlani(
          etiket: 'Kurum',
          deger: _kurum,
          ipucu: 'Kurumunu seç veya yaz',
          onTap: () => _sec('Kurum', ProfilSecenekleri.kurumlar, _kurum, (s) => _kurum = s, serbest: true),
        ),
        if (_memur) ...[
          const SizedBox(height: 14),
          SecimAlani(
            etiket: 'Hizmet sınıfı',
            deger: _sinif,
            ipucu: 'Sınıfını seç',
            onTap: () => _sec('Hizmet sınıfı', ProfilSecenekleri.siniflar, _sinif, (s) => _sinif = s),
          ),
        ],
        const SizedBox(height: 14),
        MetinAlani(
          etiket: 'Unvan',
          denetleyici: _unvan,
          ipucu: 'Ör. Hemşire',
          onDegis: () => setState(() {}),
          capitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        SecimAlani(
          etiket: 'Çalıştığın il',
          deger: _il,
          ipucu: 'İlini seç',
          onTap: () => _sec('İl', ProfilSecenekleri.iller, _il, (s) => _il = s),
        ),
      ];

  List<Widget> _becayis() => [
        ..._baslik('Adım 3', 'Becayiş ve dilekçe',
            'Yalnızca becayiş dilekçeni doldurmak ve ilanını doğrulamak için kullanılır. İstersen şimdilik atlayıp sonra profilinden ekleyebilirsin.'),
        MetinAlani(etiket: 'Sicil no', denetleyici: _sicil, onDegis: () => setState(() {}), sayisal: true),
        const SizedBox(height: 14),
        MetinAlani(
          etiket: 'Kurumsal e-posta',
          denetleyici: _eposta,
          ipucu: 'ad.soyad@kurum.gov.tr',
          onDegis: () => setState(() {}),
          eposta: true,
          hata: _epostaGecerli ? null : 'Geçerli bir e-posta adresi gir',
        ),
      ];
}

/// Geri düğmesi, adım çubuğu ve "1 / 3" göstergesi.
class _UstCubuk extends StatelessWidget {
  const _UstCubuk({required this.adim, required this.toplam, required this.onGeri});

  final int adim;
  final int toplam;
  final VoidCallback onGeri;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Semantics(
            button: true,
            label: 'Geri',
            excludeSemantics: true,
            onTap: onGeri,
            child: Material(
              color: PusulaRenk.beyaz,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onGeri,
                child: const SizedBox.square(
                  dimension: 44,
                  child: Icon(LucideIcons.arrowLeft, size: 22, color: PusulaRenk.lacivert),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Semantics(
              label: 'Adım $adim / $toplam',
              excludeSemantics: true,
              child: Row(
                children: [
                  for (var i = 1; i <= toplam; i++) ...[
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 6,
                        decoration: BoxDecoration(
                          color: i <= adim ? PusulaRenk.lacivert : PusulaRenk.cizgi,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    if (i < toplam) const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text('$adim / $toplam', style: PusulaYazi.metin(13, renk: PusulaRenk.soluk, agirlik: FontWeight.w700)),
        ],
      );
}
