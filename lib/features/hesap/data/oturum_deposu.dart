import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/hesap.dart';
import 'kimlik_servisi.dart';

/// Oturum durumunun tek kaynağı; kök ekran ve hesap ekranları buna dinler.
class OturumDeposu extends ChangeNotifier {
  OturumDeposu(this._servis) {
    _abonelik = _servis.olaylar.listen(_olay);
  }

  final KimlikServisi _servis;
  StreamSubscription<KimlikOlayi>? _abonelik;

  /// Gerçek bir arka uca bağlı mı? false ise hesaplar yalnızca cihazdadır ("örnek" sürüm).
  bool get gercek => _servis.gercek;

  /// Şifre sıfırlama bağlantısından gelindi: kullanıcıdan yeni şifre beklenir.
  bool _sifreKurtarmaBekliyor = false;
  bool get sifreKurtarmaBekliyor => _sifreKurtarmaBekliyor;

  void _olay(KimlikOlayi o) {
    switch (o.tur) {
      case KimlikOlayTuru.oturumAcildi:
        if (o.hesap != null && o.hesap!.id != _hesap?.id) {
          _hesap = o.hesap;
          notifyListeners();
        }
      case KimlikOlayTuru.oturumKapandi:
        if (_hesap != null || _sifreKurtarmaBekliyor) {
          _hesap = null;
          _sifreKurtarmaBekliyor = false;
          notifyListeners();
        }
      case KimlikOlayTuru.sifreKurtarma:
        _hesap = o.hesap ?? _hesap;
        _sifreKurtarmaBekliyor = true;
        notifyListeners();
    }
  }

  @override
  void dispose() {
    _abonelik?.cancel();
    super.dispose();
  }

  /// Sıfırlama bağlantısıyla gelen kullanıcı için yeni şifreyi belirler ve normal oturuma geçer.
  Future<void> yeniSifreBelirle(String yeni) async {
    await _calistir(() => _servis.kurtarmaSifresiBelirle(yeni));
    _sifreKurtarmaBekliyor = false;
    notifyListeners();
  }

  /// Şifre sıfırlamadan vazgeçildi: oturum kapatılır.
  Future<void> kurtarmadanVazgec() async {
    _sifreKurtarmaBekliyor = false;
    await cikisYap();
  }

  Hesap? _hesap;
  bool _yuklendi = false;
  bool _mesgul = false;

  Hesap? get hesap => _hesap;
  bool get yuklendi => _yuklendi;

  /// Bir işlem sürerken düğmeler pasif kalır.
  bool get mesgul => _mesgul;

  Future<void> yukle() async {
    try {
      _hesap = await _servis.mevcut();
    } catch (_) {
      _hesap = null;
    }
    _yuklendi = true;
    notifyListeners();
  }

  Future<T> _calistir<T>(Future<T> Function() islem) async {
    _mesgul = true;
    notifyListeners();
    try {
      return await islem();
    } on KimlikHatasi {
      rethrow;
    } catch (_) {
      throw const KimlikHatasi('İşlem tamamlanamadı. Bağlantını kontrol edip tekrar dene.');
    } finally {
      _mesgul = false;
      notifyListeners();
    }
  }

  Future<void> kayitOl(String eposta, String sifre) async {
    final h = await _calistir(() => _servis.kayitOl(eposta: eposta, sifre: sifre));
    _hesap = h;
    notifyListeners();
  }

  Future<void> girisYap(String eposta, String sifre) async {
    final h = await _calistir(() => _servis.girisYap(eposta: eposta, sifre: sifre));
    _hesap = h;
    notifyListeners();
  }

  Future<void> saglayiciIleGiris(GirisSaglayici s) async {
    final h = await _calistir(() => _servis.saglayiciIleGiris(s));
    _hesap = h;
    notifyListeners();
  }

  Future<void> sifreDegistir(String eski, String yeni) =>
      _calistir(() => _servis.sifreDegistir(eskiSifre: eski, yeniSifre: yeni));

  Future<void> sifreSifirlamaIste(String eposta) => _calistir(() => _servis.sifreSifirlamaIste(eposta));

  Future<void> cikisYap() async {
    await _calistir(_servis.cikisYap);
    _hesap = null;
    notifyListeners();
  }

  Future<void> hesabiSil() async {
    await _calistir(_servis.hesabiSil);
    _hesap = null;
    notifyListeners();
  }
}
