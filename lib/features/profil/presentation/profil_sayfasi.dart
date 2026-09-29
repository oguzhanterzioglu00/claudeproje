import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/bilesenler.dart';
import '../../../core/tema.dart';
import '../../../core/yukselen.dart';
import '../data/profil_deposu.dart';
import '../domain/profil.dart';
import 'secim_sayfasi.dart';

/// Profil: statü, görev bilgileri ve (memurlar için) becayiş/dilekçe bilgileri.
/// [ilkKurulum] true ise geri düğmesi yoktur ve düğme "Başla" der.
class ProfilSayfasi extends StatefulWidget {
  const ProfilSayfasi({super.key, required this.depo, this.ilkKurulum = false, this.onBitti});

  final ProfilDeposu depo;
  final bool ilkKurulum;

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
    final s = await SecimSayfasi.goster(context, baslik: baslik, secenekler: secenekler, secili: secili, serbest: serbest);
    if (s != null) setState(() => yaz(s));
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
    if (mounted && !widget.ilkKurulum) Navigator.of(context).popUntil((r) => r.isFirst);
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
                    Yukselen(
                      child: widget.ilkKurulum
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Kamu Pusulası',
                                    style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w700)),
                                Text('Hoş geldin', style: PusulaYazi.baslik(30, aralik: -1.4)),
                                const SizedBox(height: 6),
                                Text(
                                  'Sana uygun maaş, hak ve ilan bilgilerini gösterebilmemiz için birkaç bilgiye ihtiyacımız var.',
                                  style: PusulaYazi.metin(14, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)
                                      .copyWith(height: 1.4),
                                ),
                              ],
                            )
                          : const GeriBaslik(ustYazi: 'Kamu Pusulası', baslik: 'Profilim', sag: SizedBox.shrink()),
                    ),
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
                    _MetinAlani(
                      etiket: 'Adın',
                      denetleyici: _ad,
                      onDegis: () => setState(() {}),
                      capitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    Text('Statün', style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w700)),
                    const SizedBox(height: 8),
                    for (final s in Statu.values) ...[
                      _StatuKarti(statu: s, secili: s == _statu, onTap: () => setState(() => _statu = s)),
                      const SizedBox(height: 8),
                    ],
                    if (_memur) ...[
                      const SizedBox(height: 4),
                      PusulaKart(
                        radius: 20,
                        padding: const EdgeInsets.fromLTRB(16, 6, 10, 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text('Memurluğumun asaleti henüz onaylanmadı (aday memurum)',
                                  style: PusulaYazi.metin(13, agirlik: FontWeight.w600)),
                            ),
                            Switch(
                              value: _aday,
                              onChanged: (v) => setState(() => _aday = v),
                              activeThumbColor: PusulaRenk.amber,
                              activeTrackColor: PusulaRenk.lacivert,
                              inactiveThumbColor: PusulaRenk.beyaz,
                              inactiveTrackColor: const Color(0xFFC9CCD6),
                              trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_statu != null) ...[
                      const SizedBox(height: 20),
                      Text('Görev bilgilerin', style: PusulaYazi.baslik(18, agirlik: FontWeight.w700, aralik: -0.4)),
                      const SizedBox(height: 10),
                      _SecimAlani(
                        etiket: 'Kurum',
                        deger: _kurum,
                        ipucu: 'Kurumunu seç veya yaz',
                        onTap: () => _sec('Kurum', ProfilSecenekleri.kurumlar, _kurum, (s) => _kurum = s, serbest: true),
                      ),
                      if (_memur) ...[
                        const SizedBox(height: 12),
                        _SecimAlani(
                          etiket: 'Hizmet sınıfı',
                          deger: _sinif,
                          ipucu: 'Sınıfını seç',
                          onTap: () => _sec('Hizmet sınıfı', ProfilSecenekleri.siniflar, _sinif, (s) => _sinif = s),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _MetinAlani(etiket: 'Unvan', denetleyici: _unvan, ipucu: 'Ör. Hemşire', onDegis: () => setState(() {}), capitalization: TextCapitalization.words),
                      const SizedBox(height: 12),
                      _SecimAlani(
                        etiket: 'Çalıştığın il',
                        deger: _il,
                        ipucu: 'İlini seç',
                        onTap: () => _sec('İl', ProfilSecenekleri.iller, _il, (s) => _il = s),
                      ),
                    ],
                    if (_memur) ...[
                      const SizedBox(height: 20),
                      Text('Becayiş ve dilekçe', style: PusulaYazi.baslik(18, agirlik: FontWeight.w700, aralik: -0.4)),
                      const SizedBox(height: 4),
                      Text('Yalnızca becayiş dilekçeni doldurmak ve ilanını doğrulamak için kullanılır.',
                          style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)),
                      const SizedBox(height: 10),
                      _MetinAlani(etiket: 'Sicil no', denetleyici: _sicil, onDegis: () => setState(() {}), sayisal: true),
                      const SizedBox(height: 12),
                      _MetinAlani(
                        etiket: 'Kurumsal e-posta',
                        denetleyici: _eposta,
                        ipucu: 'ad.soyad@kurum.gov.tr',
                        onDegis: () => setState(() {}),
                        eposta: true,
                        hata: _epostaGecerli ? null : 'Geçerli bir e-posta adresi gir',
                      ),
                    ],
                    if (!widget.ilkKurulum && _mevcut != null) ...[
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton.icon(
                          onPressed: _sil,
                          icon: const Icon(LucideIcons.trash2, size: 18, color: PusulaRenk.kirmizi),
                          label: Text('Profilimi sil',
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
                  metin: widget.ilkKurulum ? 'Başla' : 'Kaydet',
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

class _StatuKarti extends StatelessWidget {
  const _StatuKarti({required this.statu, required this.secili, required this.onTap});

  final Statu statu;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: secili,
        child: Material(
          color: secili ? PusulaRenk.lacivert : PusulaRenk.beyaz,
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
                    Expanded(
                      child: Text(
                        statu.etiket,
                        style: PusulaYazi.metin(
                          14,
                          renk: secili ? PusulaRenk.beyaz : PusulaRenk.lacivert,
                          agirlik: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (secili) const Icon(LucideIcons.check, size: 20, color: PusulaRenk.amber),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _MetinAlani extends StatelessWidget {
  const _MetinAlani({
    required this.etiket,
    required this.denetleyici,
    required this.onDegis,
    this.ipucu,
    this.hata,
    this.sayisal = false,
    this.eposta = false,
    this.capitalization = TextCapitalization.none,
  });

  final String etiket;
  final TextEditingController denetleyici;
  final VoidCallback onDegis;
  final String? ipucu;
  final String? hata;
  final bool sayisal;
  final bool eposta;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiket, style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: denetleyici,
            onChanged: (_) => onDegis(),
            textCapitalization: capitalization,
            keyboardType: eposta
                ? TextInputType.emailAddress
                : sayisal
                    ? TextInputType.number
                    : TextInputType.text,
            style: PusulaYazi.metin(16, agirlik: FontWeight.w700),
            decoration: InputDecoration(
              hintText: ipucu,
              hintStyle: PusulaYazi.metin(14, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
              errorText: hata,
              filled: true,
              fillColor: PusulaRenk.beyaz,
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

class _SecimAlani extends StatelessWidget {
  const _SecimAlani({required this.etiket, required this.deger, required this.ipucu, required this.onTap});

  final String etiket;
  final String deger;
  final String ipucu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiket, style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w700)),
          const SizedBox(height: 6),
          Semantics(
            container: true,
            button: true,
            label: '$etiket: ${deger.isEmpty ? 'seçilmedi' : deger}',
            excludeSemantics: true,
            child: Material(
              color: PusulaRenk.beyaz,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: SizedBox(
                  height: 50,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            deger.isEmpty ? ipucu : deger,
                            overflow: TextOverflow.ellipsis,
                            style: deger.isEmpty
                                ? PusulaYazi.metin(14, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)
                                : PusulaYazi.metin(16, agirlik: FontWeight.w700),
                          ),
                        ),
                        const Icon(LucideIcons.chevronDown, size: 20, color: PusulaRenk.lacivert),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}
