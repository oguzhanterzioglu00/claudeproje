import AuthenticationServices
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // App Store 4. madde (HIG): "Apple ile giriş" düğmesi Apple'ın kendi bileşeni olmalı; logo ve
    // metin Flutter'da çizilmez, sistemin ASAuthorizationAppleIDButton'u kullanılır.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PusulaAppleDugme") {
      registrar.register(
        AppleDugmeFabrikasi(messenger: registrar.messenger()),
        withId: "pusula/apple_dugme"
      )
    }
  }
}

/// Flutter'a gömülen yerel "Apple ile devam et" düğmesi.
final class AppleDugmeFabrikasi: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return AppleDugmeGorunumu(frame: frame, viewId: viewId, args: args, messenger: messenger)
  }
}

final class AppleDugmeGorunumu: NSObject, FlutterPlatformView {
  private let dugme: ASAuthorizationAppleIDButton
  private let kanal: FlutterMethodChannel

  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    let parametreler = args as? [String: Any]
    let koyu = (parametreler?["koyu"] as? Bool) ?? true
    let kose = (parametreler?["kose"] as? Double) ?? 22
    dugme = ASAuthorizationAppleIDButton(
      authorizationButtonType: .continue,
      authorizationButtonStyle: koyu ? .black : .white
    )
    dugme.cornerRadius = CGFloat(kose)
    kanal = FlutterMethodChannel(name: "pusula/apple_dugme_\(viewId)", binaryMessenger: messenger)
    super.init()
    dugme.addTarget(self, action: #selector(basildi), for: .touchUpInside)
  }

  @objc private func basildi() {
    kanal.invokeMethod("basildi", arguments: nil)
  }

  func view() -> UIView {
    return dugme
  }
}
