import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart' show SignInWithAppleButton, SignInWithAppleButtonStyle;

/// "Apple ile devam et" düğmesi.
///
/// iPhone/iPad'de Apple'ın kendi bileşeni (`ASAuthorizationAppleIDButton`) gömülür: logo ve metin Apple
/// tarafından çizilir ve cihaz diline göre yerelleşir (App Store 4. madde / HIG). Diğer ortamlarda (testler,
/// geliştirme) paketin çizdiği eşdeğer düğme gösterilir.
class AppleGirisDugmesi extends StatelessWidget {
  const AppleGirisDugmesi({super.key, required this.onPressed, this.yukseklik = 56, this.kose = 22});

  final VoidCallback onPressed;
  final double yukseklik;
  final double kose;

  static const gorunumTuru = 'pusula/apple_dugme';

  static bool get _yerelMi => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    if (_yerelMi) {
      return Semantics(
        button: true,
        label: 'Apple ile devam et',
        excludeSemantics: true,
        onTap: onPressed,
        child: SizedBox(
          height: yukseklik,
          child: _YerelAppleDugme(onPressed: onPressed, kose: kose),
        ),
      );
    }
    return SignInWithAppleButton(
      text: 'Apple ile devam et',
      height: yukseklik,
      borderRadius: BorderRadius.all(Radius.circular(kose)),
      style: SignInWithAppleButtonStyle.black,
      onPressed: onPressed,
    );
  }
}

class _YerelAppleDugme extends StatelessWidget {
  const _YerelAppleDugme({required this.onPressed, required this.kose});

  final VoidCallback onPressed;
  final double kose;

  @override
  Widget build(BuildContext context) => UiKitView(
    viewType: AppleGirisDugmesi.gorunumTuru,
    creationParams: <String, Object>{'koyu': true, 'kose': kose},
    creationParamsCodec: const StandardMessageCodec(),
    onPlatformViewCreated: (id) {
      MethodChannel('pusula/apple_dugme_$id').setMethodCallHandler((cagri) async {
        if (cagri.method == 'basildi') onPressed();
      });
    },
  );
}
