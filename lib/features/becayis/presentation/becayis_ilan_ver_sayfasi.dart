import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/bilesenler.dart';
import '../../../core/tema.dart';
import '../../../core/ucgenler.dart';
import '../../../core/yukselen.dart';
import '../data/becayis_deposu.dart';

/// İlan oluşturma/düzenleme: profilden gelen bilgiler, mavi tik doğrulaması,
/// tercih sırasıyla hedef iller ve 3'lü zincir izni.
class BecayisIlanVerSayfasi extends StatefulWidget {
  const BecayisIlanVerSayfasi({super.key, required this.depo});

  final BecayisDeposu depo;

  @override
  State<BecayisIlanVerSayfasi> createState() => _BecayisIlanVerSayfasiState();
}

class _BecayisIlanVerSayfasiState extends State<BecayisIlanVerSayfasi> {
  static const _iller = [
    'Ankara', 'İstanbul', 'Bursa', 'Eskişehir', 'Manisa',
    'Aydın', 'Denizli', 'Antalya', 'Konya', 'Muğla',
  ];

  /// Seçim sırası tercih sırasıdır: ilk seçilen en çok istenen.
  late final List<String> _secili = [...widget.depo.benim.hedefIller];
  late bool _zincir = widget.depo.benim.zincirIzni;
  bool _yayinlandi = false;

  void _ilDegistir(String il) => setState(() {
        if (!_secili.remove(il)) _secili.add(il);
      });

  void _yayinla() {
    widget.depo.ilanYayinla(hedefIller: List.of(_secili), zincirIzni: _zincir);
    setState(() => _yayinlandi = true);
  }

  Future<void> _dogrula() async {
    if (widget.depo.epostam.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce profilinde kurumsal e-posta adresini gir.')),
      );
      return;
    }
    await AltSayfa.goster<void>(
      context,
      builder: (c) => _DogrulamaSayfasi(depo: widget.depo),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.depo,
        builder: (context, _) {
          final ilan = widget.depo.benim;
          return Scaffold(
            body: Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(18, 24, 18, 16),
                          children: [
                            const Yukselen(child: GeriBaslik(ustYazi: 'Becayiş ilanı', baslik: 'İlan ver')),
                            const SizedBox(height: 14),
                            Yukselen(
                              gecikme: const Duration(milliseconds: 80),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(LucideIcons.badgeCheck, size: 20, color: PusulaRenk.mavi),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Bilgilerin Pusula profilinden geldi; ilanda tekrar yazmana gerek yok.',
                                      style: PusulaYazi.metin(13, renk: PusulaRenk.soluk),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Yukselen(
                              gecikme: const Duration(milliseconds: 140),
                              child: PusulaKart(
                                padding: EdgeInsets.zero,
                                child: Column(
                                  children: [
                                    _Alan('UNVAN', ilan.unvan, LucideIcons.user),
                                    _Alan('KURUM', ilan.kurumAdi, LucideIcons.briefcase),
                                    _Alan('SINIF', ilan.sinif, LucideIcons.users),
                                    _Alan('MEVCUT İL', ilan.mevcutIl, LucideIcons.mapPin, son: true),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Yukselen(
                              gecikme: const Duration(milliseconds: 170),
                              child: _MaviTikSatiri(dogrulandi: ilan.maviTik, onDogrula: _dogrula),
                            ),
                            const SizedBox(height: 16),
                            Yukselen(
                              gecikme: const Duration(milliseconds: 200),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Gitmek istediğin iller',
                                      style: PusulaYazi.baslik(18, agirlik: FontWeight.w700, aralik: -0.4)),
                                  Hap('${_secili.length} seçili'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('İlk seçtiğin il en çok istediğin ildir; skor buna göre değişir.',
                                style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)),
                            const SizedBox(height: 10),
                            Yukselen(
                              gecikme: const Duration(milliseconds: 260),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final il in _iller)
                                    _IlDugmesi(
                                      il: il,
                                      secili: _secili.contains(il),
                                      onTap: () => _ilDegistir(il),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Yukselen(
                              gecikme: const Duration(milliseconds: 320),
                              child: PusulaKart(
                                radius: 22,
                                padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("3'lü zincir eşleşme",
                                              style: PusulaYazi.metin(14, agirlik: FontWeight.w700)),
                                          Text('A → B → C → A takaslarını da tara',
                                              style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                    Semantics(
                                      label: "3'lü zincir eşleşme",
                                      child: Switch(
                                        value: _zincir,
                                        onChanged: (v) => setState(() => _zincir = v),
                                        activeThumbColor: PusulaRenk.amber,
                                        activeTrackColor: PusulaRenk.lacivert,
                                        inactiveThumbColor: PusulaRenk.beyaz,
                                        inactiveTrackColor: const Color(0xFFC9CCD6),
                                        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                        child: BirincilDugme(
                          yukseklik: 58,
                          ikon: LucideIcons.send,
                          metin: 'İlanı yayınla · Ücretsiz',
                          onPressed: _secili.isEmpty ? null : _yayinla,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_yayinlandi) _YayindaOrtusu(ilSayisi: _secili.length),
              ],
            ),
          );
        },
      );
}

class _Alan extends StatelessWidget {
  const _Alan(this.etiket, this.deger, this.ikon, {this.son = false});

  final String etiket;
  final String deger;
  final IconData ikon;
  final bool son;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: son ? null : const Border(bottom: BorderSide(color: PusulaRenk.cizgi, width: 1.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: PusulaRenk.zemin, borderRadius: BorderRadius.circular(12)),
              child: Icon(ikon, size: 18, color: PusulaRenk.lacivert),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(etiket,
                      style: PusulaYazi.metin(11, renk: PusulaRenk.soluk, agirlik: FontWeight.w700)),
                  Text(deger,
                      overflow: TextOverflow.ellipsis,
                      style: PusulaYazi.metin(16, agirlik: FontWeight.w700)),
                ],
              ),
            ),
            const Icon(LucideIcons.lock, size: 16, color: PusulaRenk.soluk),
          ],
        ),
      );
}

class _MaviTikSatiri extends StatelessWidget {
  const _MaviTikSatiri({required this.dogrulandi, required this.onDogrula});

  final bool dogrulandi;
  final VoidCallback onDogrula;

  @override
  Widget build(BuildContext context) => PusulaKart(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: dogrulandi ? PusulaRenk.mavi : PusulaRenk.zemin,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(LucideIcons.badgeCheck,
                  size: 20, color: dogrulandi ? PusulaRenk.beyaz : PusulaRenk.soluk),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mavi tik', style: PusulaYazi.metin(14, agirlik: FontWeight.w700)),
                  Text(
                    dogrulandi
                        ? 'İlanın doğrulanmış olarak öne çıkar'
                        : 'Kurumsal e-postanla doğrula; ilanın öne çıksın',
                    style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (dogrulandi)
              const Hap('Doğrulandı',
                  zemin: PusulaRenk.yesilZemin, yazi: PusulaRenk.yesilYazi, ikon: LucideIcons.check)
            else
              SizedBox(
                height: 40,
                child: Material(
                  color: PusulaRenk.lacivert,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onDogrula,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: Text('Doğrula',
                            style: PusulaYazi.metin(13, renk: PusulaRenk.beyaz, agirlik: FontWeight.w700)),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

class _IlDugmesi extends StatelessWidget {
  const _IlDugmesi({required this.il, required this.secili, required this.onTap});

  final String il;
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
              height: 44,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (secili) ...[
                      const Icon(LucideIcons.check, size: 16, color: PusulaRenk.amber),
                      const SizedBox(width: 6),
                    ],
                    Text(il,
                        style: PusulaYazi.metin(
                          14,
                          renk: secili ? PusulaRenk.beyaz : PusulaRenk.lacivert,
                          agirlik: FontWeight.w700,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _YayindaOrtusu extends StatelessWidget {
  const _YayindaOrtusu({required this.ilSayisi});

  final int ilSayisi;

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: Semantics(
          liveRegion: true,
          child: ColoredBox(
            color: PusulaRenk.lacivert,
            child: Stack(
              children: [
                const Positioned(
                  right: -90,
                  top: -80,
                  child: Opacity(opacity: 0.35, child: PusulaUcgenler(boyut: 240, orta: PusulaRenk.mavi)),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(color: PusulaRenk.amber, shape: BoxShape.circle),
                          child: const Icon(LucideIcons.check, size: 46, color: PusulaRenk.lacivert),
                        ),
                        const SizedBox(height: 14),
                        Text('İlanın yayında',
                            style: PusulaYazi.baslik(28, renk: PusulaRenk.beyaz, aralik: -1.2)),
                        const SizedBox(height: 14),
                        Text(
                          'Algoritma $ilSayisi ilde senin için 7/24 eşleşme arıyor. Bulunca bildirim gelecek.',
                          textAlign: TextAlign.center,
                          style: PusulaYazi.metin(15, renk: const Color(0xFFC9D0E0), agirlik: FontWeight.w500),
                        ),
                        const SizedBox(height: 24),
                        BirincilDugme(
                          yukseklik: 56,
                          metin: 'Panele dön',
                          onPressed: () => Navigator.maybePop(context),
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

/// E-posta doğrulama alt sayfası: 6 haneli kod girilir.
class _DogrulamaSayfasi extends StatefulWidget {
  const _DogrulamaSayfasi({required this.depo});

  final BecayisDeposu depo;

  @override
  State<_DogrulamaSayfasi> createState() => _DogrulamaSayfasiState();
}

class _DogrulamaSayfasiState extends State<_DogrulamaSayfasi> {
  final _kod = TextEditingController();
  bool _bekliyor = false;
  String? _hata;

  @override
  void initState() {
    super.initState();
    widget.depo.epostaKoduGonder().then((ok) {
      if (!ok && mounted) {
        setState(() => _hata = 'Yalnızca .gov.tr ve .edu.tr adreslerine kod gönderebiliriz.');
      }
    });
  }

  @override
  void dispose() {
    _kod.dispose();
    super.dispose();
  }

  Future<void> _onayla() async {
    setState(() {
      _bekliyor = true;
      _hata = null;
    });
    final ok = await widget.depo.epostaDogrula(_kod.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        _bekliyor = false;
        _hata = 'Kod hatalı. Tekrar dene.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('E-postanı doğrula', style: PusulaYazi.baslik(22, aralik: -0.9)),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: PusulaYazi.metin(14, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
              children: [
                TextSpan(
                  text: widget.depo.epostam,
                  style: PusulaYazi.metin(14, agirlik: FontWeight.w700),
                ),
                const TextSpan(
                  text: ' adresine 6 haneli kod gönderdik. Yalnızca .gov.tr ve .edu.tr adresleri kabul edilir.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('Doğrulama kodu',
              style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: _kod,
            keyboardType: TextInputType.number,
            maxLength: 6,
            onChanged: (_) => setState(() => _hata = null),
            style: PusulaYazi.baslik(22, aralik: 6, agirlik: FontWeight.w700),
            decoration: InputDecoration(
              counterText: '',
              hintText: '6 haneli kod',
              hintStyle: PusulaYazi.metin(16, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)
                  .copyWith(letterSpacing: 0),
              filled: true,
              fillColor: PusulaRenk.zemin,
              errorText: _hata,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          BirincilDugme(
            yukseklik: 56,
            metin: 'Onayla',
            yukleniyor: _bekliyor,
            yukleniyorMetni: 'Doğrulanıyor',
            onPressed: _kod.text.length == 6 ? _onayla : null,
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _bekliyor ? null : () => Navigator.pop(context),
            child: Text('Şimdi değil',
                style: PusulaYazi.metin(14, agirlik: FontWeight.w700)),
          ),
        ],
      );
}
