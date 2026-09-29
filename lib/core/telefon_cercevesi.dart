import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Web'de geniş ekranda (bilgisayar) uygulamayı ortalanmış bir telefon boyutlu
/// çerçevede gösterir; dar ekranda (telefon tarayıcısı) hiçbir şey değiştirmez.
/// Mobil ve masaüstü yerel derlemelerde [etkin] false olduğundan etkisizdir.
class TelefonCercevesi extends StatelessWidget {
  const TelefonCercevesi({
    super.key,
    required this.child,
    this.etkin = kIsWeb,
    this.genislik = 430,
    this.enYukseklik = 900,
  });

  final Widget child;
  final bool etkin;

  /// Çerçevenin genişliği; ekran bundan (+ kenar boşluğu) darsa çerçeve kullanılmaz.
  final double genislik;
  final double enYukseklik;

  static const _dis = Color(0xFF0E1533);

  @override
  Widget build(BuildContext context) {
    if (!etkin) return child;
    return LayoutBuilder(
      builder: (context, kisit) {
        if (kisit.maxWidth <= genislik + 40) return child;
        final yukseklik = (kisit.maxHeight - 32).clamp(400.0, enYukseklik);
        final boyut = Size(genislik, yukseklik);
        return ColoredBox(
          color: _dis,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: const Color(0xFF2A3566), width: 2),
                boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 40, offset: Offset(0, 16))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: SizedBox.fromSize(
                  size: boyut,
                  // İçerik telefon boyutunda ölçülsün (alt sayfalar, düzenler buna göre kurulur).
                  child: MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(size: boyut, padding: EdgeInsets.zero, viewPadding: EdgeInsets.zero),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
