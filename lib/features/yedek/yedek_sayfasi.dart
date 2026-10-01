import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/bilesenler.dart';
import '../../core/tema.dart';
import 'yedek_paketi.dart';

/// "Yedekten yükle" alt sayfası: yedek kodu yapıştırılır, içeriği özetlenir, onaylanınca cihaza yüklenir.
class YedekYukleSayfasi extends StatefulWidget {
  const YedekYukleSayfasi({super.key, required this.baglam, this.panodanOku = _varsayilanPano});

  final YedekBaglami baglam;

  /// Panodaki metni verir; testlerde değiştirilir.
  final Future<String?> Function() panodanOku;

  static Future<String?> _varsayilanPano() async => (await Clipboard.getData(Clipboard.kTextPlain))?.text;

  @override
  State<YedekYukleSayfasi> createState() => _YedekYukleSayfasiState();
}

class _YedekYukleSayfasiState extends State<YedekYukleSayfasi> {
  final _kod = TextEditingController();
  YedekPaketi? _paket;
  bool _gecersiz = false;
  bool _mesgul = false;
  String? _sonuc;

  @override
  void dispose() {
    _kod.dispose();
    super.dispose();
  }

  void _coz() {
    final metin = _kod.text.trim();
    setState(() {
      _sonuc = null;
      if (metin.isEmpty) {
        _paket = null;
        _gecersiz = false;
        return;
      }
      _paket = YedekPaketi.coz(metin);
      _gecersiz = _paket == null;
    });
  }

  Future<void> _yapistir() async {
    final metin = await widget.panodanOku();
    if (!mounted) return;
    _kod.text = metin ?? '';
    _coz();
  }

  Future<void> _yukle() async {
    final p = _paket;
    if (p == null || _mesgul) return;
    setState(() => _mesgul = true);
    final r = await widget.baglam.geriYukle(p);
    if (!mounted) return;
    setState(() {
      _mesgul = false;
      _paket = null;
      _kod.clear();
      _sonuc = [
        if (r.profil) 'Profil yüklendi',
        if (r.ilan > 0) '${r.ilan} kayıtlı ilan eklendi',
        if (r.alarm > 0) '${r.alarm} alarm eklendi',
      ].join(', ');
      if (_sonuc!.isEmpty) _sonuc = 'Yedekteki her şey zaten bu cihazda.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = _paket;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.archiveRestore, size: 22, color: PusulaRenk.lacivert),
              const SizedBox(width: 10),
              Expanded(child: Text('Yedekten yükle', style: PusulaYazi.baslik(22, aralik: -0.9))),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Eski telefonda "Yedeği kopyala" ile aldığın kodu buraya yapıştır.',
            style: PusulaYazi.metin(13, renk: PusulaRenk.soluk, agirlik: FontWeight.w500).copyWith(height: 1.4),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _kod,
            onChanged: (_) => _coz(),
            minLines: 3,
            maxLines: 5,
            style: PusulaYazi.metin(13, agirlik: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'KPYEDEK1.…',
              hintStyle: PusulaYazi.metin(13, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
              filled: true,
              fillColor: PusulaRenk.beyaz,
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
          const SizedBox(height: 10),
          BirincilDugme(
            metin: 'Panodan yapıştır',
            ikon: LucideIcons.clipboardPaste,
            zemin: PusulaRenk.beyaz,
            yukseklik: 48,
            onPressed: _yapistir,
          ),
          if (_gecersiz) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                'Bu kod geçersiz ya da eksik kopyalanmış. Kodun tamamını kopyaladığından emin ol.',
                style: PusulaYazi.metin(13, renk: PusulaRenk.kirmizi, agirlik: FontWeight.w700),
              ),
            ),
          ],
          if (p != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: PusulaRenk.zemin, borderRadius: BorderRadius.circular(18)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.packageCheck, size: 20, color: PusulaRenk.lacivert),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p.bos
                          ? 'Bu yedeğin içi boş.'
                          : 'Yedekte: ${p.ozet}.${p.profil != null ? ' Yüklersen mevcut profilin yedektekiyle değişir.' : ''}',
                      style: PusulaYazi.metin(13, agirlik: FontWeight.w600).copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            BirincilDugme(
              metin: 'Yedeği yükle',
              ikon: LucideIcons.download,
              yukseklik: 54,
              onPressed: p.bos || _mesgul ? null : _yukle,
            ),
          ],
          if (_sonuc != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.circleCheck, size: 18, color: PusulaRenk.yesilYazi),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$_sonuc.',
                      style: PusulaYazi.metin(13, renk: PusulaRenk.yesilYazi, agirlik: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
