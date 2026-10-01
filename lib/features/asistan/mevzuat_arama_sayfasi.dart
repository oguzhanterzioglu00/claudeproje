import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/bilesenler.dart';
import '../../core/bos_durum.dart';
import '../../core/tema.dart';
import '../../core/yukselen.dart';
import '../araclar/presentation/arac_parcalari.dart';
import 'bilgi_bankasi.dart';
import 'mevzuat_arama.dart';

/// Mevzuat arama: doğrulanmış kanun alıntıları içinde anahtar sözcükle arama. Sonuca dokununca maddenin alıntısı
/// tam olarak açılır ve kopyalanabilir.
class MevzuatAramaSayfasi extends StatefulWidget {
  const MevzuatAramaSayfasi({super.key, this.kitle, this.baslangicSorgu = ''});

  final Kitle? kitle;
  final String baslangicSorgu;

  @override
  State<MevzuatAramaSayfasi> createState() => _MevzuatAramaSayfasiState();
}

class _MevzuatAramaSayfasiState extends State<MevzuatAramaSayfasi> {
  late final _sorgu = TextEditingController(text: widget.baslangicSorgu);

  static const _oneriler = ['yıllık izin', 'aylıksız izin', 'kademe', 'disiplin', 'becayiş', 'kıdem tazminatı', 'mazeret'];

  @override
  void dispose() {
    _sorgu.dispose();
    super.dispose();
  }

  void _ac(AramaSonucu s) => AltSayfa.goster<void>(context, builder: (c) => _Madde(sonuc: s));

  @override
  Widget build(BuildContext context) {
    final metin = _sorgu.text.trim();
    final sonuclar = MevzuatArama.ara(metin, kitle: widget.kitle);
    final baslamadi = metin.length < 2;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
          children: [
            const Yukselen(child: GeriBaslik(ustYazi: 'Doğrulanmış kanun metinleri', baslik: 'Mevzuat ara', sag: SizedBox.shrink())),
            const SizedBox(height: 14),
            Yukselen(
              gecikme: const Duration(milliseconds: 80),
              child: TextField(
                controller: _sorgu,
                autofocus: widget.baslangicSorgu.isEmpty,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                style: PusulaYazi.metin(15, agirlik: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Örn. yıllık izin, kademe, 74. madde',
                  hintStyle: PusulaYazi.metin(15, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
                  prefixIcon: const Icon(LucideIcons.search, size: 20, color: PusulaRenk.lacivert),
                  suffixIcon: metin.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Temizle',
                          icon: const Icon(LucideIcons.x, size: 18, color: PusulaRenk.soluk),
                          onPressed: () => setState(_sorgu.clear),
                        ),
                  filled: true,
                  fillColor: PusulaRenk.beyaz,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (baslamadi) ...[
              Text('Sık aranan', style: PusulaYazi.metin(13, renk: PusulaRenk.soluk, agirlik: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final o in _oneriler)
                    Material(
                      color: PusulaRenk.beyaz,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() => _sorgu.text = o),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Text(o, style: PusulaYazi.metin(13, agirlik: FontWeight.w700)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const NotSatiri(
                'Aramalar uygulamadaki doğrulanmış kanun alıntıları içinde yapılır. Her kanun ve madde burada yoktur; '
                'bulamadığın bir konu için resmî kaynağa (mevzuat.gov.tr) bak.',
              ),
            ] else if (sonuclar.isEmpty)
              const BosDurum(
                gorsel: BosGorselTuru.arama,
                baslik: 'Sonuç bulunamadı',
                alt: 'Başka bir sözcük dene. Tüm sözcüklerin aynı maddede geçmesi gerekir.',
              )
            else ...[
              Text(
                '${sonuclar.length} madde bulundu',
                style: PusulaYazi.metin(13, renk: PusulaRenk.soluk, agirlik: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (final (i, s) in sonuclar.indexed) ...[
                Yukselen(
                  key: ValueKey('${s.kaynak.baslik}-${s.konu.id}'),
                  gecikme: Duration(milliseconds: i < 8 ? i * 50 : 0),
                  child: _SonucKarti(sonuc: s, onTap: () => _ac(s)),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SonucKarti extends StatelessWidget {
  const _SonucKarti({required this.sonuc, required this.onTap});

  final AramaSonucu sonuc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stil = PusulaYazi.metin(13, agirlik: FontWeight.w500).copyWith(height: 1.45);
    final parcalar = <InlineSpan>[];
    var son = 0;
    for (final (b, e) in sonuc.vurgular) {
      if (b > son) parcalar.add(TextSpan(text: sonuc.parca.substring(son, b)));
      parcalar.add(
        TextSpan(
          text: sonuc.parca.substring(b, e),
          style: const TextStyle(backgroundColor: Color(0xFFFFE2A8), fontWeight: FontWeight.w800),
        ),
      );
      son = e;
    }
    if (son < sonuc.parca.length) parcalar.add(TextSpan(text: sonuc.parca.substring(son)));

    return Semantics(
      container: true,
      button: true,
      label: '${sonuc.kaynak.baslik}. ${sonuc.parca}',
      excludeSemantics: true,
      onTap: onTap,
      child: PusulaKart(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hap(sonuc.konu.etiket, zemin: PusulaRenk.zemin, yazi: PusulaRenk.lacivert, boyut: 11),
            const SizedBox(height: 8),
            Text(sonuc.kaynak.baslik, style: PusulaYazi.metin(14, agirlik: FontWeight.w800).copyWith(height: 1.25)),
            if (sonuc.parca.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text.rich(TextSpan(style: stil, children: parcalar)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Maddenin alıntısı ve kopyalama.
class _Madde extends StatelessWidget {
  const _Madde({required this.sonuc});

  final AramaSonucu sonuc;

  @override
  Widget build(BuildContext context) {
    final alinti = sonuc.kaynak.alinti ?? '';
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(sonuc.kaynak.baslik, style: PusulaYazi.baslik(18, aralik: -0.6)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: PusulaRenk.zemin, borderRadius: BorderRadius.circular(18)),
              child: SelectableText(alinti, style: PusulaYazi.metin(14, agirlik: FontWeight.w500).copyWith(height: 1.5)),
            ),
            const SizedBox(height: 10),
            NotSatiri('${_surum(sonuc.konu)} Kanun değiştikçe güncellenmelidir; işlem yapmadan önce resmî kaynağı doğrula.'),
            const SizedBox(height: 14),
            BirincilDugme(
              metin: 'Alıntıyı kopyala',
              ikon: LucideIcons.copy,
              yukseklik: 52,
              onPressed: () async {
                final mesaj = ScaffoldMessenger.of(context);
                await Clipboard.setData(ClipboardData(text: '${sonuc.kaynak.baslik}\n\n$alinti'));
                mesaj.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Alıntı panoya kopyalandı.',
                      style: PusulaYazi.metin(14, renk: PusulaRenk.beyaz, agirlik: FontWeight.w600),
                    ),
                    backgroundColor: PusulaRenk.lacivert,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _surum(BilgiKonusu k) => k.surum ?? '${BilgiBankasi.surum}.';
}
