import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:url_launcher/url_launcher.dart' show LaunchMode;

import 'supabase_kimlik_servisi.dart';

/// [KimlikIstemcisi]'nin gerçek Supabase Auth uygulaması. Mantık [SupabaseKimlikServisi]'ndedir; bu sınıf yalnızca
/// Supabase çağrılarını ve hatalarını sağlayıcıdan bağımsız türlere çevirir (ağ olmadan sınanamaz, bu yüzden ince tutulur).
class SupabaseKimlikIstemcisi implements KimlikIstemcisi {
  SupabaseKimlikIstemcisi(this._client);

  final sb.SupabaseClient _client;
  bool _googleHazir = false;

  sb.GoTrueClient get _auth => _client.auth;

  static IstemciKullanicisi? _kullanici(sb.User? u) {
    if (u == null) return null;
    final meta = u.userMetadata ?? const <String, dynamic>{};
    final ad = (meta['full_name'] ?? meta['name'] ?? '').toString();
    final saglayici = (u.appMetadata['provider'] ?? 'email').toString();
    return IstemciKullanicisi(id: u.id, eposta: u.email ?? '', ad: ad, saglayici: saglayici);
  }

  @override
  IstemciKullanicisi? get kullanici => _kullanici(_auth.currentUser);

  @override
  Stream<IstemciOlayi> get olaylar => _auth.onAuthStateChange
      .map((s) {
        switch (s.event) {
          case sb.AuthChangeEvent.signedIn:
          case sb.AuthChangeEvent.initialSession:
            final k = _kullanici(s.session?.user);
            return k == null ? null : IstemciOlayi(IstemciOlayTuru.girisYapti, k);
          case sb.AuthChangeEvent.signedOut:
            return const IstemciOlayi(IstemciOlayTuru.cikisYapti);
          case sb.AuthChangeEvent.passwordRecovery:
            return IstemciOlayi(IstemciOlayTuru.sifreKurtarma, _kullanici(s.session?.user));
          default:
            return null;
        }
      })
      .where((o) => o != null)
      .cast<IstemciOlayi>();

  /// Supabase hatalarını (ve ağ hatalarını) [IstemciHatasi]'na çevirir.
  static Future<T> _sar<T>(Future<T> Function() islem) async {
    try {
      return await islem();
    } on sb.AuthException catch (e) {
      throw IstemciHatasi(kod: e.code ?? _koddan(e.message), mesaj: e.message);
    } on sb.PostgrestException catch (e) {
      throw IstemciHatasi(kod: e.code, mesaj: e.message);
    } on IstemciHatasi {
      rethrow;
    } catch (e) {
      final s = e.toString();
      if (s.contains('SocketException') ||
          s.contains('ClientException') ||
          s.contains('Failed host lookup') ||
          s.contains('TimeoutException')) {
        throw const IstemciHatasi(ag: true);
      }
      rethrow;
    }
  }

  /// Eski sunucu sürümleri kod göndermez; metinden çıkarır.
  static String? _koddan(String mesaj) {
    final m = mesaj.toLowerCase();
    if (m.contains('invalid login credentials')) return 'invalid_credentials';
    if (m.contains('email not confirmed')) return 'email_not_confirmed';
    if (m.contains('already registered')) return 'user_already_exists';
    if (m.contains('password should be')) return 'weak_password';
    if (m.contains('rate limit')) return 'over_email_send_rate_limit';
    return null;
  }

  @override
  Future<IstemciKullanicisi?> kayitOl(String eposta, String sifre, {required String yonlendirme}) => _sar(() async {
    final r = await _auth.signUp(email: eposta, password: sifre, emailRedirectTo: yonlendirme);
    // E-posta doğrulaması açıkken var olan bir adresle kayıt, hata yerine kimliksiz sahte kullanıcı döner.
    if (r.user != null && (r.user!.identities?.isEmpty ?? false)) {
      throw const IstemciHatasi(kod: 'user_already_exists');
    }
    return r.session == null ? null : _kullanici(r.user);
  });

  @override
  Future<IstemciKullanicisi> girisYap(String eposta, String sifre) => _sar(() async {
    final r = await _auth.signInWithPassword(email: eposta, password: sifre);
    final k = _kullanici(r.user);
    if (k == null) throw const IstemciHatasi(kod: 'invalid_credentials');
    return k;
  });

  @override
  Future<bool> saglayiciBaslat(String saglayici, {required String yonlendirme}) => _sar(
    () => _auth.signInWithOAuth(
      saglayici == 'google' ? sb.OAuthProvider.google : sb.OAuthProvider.apple,
      redirectTo: yonlendirme,
      authScreenLaunchMode: LaunchMode.externalApplication,
    ),
  );

  @override
  Future<IstemciKullanicisi?> googleYerelGiris(String sunucuIstemciKimligi) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final google = GoogleSignIn.instance;
    try {
      if (!_googleHazir) {
        await google.initialize(serverClientId: sunucuIstemciKimligi);
        _googleHazir = true;
      }
      if (!google.supportsAuthenticate()) return null;
      final hesap = await google.authenticate();
      final idToken = hesap.authentication.idToken;
      if (idToken == null) throw const IstemciHatasi(kod: 'google_hatasi');
      return await _sar(() async {
        final r = await _client.auth.signInWithIdToken(provider: sb.OAuthProvider.google, idToken: idToken);
        final k = _kullanici(r.user);
        if (k == null) throw const IstemciHatasi(kod: 'google_hatasi');
        return k;
      });
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled || e.code == GoogleSignInExceptionCode.interrupted) {
        throw const IstemciHatasi(kod: 'iptal');
      }
      throw IstemciHatasi(kod: 'google_hatasi', mesaj: '${e.code.name}: ${e.description}');
    }
  }

  /// Apple kimlik jetonu yeniden oynatılmasın diye her girişte rastgele bir nonce üretilir: Apple'a özeti,
  /// Supabase'e ham hâli verilir ve Supabase ikisini eşleştirir.
  static String _nonceUret() {
    final r = Random.secure();
    return base64Url.encode(List<int>.generate(32, (_) => r.nextInt(256)));
  }

  @override
  Future<IstemciKullanicisi?> appleYerelGiris() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return null;
    if (!await SignInWithApple.isAvailable()) return null;
    final ham = _nonceUret();
    final ozet = sha256.convert(utf8.encode(ham)).toString();
    final AuthorizationCredentialAppleID kimlik;
    try {
      kimlik = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: ozet,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) throw const IstemciHatasi(kod: 'iptal');
      throw IstemciHatasi(kod: 'apple_hatasi', mesaj: '${e.code.name}: ${e.message}');
    }
    final idToken = kimlik.identityToken;
    if (idToken == null) throw const IstemciHatasi(kod: 'apple_hatasi');
    final k = await _sar(() async {
      final r = await _client.auth.signInWithIdToken(provider: sb.OAuthProvider.apple, idToken: idToken, nonce: ham);
      final kullanici = _kullanici(r.user);
      if (kullanici == null) throw const IstemciHatasi(kod: 'apple_hatasi');
      return kullanici;
    });
    // Apple adı yalnızca İLK girişte verir; o an kaydedilmezse bir daha alınamaz.
    final ad = [kimlik.givenName, kimlik.familyName].whereType<String>().where((x) => x.isNotEmpty).join(' ');
    if (ad.isNotEmpty && k.ad.isEmpty) {
      try {
        await _client.auth.updateUser(sb.UserAttributes(data: {'full_name': ad}));
        return IstemciKullanicisi(id: k.id, eposta: k.eposta, ad: ad, saglayici: k.saglayici);
      } catch (_) {}
    }
    return k;
  }

  @override
  Future<void> sifreSifirlamaIste(String eposta, {required String yonlendirme}) =>
      _sar(() => _auth.resetPasswordForEmail(eposta, redirectTo: yonlendirme));

  @override
  Future<void> sifreGuncelle(String yeniSifre) => _sar(() => _auth.updateUser(sb.UserAttributes(password: yeniSifre)));

  @override
  Future<void> cikis() async {
    // Yerel Google oturumu da kapanır; bir sonraki girişte hesap yeniden seçilir.
    if (_googleHazir) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await _sar(_auth.signOut);
  }

  @override
  Future<void> hesabiSil() => _sar(() => _client.rpc<void>('hesabi_sil'));
}
