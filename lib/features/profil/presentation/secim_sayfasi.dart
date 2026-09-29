import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/bilesenler.dart';
import '../../../core/metin.dart';
import '../../../core/tema.dart';

/// Aranabilir liste seçici (alt sayfa). [serbest] true ise listede olmayan bir
/// değer yazılıp seçilebilir.
abstract final class SecimSayfasi {
  static Future<String?> goster(
    BuildContext context, {
    required String baslik,
    required List<String> secenekler,
    String secili = '',
    bool serbest = false,
  }) =>
      AltSayfa.goster<String>(
        context,
        builder: (c) => _Secim(baslik: baslik, secenekler: secenekler, secili: secili, serbest: serbest),
      );
}

class _Secim extends StatefulWidget {
  const _Secim({required this.baslik, required this.secenekler, required this.secili, required this.serbest});

  final String baslik;
  final List<String> secenekler;
  final String secili;
  final bool serbest;

  @override
  State<_Secim> createState() => _SecimState();
}

class _SecimState extends State<_Secim> {
  final _ara = TextEditingController();

  @override
  void dispose() {
    _ara.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = aramaAnahtari(_ara.text);
    final liste = widget.secenekler.where((s) => q.isEmpty || aramaAnahtari(s).contains(q)).toList();
    final yazilan = _ara.text.trim();
    final serbestGoster = widget.serbest &&
        yazilan.isNotEmpty &&
        !widget.secenekler.any((s) => normalize(s) == normalize(yazilan));

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.baslik, style: PusulaYazi.baslik(20, aralik: -0.8)),
          const SizedBox(height: 12),
          TextField(
            controller: _ara,
            onChanged: (_) => setState(() {}),
            style: PusulaYazi.metin(15, agirlik: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Ara',
              hintStyle: PusulaYazi.metin(15, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
              prefixIcon: const Icon(LucideIcons.search, size: 20, color: PusulaRenk.lacivert),
              filled: true,
              fillColor: PusulaRenk.zemin,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                if (serbestGoster)
                  _Satir(
                    metin: 'Kullan: "$yazilan"',
                    secili: false,
                    onTap: () => Navigator.pop(context, yazilan),
                  ),
                for (final s in liste)
                  _Satir(
                    metin: s,
                    secili: s == widget.secili,
                    onTap: () => Navigator.pop(context, s),
                  ),
                if (liste.isEmpty && !serbestGoster)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Sonuç yok',
                        textAlign: TextAlign.center,
                        style: PusulaYazi.metin(14, renk: PusulaRenk.soluk)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Satir extends StatelessWidget {
  const _Satir({required this.metin, required this.secili, required this.onTap});

  final String metin;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: secili,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Row(
              children: [
                Expanded(child: Text(metin, style: PusulaYazi.metin(15, agirlik: secili ? FontWeight.w700 : FontWeight.w500))),
                if (secili) const Icon(LucideIcons.check, size: 18, color: PusulaRenk.yesilYazi),
              ],
            ),
          ),
        ),
      );
}
