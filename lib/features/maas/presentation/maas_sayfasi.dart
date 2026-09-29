import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/bilesenler.dart';
import '../../../core/metin.dart';
import '../../../core/tema.dart';
import '../../../core/ucgenler.dart';
import '../../../core/yukselen.dart';
import '../domain/gosterge_tablosu.dart';
import '../domain/memur_maas_hesaplayici.dart';

/// Memur maaşı hesaplayıcısı: derece, kademe ve bordrodan bilinen kalemlerle
/// tahmini brüt/net. Sözleşmeli ve işçi için hesap yoktur (ayrı sözleşmelere tabi).
class MaasSayfasi extends StatefulWidget {
  const MaasSayfasi({
    super.key,
    this.hesaplayici = const MemurMaasHesaplayici(),
    this.ay,
    this.baslangic = const MaasGirdisi(derece: 8, kademe: 3, hizmetYili: 10),
  });

  final MemurMaasHesaplayici hesaplayici;

  /// Kümülatif vergi için ay (1-12); boşsa bugünün ayı.
  final int? ay;
  final MaasGirdisi baslangic;

  @override
  State<MaasSayfasi> createState() => _MaasSayfasiState();
}

class _MaasSayfasiState extends State<MaasSayfasi> {
  static const _gruplar = ['Memur 4/A', 'Sözleşmeli', 'İşçi'];

  late MaasGirdisi _g = widget.baslangic;
  int _grup = 0;
  bool _gelismis = false;

  late final _ekGosterge = TextEditingController(text: _metin(_g.ekGosterge));
  late final _yanOdeme = TextEditingController(text: _metin(_g.yanOdemePuani));
  late final _tazminat = TextEditingController(text: _metin((_g.ozelHizmetTazminatiOrani * 100).round()));
  late final _diger = TextEditingController(text: _metin(_g.digerBrut.round()));

  static String _metin(int v) => v == 0 ? '' : '$v';

  @override
  void dispose() {
    _ekGosterge.dispose();
    _yanOdeme.dispose();
    _tazminat.dispose();
    _diger.dispose();
    super.dispose();
  }

  static double _sayi(String s) => double.tryParse(s.trim().replaceAll(',', '.')) ?? 0;

  void _derece(int d) {
    final derece = d.clamp(1, GostergeTablosu.enUstDerece);
    setState(() => _g = _g.kopya(derece: derece, kademe: GostergeTablosu.kademeSinirla(derece, _g.kademe)));
  }

  @override
  Widget build(BuildContext context) {
    final ay = widget.ay ?? DateTime.now().month;
    final p = widget.hesaplayici.parametreler;
    final memur = _grup == 0;
    final s = memur ? widget.hesaplayici.hesapla(_g, ay: ay) : null;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
        children: [
          Yukselen(
            child: Row(
              children: [
                Expanded(child: Text('Maaş hesapla', style: PusulaYazi.baslik(24, aralik: -1))),
                Hap(p.donem, zemin: PusulaRenk.lacivert, yazi: PusulaRenk.amber),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (s != null)
            Yukselen(gecikme: const Duration(milliseconds: 80), child: _SonucKarti(sonuc: s, donem: p.donem))
          else
            const Yukselen(gecikme: Duration(milliseconds: 80), child: _KapsamDisi()),
          const SizedBox(height: 14),
          Yukselen(
            gecikme: const Duration(milliseconds: 140),
            child: _Bolum(
              baslik: 'Görev grubu',
              child: Row(
                children: [
                  for (var i = 0; i < _gruplar.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _Secenek(
                        etiket: _gruplar[i],
                        secili: i == _grup,
                        onTap: () => setState(() => _grup = i),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (memur) ...[
            const SizedBox(height: 14),
            Yukselen(
              gecikme: const Duration(milliseconds: 200),
              child: _Adim(
                etiket: 'Derece',
                deger: '${_g.derece}',
                eksiEtiketi: 'Dereceyi azalt',
                artiEtiketi: 'Dereceyi artır',
                onEksi: _g.derece > 1 ? () => _derece(_g.derece - 1) : null,
                onArti: _g.derece < GostergeTablosu.enUstDerece ? () => _derece(_g.derece + 1) : null,
              ),
            ),
            const SizedBox(height: 14),
            Yukselen(
              gecikme: const Duration(milliseconds: 260),
              child: _Bolum(
                baslik: 'Kademe',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var k = 1; k <= GostergeTablosu.kademeSayisi(_g.derece); k++)
                      _KademeDugmesi(
                        n: k,
                        secili: k == _g.kademe,
                        onTap: () => setState(() => _g = _g.kopya(kademe: k)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Yukselen(
              gecikme: const Duration(milliseconds: 320),
              child: _Adim(
                etiket: 'Hizmet yılı',
                alt: 'Kıdem aylığı en çok ${p.enFazlaKidemYili} yıl sayılır',
                deger: '${_g.hizmetYili}',
                eksiEtiketi: 'Hizmet yılını azalt',
                artiEtiketi: 'Hizmet yılını artır',
                onEksi: _g.hizmetYili > 0 ? () => setState(() => _g = _g.kopya(hizmetYili: _g.hizmetYili - 1)) : null,
                onArti: _g.hizmetYili < 45 ? () => setState(() => _g = _g.kopya(hizmetYili: _g.hizmetYili + 1)) : null,
              ),
            ),
            const SizedBox(height: 14),
            _Gelismis(
              acik: _gelismis,
              onDegis: () => setState(() => _gelismis = !_gelismis),
              alanlar: [
                _SayiAlani(
                  etiket: 'Ek gösterge',
                  ipucu: 'Bordroda "ek gösterge" yazar',
                  denetleyici: _ekGosterge,
                  onDegis: (v) => setState(() => _g = _g.kopya(ekGosterge: _sayi(v).round())),
                ),
                _SayiAlani(
                  etiket: 'Yan ödeme puanı',
                  ipucu: 'Bordroda "yan ödeme" puanı',
                  denetleyici: _yanOdeme,
                  onDegis: (v) => setState(() => _g = _g.kopya(yanOdemePuani: _sayi(v).round())),
                ),
                _SayiAlani(
                  etiket: 'Özel hizmet tazminatı',
                  ipucu: 'Oran, ör. 50',
                  sonEk: '%',
                  denetleyici: _tazminat,
                  onDegis: (v) => setState(() => _g = _g.kopya(ozelHizmetTazminatiOrani: _sayi(v) / 100)),
                ),
                _SayiAlani(
                  etiket: 'Diğer brüt ödemeler',
                  ipucu: 'Ek ödeme vb., aylık TL',
                  sonEk: '₺',
                  denetleyici: _diger,
                  onDegis: (v) => setState(() => _g = _g.kopya(digerBrut: _sayi(v))),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Dokum(sonuc: s!),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(LucideIcons.info, size: 18, color: PusulaRenk.soluk),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tahmini hesap: bordrondaki net tutar geçerlidir. Katsayılar: ${p.kaynak}. '
                    'Aile/çocuk yardımı ve kişisel kalemler dahil değil; aylık tutar yıl boyunca sabit kabul edilir.',
                    style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500).copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SonucKarti extends StatelessWidget {
  const _SonucKarti({required this.sonuc, required this.donem});

  final MaasSonucu sonuc;
  final String donem;

  @override
  Widget build(BuildContext context) {
    final hareketsiz = MediaQuery.disableAnimationsOf(context);
    final netOran = sonuc.brut <= 0 ? 0.0 : (sonuc.net / sonuc.brut).clamp(0.0, 1.0);
    final netFlex = (netOran * 1000).round().clamp(1, 999);

    return Semantics(
      label: 'Tahmini net maaş ${binlik(sonuc.net)} lira',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          color: PusulaRenk.mavi,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Stack(
            children: [
              const Positioned(
                right: -80,
                top: -90,
                child: Opacity(opacity: 0.5, child: PusulaUcgenler(boyut: 230, orta: PusulaRenk.lacivert)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(LucideIcons.wallet, size: 18, color: Color(0xFFDCE3FF)),
                    const SizedBox(width: 8),
                    Text('Tahmini net maaş', style: PusulaYazi.metin(13, renk: const Color(0xFFDCE3FF))),
                  ]),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: sonuc.net),
                    duration: hareketsiz ? Duration.zero : const Duration(milliseconds: 550),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => Text(
                      liraTam(v),
                      maxLines: 1,
                      style: PusulaYazi.baslik(44, renk: PusulaRenk.beyaz, aralik: -2)
                          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Row(children: [
                      Expanded(flex: netFlex, child: Container(height: 8, color: PusulaRenk.amber)),
                      const SizedBox(width: 2),
                      Expanded(flex: 1000 - netFlex, child: Container(height: 8, color: PusulaRenk.lacivert)),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _EtiketDeger('Net', sonuc.net),
                      _EtiketDeger('Kesinti', sonuc.kesintiToplami),
                      _EtiketDeger('Brüt', sonuc.brut),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EtiketDeger extends StatelessWidget {
  const _EtiketDeger(this.etiket, this.deger);

  final String etiket;
  final double deger;

  @override
  Widget build(BuildContext context) => Text(
        '$etiket ${liraTam(deger)}',
        style: PusulaYazi.metin(12, renk: const Color(0xFFDCE3FF), agirlik: FontWeight.w700),
      );
}

class _KapsamDisi extends StatelessWidget {
  const _KapsamDisi();

  @override
  Widget build(BuildContext context) => PusulaKart(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(LucideIcons.info, size: 20, color: PusulaRenk.lacivert),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sözleşmeli ve işçi maaşı, sözleşme veya toplu iş sözleşmesine göre değişir; '
                'bu hesap yalnızca 657 sayılı Kanun\'a tabi memurlar içindir. '
                'Bu gruplar için hesap yakında.',
                style: PusulaYazi.metin(14).copyWith(height: 1.4),
              ),
            ),
          ],
        ),
      );
}

class _Bolum extends StatelessWidget {
  const _Bolum({required this.baslik, required this.child});

  final String baslik;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik, style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w700)),
          const SizedBox(height: 8),
          child,
        ],
      );
}

class _Secenek extends StatelessWidget {
  const _Secenek({required this.etiket, required this.secili, required this.onTap});

  final String etiket;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: secili,
        child: Material(
          color: secili ? PusulaRenk.lacivert : PusulaRenk.beyaz,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: SizedBox(
              height: 46,
              child: Center(
                child: Text(
                  etiket,
                  style: PusulaYazi.metin(
                    13,
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

class _KademeDugmesi extends StatelessWidget {
  const _KademeDugmesi({required this.n, required this.secili, required this.onTap});

  final int n;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: secili,
        label: 'Kademe $n',
        excludeSemantics: true,
        child: Material(
          color: secili ? PusulaRenk.amber : PusulaRenk.beyaz,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: SizedBox.square(
              dimension: 44,
              child: Center(child: Text('$n', style: PusulaYazi.baslik(14, aralik: 0, agirlik: FontWeight.w700))),
            ),
          ),
        ),
      );
}

class _Adim extends StatelessWidget {
  const _Adim({
    required this.etiket,
    required this.deger,
    required this.eksiEtiketi,
    required this.artiEtiketi,
    required this.onEksi,
    required this.onArti,
    this.alt,
  });

  final String etiket;
  final String? alt;
  final String deger;
  final String eksiEtiketi;
  final String artiEtiketi;
  final VoidCallback? onEksi;
  final VoidCallback? onArti;

  @override
  Widget build(BuildContext context) => PusulaKart(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(etiket, style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w700)),
                  Text(deger, style: PusulaYazi.baslik(28, aralik: -1)),
                  if (alt != null)
                    Text(alt!, style: PusulaYazi.metin(11, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)),
                ],
              ),
            ),
            _Yuvarlak(LucideIcons.minus, eksiEtiketi, onEksi),
            const SizedBox(width: 8),
            _Yuvarlak(LucideIcons.plus, artiEtiketi, onArti),
          ],
        ),
      );
}

class _Yuvarlak extends StatelessWidget {
  const _Yuvarlak(this.ikon, this.etiket, this.onTap);

  final IconData ikon;
  final String etiket;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: onTap != null,
        label: etiket,
        excludeSemantics: true,
        child: Material(
          color: onTap == null ? PusulaRenk.cizgi : PusulaRenk.amber,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: SizedBox.square(
              dimension: 48,
              child: Icon(ikon, size: 22, color: onTap == null ? PusulaRenk.soluk : PusulaRenk.lacivert),
            ),
          ),
        ),
      );
}

class _Gelismis extends StatelessWidget {
  const _Gelismis({required this.acik, required this.onDegis, required this.alanlar});

  final bool acik;
  final VoidCallback onDegis;
  final List<Widget> alanlar;

  @override
  Widget build(BuildContext context) => PusulaKart(
        radius: 24,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Semantics(
              button: true,
              expanded: acik,
              child: InkWell(
                onTap: onDegis,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bordrondan netleştir', style: PusulaYazi.metin(14, agirlik: FontWeight.w700)),
                            Text('Ek gösterge, yan ödeme, tazminat',
                                style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)),
                          ],
                        ),
                      ),
                      Icon(acik ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 22, color: PusulaRenk.lacivert),
                    ],
                  ),
                ),
              ),
            ),
            if (acik)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    for (var i = 0; i < alanlar.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      alanlar[i],
                    ],
                  ],
                ),
              ),
          ],
        ),
      );
}

class _SayiAlani extends StatelessWidget {
  const _SayiAlani({
    required this.etiket,
    required this.ipucu,
    required this.denetleyici,
    required this.onDegis,
    this.sonEk,
  });

  final String etiket;
  final String ipucu;
  final String? sonEk;
  final TextEditingController denetleyici;
  final ValueChanged<String> onDegis;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiket, style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: denetleyici,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
            onChanged: onDegis,
            style: PusulaYazi.metin(16, agirlik: FontWeight.w700),
            decoration: InputDecoration(
              hintText: ipucu,
              hintStyle: PusulaYazi.metin(14, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
              suffixText: sonEk,
              suffixStyle: PusulaYazi.metin(16, agirlik: FontWeight.w700),
              filled: true,
              fillColor: PusulaRenk.zemin,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
              ),
            ),
          ),
        ],
      );
}

class _Dokum extends StatelessWidget {
  const _Dokum({required this.sonuc});

  final MaasSonucu sonuc;

  @override
  Widget build(BuildContext context) {
    final kalemler = <(String, double, bool)>[
      ('Gösterge aylığı', sonuc.gostergeAyligi, false),
      ('Ek gösterge aylığı', sonuc.ekGostergeAyligi, false),
      ('Taban aylık', sonuc.tabanAylik, false),
      ('Kıdem aylığı', sonuc.kidemAyligi, false),
      ('Yan ödeme', sonuc.yanOdeme, false),
      ('Özel hizmet tazminatı', sonuc.ozelHizmetTazminati, false),
      ('Diğer ödemeler', sonuc.digerBrut, false),
      ('Emeklilik payı (%9)', sonuc.emeklilikPayi, true),
      ('Genel sağlık sigortası (%5)', sonuc.gss, true),
      ('Gelir vergisi', sonuc.gelirVergisi, true),
      ('Damga vergisi', sonuc.damgaVergisi, true),
    ];

    Widget satir(String ad, double v, bool kesinti) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(ad, style: PusulaYazi.metin(14, agirlik: FontWeight.w500)),
              Text('${kesinti ? '−' : ''}${liraTam(v)}',
                  style: PusulaYazi.metin(14, renk: kesinti ? PusulaRenk.kirmizi : PusulaRenk.lacivert, agirlik: FontWeight.w700)),
            ],
          ),
        );

    return PusulaKart(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Döküm', style: PusulaYazi.baslik(16, agirlik: FontWeight.w700, aralik: -0.4)),
          const SizedBox(height: 6),
          for (final (ad, v, k) in kalemler)
            if (v > 0.005) satir(ad, v, k),
          const Divider(color: PusulaRenk.cizgi, thickness: 1.5, height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Brüt', style: PusulaYazi.metin(14, agirlik: FontWeight.w700)),
              Text(liraTam(sonuc.brut), style: PusulaYazi.metin(14, agirlik: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Net', style: PusulaYazi.metin(15, agirlik: FontWeight.w700)),
              Text(liraTam(sonuc.net), style: PusulaYazi.baslik(16, aralik: -0.4)),
            ],
          ),
        ],
      ),
    );
  }
}
