import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Uygulamanın ortak hareket ölçüleri. Hareket süreleri ve eğrileri buradan alınır ki her ekran
/// aynı "ağırlıkta" hissetsin. Sistem "hareketi azalt" ayarı açıksa tüm hareketli bileşenler
/// animasyonsuz, durağan hâlini gösterir.
abstract final class PusulaHareket {
  static bool azalt(BuildContext context) => MediaQuery.disableAnimationsOf(context);

  /// Süs amaçlı sürekli hareket (süzülme, nefes alma) açık mı? Ekran görünmezken zaten durur
  /// (TickerMode). Testler bunu kapatır: bitmeyen animasyon `pumpAndSettle`'ı bekletir.
  static bool susHareketi = true;

  static const kisa = Duration(milliseconds: 180);
  static const orta = Duration(milliseconds: 320);
  static const uzun = Duration(milliseconds: 560);

  /// Yaylanarak oturan giriş (hafif aşım).
  static const yay = Curves.easeOutBack;
  static const yumusak = Curves.easeOutCubic;
}

/// [HareketliGorsel] içindeki tek bir SVG katmanı ve hareketi. Tüm katmanların `viewBox`'ı aynıdır,
/// bu yüzden üst üste konunca hizalanırlar.
class GorselKatmani {
  const GorselKatmani(
    this.varlik, {
    this.suzulme = 0,
    this.donme = 0,
    this.nefes = 0,
    this.hiz = 1,
    this.faz = 0,
    this.derinlik = 0.5,
  });

  /// SVG varlığının yolu (ör. `assets/gorsel/haber/maas_orta.svg`).
  final String varlik;

  /// Yukarı-aşağı süzülme genliği (mantıksal piksel).
  final double suzulme;

  /// Sağa-sola salınım genliği (radyan).
  final double donme;

  /// Nefes alma: ölçeğin 1 etrafındaki genliği (ör. 0.04).
  final double nefes;

  /// 12 saniyelik döngüde kaç tur atacağı. Tam sayı olmalı ki döngü kesintisiz bağlansın.
  final int hiz;

  /// 0..1 arası başlangıç fazı; katmanlar birbirinden bağımsız hareket etsin diye.
  final double faz;

  /// Paralaks derinliği: ön katman büyük, arka katman küçük kayar.
  final double derinlik;
}

/// Katmanlı SVG illüstrasyon: her katman kendi ritminde süzülür, döner ya da nefes alır; ilk
/// gösterimde katmanlar sırayla yaylanarak belirir. [kaydirma] verilirse (−1..1) katmanlar
/// derinliklerine göre yana kayar (slayt paralaksı).
class HareketliGorsel extends StatefulWidget {
  const HareketliGorsel({
    super.key,
    required this.katmanlar,
    this.kaydirma,
    this.hareketli = true,
    this.giris = true,
    this.anlamEtiketi,
  });

  final List<GorselKatmani> katmanlar;
  final ValueListenable<double>? kaydirma;

  /// false ise durağan çizim (liste küçük görselleri).
  final bool hareketli;
  final bool giris;

  /// Ekran okuyucu için açıklama; verilmezse görsel dekoratif sayılır.
  final String? anlamEtiketi;

  @override
  State<HareketliGorsel> createState() => _HareketliGorselState();
}

class _HareketliGorselState extends State<HareketliGorsel> with TickerProviderStateMixin {
  static const _dongu = Duration(seconds: 12);
  AnimationController? _dongusu;
  AnimationController? _girisi;
  bool _azalt = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _azalt = PusulaHareket.azalt(context);
    _kontrolleriKur();
  }

  @override
  void didUpdateWidget(HareketliGorsel eski) {
    super.didUpdateWidget(eski);
    if (eski.hareketli != widget.hareketli) _kontrolleriKur();
  }

  void _kontrolleriKur() {
    final canli = widget.hareketli && !_azalt;
    final dongu = canli && PusulaHareket.susHareketi;
    if (dongu) {
      _dongusu ??= AnimationController(vsync: this, duration: _dongu)..repeat();
    } else {
      _dongusu?.dispose();
      _dongusu = null;
    }
    if (canli && widget.giris) {
      if (_girisi == null) {
        _girisi = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
        _girisi!.forward();
      }
    } else {
      _girisi?.dispose();
      _girisi = null;
    }
  }

  @override
  void dispose() {
    _dongusu?.dispose();
    _girisi?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final birlesik = Listenable.merge([
      if (_dongusu != null) _dongusu!,
      if (_girisi != null) _girisi!,
      if (widget.kaydirma != null) widget.kaydirma!,
    ]);
    final sayi = widget.katmanlar.length;
    Widget govde = RepaintBoundary(
      child: AspectRatio(
        aspectRatio: 240 / 180,
        child: AnimatedBuilder(
          animation: birlesik,
          builder: (context, _) {
            final t = _dongusu?.value ?? 0;
            final kay = widget.kaydirma?.value ?? 0;
            return Stack(
              fit: StackFit.expand,
              children: [
                for (var i = 0; i < sayi; i++) _katman(widget.katmanlar[i], i, sayi, t, kay),
              ],
            );
          },
        ),
      ),
    );
    if (widget.anlamEtiketi == null) return ExcludeSemantics(child: govde);
    return Semantics(image: true, label: widget.anlamEtiketi, excludeSemantics: true, child: govde);
  }

  Widget _katman(GorselKatmani k, int i, int sayi, double t, double kay) {
    final faz = (t * k.hiz + k.faz) * 2 * math.pi;
    final dy = math.sin(faz) * k.suzulme;
    final aci = math.sin(faz + 1.3) * k.donme;
    final olcek = 1 + math.sin(faz + 0.7) * k.nefes;
    final dx = kay * k.derinlik * -14;

    // Giriş: her katman bir öncekinden biraz sonra, yaylanarak oturur.
    var giris = 1.0;
    if (_girisi != null) {
      final baslangic = 0.12 * i;
      final ilerleme = ((_girisi!.value - baslangic) / (1 - baslangic)).clamp(0.0, 1.0);
      giris = PusulaHareket.yay.transform(ilerleme);
    }
    final gorunurluk = _girisi == null ? 1.0 : Curves.easeOut.transform(giris.clamp(0.0, 1.0));

    return Opacity(
      opacity: gorunurluk,
      child: Transform.translate(
        offset: Offset(dx, dy + (1 - giris) * 14),
        child: Transform.rotate(
          angle: aci,
          child: Transform.scale(
            scale: olcek * (0.82 + 0.18 * giris),
            child: SvgPicture.asset(k.varlik, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

/// Dokunulunca hafifçe küçülüp bırakılınca yaylanarak dönen sarmalayıcı. Altındaki dokunma
/// işlemini engellemez ([Listener] kullanır) ve başlangıçta hafif bir dokunsal geri bildirim verir.
class Basilabilir extends StatefulWidget {
  const Basilabilir({super.key, required this.child, this.aktif = true, this.olcek = 0.97});

  final Widget child;
  final bool aktif;
  final double olcek;

  @override
  State<Basilabilir> createState() => _BasilabilirState();
}

class _BasilabilirState extends State<Basilabilir> {
  bool _basili = false;

  void _ayarla(bool v) {
    if (_basili == v || !mounted) return;
    setState(() => _basili = v);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.aktif || PusulaHareket.azalt(context)) return widget.child;
    return Listener(
      onPointerDown: (_) {
        HapticFeedback.selectionClick();
        _ayarla(true);
      },
      onPointerUp: (_) => _ayarla(false),
      onPointerCancel: (_) => _ayarla(false),
      child: AnimatedScale(
        scale: _basili ? widget.olcek : 1,
        duration: _basili ? const Duration(milliseconds: 90) : PusulaHareket.orta,
        curve: _basili ? Curves.easeOut : Curves.elasticOut,
        child: widget.child,
      ),
    );
  }
}

/// Değer değişince eski rakamdan yenisine sayarak geçen metin. [bicim] sayıyı yazıya çevirir
/// (ör. lira biçimi). Hareketi azalt açıksa değer anında değişir.
class SayiSayaci extends StatelessWidget {
  const SayiSayaci({
    super.key,
    required this.deger,
    required this.bicim,
    required this.stil,
    this.sure = const Duration(milliseconds: 650),
    this.maxLines = 1,
  });

  final double deger;
  final String Function(double) bicim;
  final TextStyle stil;
  final Duration sure;
  final int maxLines;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(end: deger),
    duration: PusulaHareket.azalt(context) ? Duration.zero : sure,
    curve: PusulaHareket.yumusak,
    builder: (context, v, _) => Text(bicim(v), maxLines: maxLines, style: stil),
  );
}
