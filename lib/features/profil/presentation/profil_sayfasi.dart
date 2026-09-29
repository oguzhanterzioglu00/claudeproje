import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/bilesenler.dart';
import '../../../core/tema.dart';
import '../../../core/yukselen.dart';
import '../data/profil_deposu.dart';
import '../domain/profil.dart';
import 'profil_alanlari.dart';
import 'secim_sayfasi.dart';

/// Profil: statü, görev bilgileri ve (memurlar için) becayiş/dilekçe bilgileri.
/// İlk kurulum için bkz. [IlkKurulumSayfasi].
class ProfilSayfasi extends StatefulWidget {
  const ProfilSayfasi({super.key, required this.depo, this.onBitti});

  final ProfilDeposu depo;

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
                        onTap: () => _sec('Kurum', ProfilSecenekleri.kurumlar, _kurum, (s) => _kurum = s, serbest: true),
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
                      MetinAlani(etiket: 'Unvan', denetleyici: _unvan, ipucu: 'Ör. Hemşire', onDegis: () => setState(() {}), capitalization: TextCapitalization.words),
                      const SizedBox(height: 12),
                      SecimAlani(
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
                      MetinAlani(etiket: 'Sicil no', denetleyici: _sicil, onDegis: () => setState(() {}), sayisal: true),
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
                    if (_mevcut != null) ...[
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
