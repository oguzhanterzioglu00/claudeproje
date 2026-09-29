import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/bilesenler.dart';
import '../../core/tema.dart';
import 'haber_kapagi.dart';
import 'haber_modeli.dart';

/// Görselli, yana kaydırılan haber slaytları. Kendiliğinden ilerler (kullanıcı
/// dokununca durur, bir süre sonra devam eder); sistem "hareketi azalt" açıksa
/// kendiliğinden ilerlemez.
class HaberSlaytlari extends StatefulWidget {
  const HaberSlaytlari({
    super.key,
    required this.haberler,
    required this.bugun,
    required this.onAc,
    this.otomatik = true,
    this.yukseklik = 214,
    this.aralik = const Duration(seconds: 5),
  });

  final List<Haber> haberler;
  final DateTime bugun;
  final ValueChanged<Haber> onAc;
  final bool otomatik;
  final double yukseklik;

  /// Kendiliğinden ilerleme aralığı.
  final Duration aralik;

  @override
  State<HaberSlaytlari> createState() => _HaberSlaytlariState();
}

class _HaberSlaytlariState extends State<HaberSlaytlari> {
  final _kontrol = PageController(viewportFraction: 0.9);
  Timer? _sayac;
  int _sayfa = 0;
  bool _hareketsiz = false;

  int get _sayi => widget.haberler.length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _hareketsiz = MediaQuery.disableAnimationsOf(context);
    _sayaciKur();
  }

  @override
  void didUpdateWidget(HaberSlaytlari eski) {
    super.didUpdateWidget(eski);
    if (eski.otomatik != widget.otomatik || eski.aralik != widget.aralik || eski.haberler.length != _sayi) {
      _sayaciKur();
    }
  }

  void _sayaciKur() {
    _sayac?.cancel();
    _sayac = null;
    if (!widget.otomatik || _hareketsiz || _sayi < 2) return;
    _sayac = Timer.periodic(widget.aralik, (_) => _ilerle());
  }

  void _ilerle() {
    // Sekme görünür değilse (IndexedStack) ya da yerleşmediyse ilerleme.
    if (!mounted || !_kontrol.hasClients || _sayi < 2 || !TickerMode.valuesOf(context).enabled) return;
    final sonraki = (_sayfa + 1) % _sayi;
    _kontrol.animateToPage(sonraki, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _sayac?.cancel();
    _kontrol.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_sayi == 0) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: widget.yukseklik,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              // Kullanıcı sürüklemeye başlayınca otomatik ilerleme durur; bırakınca yeniden kurulur.
              if (n is ScrollStartNotification && n.dragDetails != null) {
                _sayac?.cancel();
              } else if (n is ScrollEndNotification) {
                _sayaciKur();
              }
              return false;
            },
            child: PageView.builder(
              controller: _kontrol,
              padEnds: false,
              itemCount: _sayi,
              onPageChanged: (i) => setState(() => _sayfa = i),
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _Slayt(haber: widget.haberler[i], bugun: widget.bugun, onTap: () => widget.onAc(widget.haberler[i])),
              ),
            ),
          ),
        ),
        if (_sayi > 1) ...[
          const SizedBox(height: 10),
          Semantics(
            label: 'Haber ${_sayfa + 1} / $_sayi',
            excludeSemantics: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _sayi; i++)
                  AnimatedContainer(
                    duration: _hareketsiz ? Duration.zero : const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _sayfa ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _sayfa ? PusulaRenk.lacivert : PusulaRenk.lacivert.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Slayt extends StatelessWidget {
  const _Slayt({required this.haber, required this.bugun, required this.onTap});

  final Haber haber;
  final DateTime bugun;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    label: '${haber.baslik}. ${haber.kaynakAdi}, ${haber.zamanEtiketi(bugun)}',
    excludeSemantics: true,
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Material(
        color: PusulaRenk.lacivert,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              HaberKapagi(haber: haber),
              // Yazının okunması için alttan koyulaşan katman.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00182350), Color(0xE6182350)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Hap(
                          haber.tur.etiket,
                          zemin: HaberGorunumu.renk(haber.tur),
                          yazi: HaberGorunumu.ikonRengi(haber.tur),
                          ikon: HaberGorunumu.ikon(haber.tur),
                          boyut: 11,
                        ),
                        if (haber.resmiKaynak) ...[
                          const SizedBox(width: 6),
                          const Hap(
                            'Resmî kaynak',
                            zemin: PusulaRenk.yesilZemin,
                            yazi: PusulaRenk.yesilYazi,
                            ikon: LucideIcons.badgeCheck,
                            boyut: 11,
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    Text(
                      haber.baslik,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: PusulaYazi.baslik(19, renk: PusulaRenk.beyaz, aralik: -0.6).copyWith(height: 1.2),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${haber.kaynakAdi} · ${haber.zamanEtiketi(bugun)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PusulaYazi.metin(12, renk: const Color(0xFFC9D2EC), agirlik: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
