import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/bilesenler.dart';
import '../../../core/hareket.dart';
import '../../../core/sayi_adimi.dart';
import '../../../core/metin.dart';
import '../../../core/tema.dart';
import '../../../core/ucgenler.dart';
import '../../../core/yukselen.dart';
import '../domain/gosterge_tablosu.dart';
import '../domain/maas_parametreleri.dart';
import '../domain/memur_maas_hesaplayici.dart';
import '../domain/ucretli_maas_hesaplayici.dart';

/// Maaş hesaplayıcısı. Memurlar için derece, kademe ve bordrodan bilinen kalemlerle tahmini brüt/net;
/// 4/B sözleşmeli ve işçiler için (ücretleri sözleşmeye bağlı olduğundan) bordrodaki aylık brüt ücretten
/// tahmini net.
class MaasSayfasi extends StatefulWidget {
  const MaasSayfasi({
    super.key,
    this.hesaplayici = const MemurMaasHesaplayici(),
    this.ucretliHesaplayici = const UcretliMaasHesaplayici(),
    this.baslangicGrup = 0,
    this.kayitliBrut,
    this.kaydetBrut,
    this.ay,
    this.baslangic = const MaasGirdisi(derece: 8, kademe: 3, hizmetYili: 10),
    this.kayitliGirdi,
    this.kaydet,
    this.haberler,
  });

  final MemurMaasHesaplayici hesaplayici;
  final UcretliMaasHesaplayici ucretliHesaplayici;

  /// Açılışta seçili görev grubu: 0 memur, 1 sözleşmeli, 2 işçi.
  final int baslangicGrup;

  /// Profilde kayıtlı aylık brüt ücret (sözleşmeli/işçi); "Profilime kaydet" bununla karşılaştırılır.
  final double? kayitliBrut;

  /// Brüt ücreti profile kaydeder; boşsa düğme gösterilmez.
  final ValueChanged<double>? kaydetBrut;

  /// Kümülatif vergi için ay (1-12); boşsa bugünün ayı.
  final int? ay;
  final MaasGirdisi baslangic;

  /// Profilde kayıtlı girdi (varsa); değişiklik bununla karşılaştırılır.
  final MaasGirdisi? kayitliGirdi;

  /// "Profilime kaydet" düğmesi; boşsa düğme gösterilmez.
  final ValueChanged<MaasGirdisi>? kaydet;

  /// Sayfanın altında gösterilen haber bölümü (isteğe bağlı).
  final Widget? haberler;

  @override
  State<MaasSayfasi> createState() => _MaasSayfasiState();
}

class _MaasSayfasiState extends State<MaasSayfasi> {
  static const _gruplar = ['Memur (657)', 'Sözleşmeli', 'İşçi'];

  late MaasGirdisi _g = widget.baslangic;
  late MaasGirdisi? _kayitli = widget.kayitliGirdi;
  late int _grup = widget.baslangicGrup;
  bool _gelismis = false;
  late double? _kayitliBrut = widget.kayitliBrut;

  late final _brut = TextEditingController(
    text: widget.kayitliBrut == null || widget.kayitliBrut! <= 0 ? '' : widget.kayitliBrut!.round().toString(),
  );

  late final _ekGosterge = TextEditingController(text: _metin(_g.ekGosterge));
  late final _yanOdeme = TextEditingController(text: _metin(_g.yanOdemePuani));
  late final _tazminat = TextEditingController(text: _metin((_g.ozelHizmetTazminatiOrani * 100).round()));
  late final _diger = TextEditingController(text: _metin(_g.digerBrut.round()));

  static String _metin(int v) => v == 0 ? '' : '$v';

  @override
  void dispose() {
    _brut.dispose();
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
    final brutDeger = _sayi(_brut.text);
    final u = !memur && brutDeger > 0 ? widget.ucretliHesaplayici.hesapla(brutDeger, ay: ay) : null;

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
            Yukselen(
              gecikme: const Duration(milliseconds: 80),
              child: _SonucKarti(net: s.net, brut: s.brut, kesinti: s.kesintiToplami),
            )
          else if (u != null)
            Yukselen(
              gecikme: const Duration(milliseconds: 80),
              child: _SonucKarti(net: u.net, brut: u.brut, kesinti: u.kesintiToplami),
            )
          else
            const Yukselen(gecikme: Duration(milliseconds: 80), child: _BrutIste()),
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
                      child: _Secenek(etiket: _gruplar[i], secili: i == _grup, onTap: () => setState(() => _grup = i)),
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
              child: SayiAdimi(
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
              child: SayiAdimi(
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
            if (widget.kaydet != null) ...[
              const SizedBox(height: 14),
              BirincilDugme(
                yukseklik: 54,
                ikon: _g == _kayitli ? LucideIcons.check : LucideIcons.save,
                metin: _g == _kayitli ? 'Profilinde kayıtlı' : 'Bilgilerimi profilime kaydet',
                zemin: _g == _kayitli ? PusulaRenk.yesilZemin : PusulaRenk.lacivert,
                yazi: _g == _kayitli ? PusulaRenk.yesilYazi : PusulaRenk.beyaz,
                onPressed: _g == _kayitli
                    ? () {}
                    : () {
                        widget.kaydet!(_g);
                        setState(() => _kayitli = _g);
                      },
              ),
              const SizedBox(height: 6),
              Text(
                'Kaydedersen ana sayfada tahmini net maaşını görürsün. Bilgiler yalnızca bu cihazda saklanır.',
                textAlign: TextAlign.center,
                style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
              ),
            ],
            const SizedBox(height: 14),
            _Not(
              'Tahmini hesap: bordrondaki net tutar geçerlidir. Katsayılar: ${p.kaynak}. '
              'Aile/çocuk yardımı ve kişisel kalemler dahil değil; aylık tutar yıl boyunca sabit kabul edilir.',
            ),
          ] else ...[
            const SizedBox(height: 14),
            Yukselen(
              gecikme: const Duration(milliseconds: 200),
              child: _Bolum(
                baslik: 'Aylık brüt ücret',
                child: _SayiAlani(
                  etiket: 'Bordrondaki brüt ücret',
                  ipucu: 'Ör. 45000',
                  sonEk: '₺',
                  denetleyici: _brut,
                  onDegis: (_) => setState(() {}),
                ),
              ),
            ),
            if (u != null) ...[const SizedBox(height: 14), _UcretliDokum(sonuc: u, parametreler: p)],
            if (widget.kaydetBrut != null && u != null) ...[
              const SizedBox(height: 14),
              Builder(
                builder: (context) {
                  final kayitli = _kayitliBrut != null && (_kayitliBrut! - brutDeger).abs() < 0.005;
                  return BirincilDugme(
                    yukseklik: 54,
                    ikon: kayitli ? LucideIcons.check : LucideIcons.save,
                    metin: kayitli ? 'Profilinde kayıtlı' : 'Bilgilerimi profilime kaydet',
                    zemin: kayitli ? PusulaRenk.yesilZemin : PusulaRenk.lacivert,
                    yazi: kayitli ? PusulaRenk.yesilYazi : PusulaRenk.beyaz,
                    onPressed: kayitli
                        ? () {}
                        : () {
                            widget.kaydetBrut!(brutDeger);
                            setState(() => _kayitliBrut = brutDeger);
                          },
                  );
                },
              ),
              const SizedBox(height: 6),
              Text(
                'Kaydedersen ana sayfada tahmini net maaşını görürsün. Bilgiler yalnızca bu cihazda saklanır.',
                textAlign: TextAlign.center,
                style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
              ),
            ],
            const SizedBox(height: 14),
            _Not(
              'Tahmini hesap: bordrondaki net tutar geçerlidir. SGK işçi payı %14 ve işsizlik sigortası %1 '
              '(5510 sayılı Kanun md. 81 ve 82; prime esas kazanç üst sınırı ${liraTam(p.asgariUcretBrut * p.sgkTavanKati)}), '
              'damga vergisi binde 7,59 ve kümülatif gelir vergisi (GİB 2026 ücret tarifesi) uygulanır; asgari ücrete '
              'isabet eden kısım gelir ve damga vergisinden istisnadır. Sendika aidatı, icra/nafaka, özel sigorta ve '
              'engelli indirimi gibi kişisel kalemler dahil değil; aylık ücret yıl boyunca sabit kabul edilir. '
              'Sözleşmeli personelin ücreti sözleşmesine bağlıdır, bordrondaki brüt tutarı gir.',
            ),
          ],
          if (widget.haberler != null) widget.haberler!,
        ],
      ),
    );
  }
}

class _SonucKarti extends StatelessWidget {
  const _SonucKarti({required this.net, required this.brut, required this.kesinti});

  final double net;
  final double brut;
  final double kesinti;

  @override
  Widget build(BuildContext context) {
    final hareketsiz = MediaQuery.disableAnimationsOf(context);
    final netOran = brut <= 0 ? 0.0 : (net / brut).clamp(0.0, 1.0);
    final netFlex = (netOran * 1000).round().clamp(1, 999);

    return Semantics(
      label: 'Tahmini net maaş ${binlik(net)} lira',
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
                  Row(
                    children: [
                      const Icon(LucideIcons.wallet, size: 18, color: Color(0xFFDCE3FF)),
                      const SizedBox(width: 8),
                      Text('Tahmini net maaş', style: PusulaYazi.metin(13, renk: const Color(0xFFDCE3FF))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SayiSayaci(
                    deger: net,
                    bicim: liraTam,
                    stil: PusulaYazi.baslik(
                      44,
                      renk: PusulaRenk.beyaz,
                      aralik: -2,
                    ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                  const SizedBox(height: 10),
                  // Net/kesinti çubuğu: oran değişince amber kısım akıcı biçimde uzar ya da kısalır.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: netFlex / 1000),
                      duration: hareketsiz ? Duration.zero : const Duration(milliseconds: 650),
                      curve: Curves.easeOutCubic,
                      builder: (context, oran, _) {
                        final amber = (oran * 1000).round().clamp(1, 999);
                        return Row(
                          children: [
                            Expanded(flex: amber, child: Container(height: 8, color: PusulaRenk.amber)),
                            const SizedBox(width: 2),
                            Expanded(flex: 1000 - amber, child: Container(height: 8, color: PusulaRenk.lacivert)),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_EtiketDeger('Net', net), _EtiketDeger('Kesinti', kesinti), _EtiketDeger('Brüt', brut)],
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
  Widget build(BuildContext context) => SayiSayaci(
    deger: deger,
    bicim: (v) => '$etiket ${liraTam(v)}',
    sure: const Duration(milliseconds: 800),
    stil: PusulaYazi.metin(12, renk: const Color(0xFFDCE3FF), agirlik: FontWeight.w700),
  );
}

class _BrutIste extends StatelessWidget {
  const _BrutIste();

  @override
  Widget build(BuildContext context) => PusulaKart(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(LucideIcons.info, size: 20, color: PusulaRenk.lacivert),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Sözleşmeli personelin ve işçinin ücreti sözleşmeye göre belirlenir. Bordronda yazan aylık brüt '
            'ücretini aşağıya gir; SGK, işsizlik, gelir ve damga vergisi kesintilerini hesaplayıp tahmini net '
            'ücretini göstereyim.',
            style: PusulaYazi.metin(14).copyWith(height: 1.4),
          ),
        ),
      ],
    ),
  );
}

class _Not extends StatelessWidget {
  const _Not(this.metin);

  final String metin;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 1),
        child: Icon(LucideIcons.info, size: 18, color: PusulaRenk.soluk),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          metin,
          style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500).copyWith(height: 1.4),
        ),
      ),
    ],
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
      Text(
        baslik,
        style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w700),
      ),
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
    onTap: onTap,
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
          child: Center(
            child: Text('$n', style: PusulaYazi.baslik(14, aralik: 0, agirlik: FontWeight.w700)),
          ),
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
                        Text(
                          'Ek gösterge, yan ödeme, tazminat',
                          style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
                        ),
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
                for (var i = 0; i < alanlar.length; i++) ...[if (i > 0) const SizedBox(height: 10), alanlar[i]],
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
      Text(
        etiket,
        style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w700),
      ),
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
          Text(
            '${kesinti ? '−' : ''}${liraTam(v)}',
            style: PusulaYazi.metin(
              14,
              renk: kesinti ? PusulaRenk.kirmizi : PusulaRenk.lacivert,
              agirlik: FontWeight.w700,
            ),
          ),
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

class _UcretliDokum extends StatelessWidget {
  const _UcretliDokum({required this.sonuc, required this.parametreler});

  final UcretliSonucu sonuc;
  final MaasParametreleri parametreler;

  @override
  Widget build(BuildContext context) {
    Widget satir(String ad, double v, {bool kesinti = true}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(ad, style: PusulaYazi.metin(14, agirlik: FontWeight.w500)),
          Text(
            '${kesinti ? '−' : ''}${liraTam(v)}',
            style: PusulaYazi.metin(
              14,
              renk: kesinti ? PusulaRenk.kirmizi : PusulaRenk.lacivert,
              agirlik: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    final sgkYuzde = (parametreler.isciSgkPayi * 100).round();
    final issizlikYuzde = (parametreler.issizlikPayi * 100).round();
    return PusulaKart(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Döküm', style: PusulaYazi.baslik(16, agirlik: FontWeight.w700, aralik: -0.4)),
          const SizedBox(height: 6),
          satir('Brüt ücret', sonuc.brut, kesinti: false),
          satir('SGK işçi payı (%$sgkYuzde)', sonuc.sgkPayi),
          satir('İşsizlik sigortası (%$issizlikYuzde)', sonuc.issizlik),
          if (sonuc.gelirVergisi > 0.005) satir('Gelir vergisi', sonuc.gelirVergisi),
          if (sonuc.damgaVergisi > 0.005) satir('Damga vergisi', sonuc.damgaVergisi),
          const Divider(color: PusulaRenk.cizgi, thickness: 1.5, height: 18),
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
