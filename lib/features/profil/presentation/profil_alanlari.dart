import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/bilesenler.dart';
import '../../../core/tema.dart';
import '../domain/profil.dart';

/// Profil ve ilk kurulum ekranlarının ortak form parçaları.
/// "Memurluğumun asaleti henüz onaylanmadı" anahtarı.
class AdayMemurKarti extends StatelessWidget {
  const AdayMemurKarti({super.key, required this.deger, required this.onDegis});

  final bool deger;
  final ValueChanged<bool> onDegis;

  @override
  Widget build(BuildContext context) => PusulaKart(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(16, 6, 10, 6),
        child: Row(
          children: [
            Expanded(
              child: Text('Memurluğumun asaleti henüz onaylanmadı (aday memurum)',
                  style: PusulaYazi.metin(13, agirlik: FontWeight.w600)),
            ),
            Switch(
              value: deger,
              onChanged: onDegis,
              activeThumbColor: PusulaRenk.amber,
              activeTrackColor: PusulaRenk.lacivert,
              inactiveThumbColor: PusulaRenk.beyaz,
              inactiveTrackColor: const Color(0xFFC9CCD6),
              trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
            ),
          ],
        ),
      );
}

class StatuKarti extends StatelessWidget {
  const StatuKarti({super.key, required this.statu, required this.secili, required this.onTap});

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

class MetinAlani extends StatelessWidget {
  const MetinAlani({
    super.key,
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

class SecimAlani extends StatelessWidget {
  const SecimAlani({super.key, required this.etiket, required this.deger, required this.ipucu, required this.onTap});

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
            onTap: onTap,
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
