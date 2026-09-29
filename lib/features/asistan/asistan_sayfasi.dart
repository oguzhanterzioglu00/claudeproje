import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/bilesenler.dart';
import '../../core/tema.dart';
import '../../core/yukselen.dart';
import 'asistan_servisi.dart';

/// "Hakkım ne?": soru sorulur, cevap ilgili mevzuat maddesiyle birlikte gelir.
class AsistanSayfasi extends StatefulWidget {
  const AsistanSayfasi({super.key, this.asistan = const SahteAsistan()});

  final MevzuatAsistani asistan;

  @override
  State<AsistanSayfasi> createState() => _AsistanSayfasiState();
}

class _Mesaj {
  _Mesaj.kullanici(this.metin)
      : benim = true,
        cevap = null,
        bekliyor = false;
  _Mesaj.asistan({this.metin = '', this.cevap, this.bekliyor = false}) : benim = false;

  final bool benim;
  final String metin;
  final AsistanCevabi? cevap;
  final bool bekliyor;
}

class _AsistanSayfasiState extends State<AsistanSayfasi> {
  static const _ornekSorular = [
    ('Becayiş', 'Becayiş şartları nedir?'),
    ('Rapor', 'Rapor kullanımı ile ilgili haklarım neler?'),
    ('Tayin şartları', 'Tayin şartları nelerdir?'),
    ('Emeklilik', 'Emeklilik için ne kadar süre gerekir?'),
    ('Mazeret izni', 'Mazeret izni kaç gün?'),
  ];

  final _soru = TextEditingController();
  final _kaydirma = ScrollController();
  final List<_Mesaj> _mesajlar = [
    _Mesaj.asistan(
      metin: 'Merhaba! Sorunu ilgili mevzuat maddesini bularak, kaynağıyla birlikte yanıtlarım. '
          'Şu an örnek sürümdeyim: yalnızca Becayiş sorusunu gerçek kanun metniyle yanıtlıyorum.',
    ),
  ];
  bool _bekliyor = false;

  @override
  void dispose() {
    _soru.dispose();
    _kaydirma.dispose();
    super.dispose();
  }

  Future<void> _gonder(String soru) async {
    final s = soru.trim();
    if (s.isEmpty || _bekliyor) return;
    _soru.clear();
    setState(() {
      _bekliyor = true;
      _mesajlar
        ..add(_Mesaj.kullanici(s))
        ..add(_Mesaj.asistan(bekliyor: true));
    });
    _asagiKaydir();
    AsistanCevabi cevap;
    try {
      cevap = await widget.asistan.sor(s);
    } catch (_) {
      cevap = const AsistanCevabi(metin: 'Şu an cevap üretemedim. Biraz sonra tekrar dener misin?', ornek: true);
    }
    if (!mounted) return;
    setState(() {
      _mesajlar.removeLast();
      _mesajlar.add(_Mesaj.asistan(cevap: cevap, metin: cevap.metin));
      _bekliyor = false;
    });
    _asagiKaydir();
  }

  void _asagiKaydir() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_kaydirma.hasClients) {
        _kaydirma.animateTo(
          _kaydirma.position.maxScrollExtent,
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 24, 18, 0),
              child: Yukselen(child: _Ust()),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Yukselen(gecikme: Duration(milliseconds: 80), child: _Uyari()),
            ),
            Expanded(
              child: ListView.separated(
                controller: _kaydirma,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                itemCount: _mesajlar.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _MesajBalonu(mesaj: _mesajlar[i]),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: _ornekSorular.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final (etiket, soru) = _ornekSorular[i];
                  return Material(
                    color: PusulaRenk.beyaz,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _bekliyor ? null : () => _gonder(soru),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Center(
                          child: Text(etiket, style: PusulaYazi.metin(13, agirlik: FontWeight.w700)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _soru,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _gonder,
                      style: PusulaYazi.metin(15, agirlik: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Sorunu yaz…',
                        hintStyle: PusulaYazi.metin(15, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
                        filled: true,
                        fillColor: PusulaRenk.beyaz,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
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
                  const SizedBox(width: 10),
                  Semantics(
                    button: true,
                    label: 'Gönder',
                    excludeSemantics: true,
                    child: Material(
                      color: _bekliyor ? PusulaRenk.cizgi : PusulaRenk.amber,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: _bekliyor ? null : () => _gonder(_soru.text),
                        child: const SizedBox.square(
                          dimension: 52,
                          child: Icon(LucideIcons.send, size: 22, color: PusulaRenk.lacivert),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _Ust extends StatelessWidget {
  const _Ust();

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: PusulaRenk.mor, borderRadius: BorderRadius.circular(14)),
            child: const Icon(LucideIcons.sparkles, size: 22, color: PusulaRenk.amber),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hakkım ne?', style: PusulaYazi.baslik(22, aralik: -0.9)),
                Text('Mevzuat asistanı',
                    style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)),
              ],
            ),
          ),
          const OrnekRozeti(),
        ],
      );
}

class _Uyari extends StatelessWidget {
  const _Uyari();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(color: const Color(0xFFFFF1D6), borderRadius: BorderRadius.circular(18)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(LucideIcons.info, size: 18, color: PusulaRenk.lacivert),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cevaplar ilgili mevzuat maddesiyle birlikte gelir. Hukuki tavsiye değildir.',
                style: PusulaYazi.metin(13),
              ),
            ),
          ],
        ),
      );
}

class _MesajBalonu extends StatelessWidget {
  const _MesajBalonu({required this.mesaj});

  final _Mesaj mesaj;

  @override
  Widget build(BuildContext context) {
    if (mesaj.benim) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: PusulaRenk.lacivert,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: Text(mesaj.metin, style: PusulaYazi.metin(15, renk: PusulaRenk.beyaz, agirlik: FontWeight.w500)),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: PusulaRenk.mor, borderRadius: BorderRadius.circular(12)),
          child: const Icon(LucideIcons.sparkles, size: 18, color: PusulaRenk.amber),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: PusulaRenk.beyaz,
                border: Border.all(color: PusulaRenk.lacivert, width: 1.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(22),
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
              ),
              child: mesaj.bekliyor ? const _Yaziyor() : _CevapIcerigi(mesaj: mesaj),
            ),
          ),
        ),
      ],
    );
  }
}

class _Yaziyor extends StatelessWidget {
  const _Yaziyor();

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: PusulaRenk.mor.withValues(alpha: 0.4 + 0.3 * i),
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 6),
          Text('Mevzuat taranıyor…', style: PusulaYazi.metin(13, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)),
        ],
      );
}

class _CevapIcerigi extends StatelessWidget {
  const _CevapIcerigi({required this.mesaj});

  final _Mesaj mesaj;

  @override
  Widget build(BuildContext context) {
    final c = mesaj.cevap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (c != null && c.ornek) ...[
          const Hap('ÖRNEK CEVAP', zemin: PusulaRenk.cizgi, yazi: PusulaRenk.lacivert),
          const SizedBox(height: 8),
        ],
        Text(mesaj.metin, style: PusulaYazi.metin(15, agirlik: FontWeight.w500).copyWith(height: 1.4)),
        if (c != null)
          for (final k in c.kaynaklar) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: PusulaRenk.zemin, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.bookOpen, size: 16, color: PusulaRenk.mor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(k.baslik,
                            style: PusulaYazi.metin(12, renk: PusulaRenk.mor, agirlik: FontWeight.w700)),
                      ),
                    ],
                  ),
                  if (k.alinti != null) ...[
                    const SizedBox(height: 6),
                    Text('“${k.alinti}”',
                        style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)
                            .copyWith(height: 1.4, fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
          ],
      ],
    );
  }
}
