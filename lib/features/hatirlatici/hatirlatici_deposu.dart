import 'package:flutter/foundation.dart';

import '../../core/depolama.dart';
import '../maas/domain/gosterge_tablosu.dart';
import '../profil/domain/profil.dart';
import 'hatirlatici_servisi.dart';

/// Planlanacak tek bir bildirim.
class Hatirlatma {
  const Hatirlatma({required this.id, required this.zaman, required this.baslik, required this.govde});

  final int id;
  final DateTime zaman;
  final String baslik;
  final String govde;
}

/// Kademe ilerlemesi hatırlatmalarını üretir (657 md. 64: bulunulan kademede en az bir yıl).
/// Bir hafta öncesi ve süre dolduğu gün sabah 09:00; geçmişte kalanlar üretilmez.
List<Hatirlatma> kademeHatirlatmalari(DateTime kademeTarihi, DateTime simdi) {
  final hedef = DateTime(kademeTarihi.year + 1, kademeTarihi.month, kademeTarihi.day, 9);
  final liste = [
    Hatirlatma(
      id: HatirlaticiDeposu.kademeBirHaftaId,
      zaman: hedef.subtract(const Duration(days: 7)),
      baslik: 'Kademe ilerlemene 1 hafta kaldı',
      govde: 'Bulunduğun kademede bir yıllık süre 7 gün sonra doluyor.',
    ),
    Hatirlatma(
      id: HatirlaticiDeposu.kademeGunuId,
      zaman: hedef,
      baslik: 'Kademe ilerlemesi için süre doldu',
      govde: 'Bir yıllık süre bugün doluyor. Kademe ilerlemeni kurumunla kontrol et.',
    ),
  ];
  return [
    for (final h in liste)
      if (h.zaman.isAfter(simdi)) h,
  ];
}

/// Hesap bazlı hatırlatıcı tercihi ve zamanlama. Yalnızca tercih cihazda saklanır.
class HatirlaticiDeposu extends ChangeNotifier {
  HatirlaticiDeposu(this._servis, this._depolama, {required String hesapId, DateTime Function()? simdi})
    : _anahtar = 'hatirlatici_kademe_v1_$hesapId',
      _simdi = simdi ?? DateTime.now;

  static const kademeBirHaftaId = 7101;
  static const kademeGunuId = 7102;

  final HatirlaticiServisi _servis;
  final AnahtarDeger _depolama;
  final String _anahtar;
  final DateTime Function() _simdi;

  bool _kademeAcik = false;
  bool _yuklendi = false;
  bool _atildi = false;

  @override
  void notifyListeners() {
    if (!_atildi) super.notifyListeners();
  }

  @override
  void dispose() {
    _atildi = true;
    super.dispose();
  }

  bool get destekleniyor => _servis.destekleniyor;
  bool get kademeAcik => _kademeAcik;
  bool get yuklendi => _yuklendi;

  Future<void> yukle() async {
    _kademeAcik = await _depolama.oku(_anahtar) == '1';
    _yuklendi = true;
    notifyListeners();
  }

  /// Kademe hatırlatıcısını açar/kapatır. Açarken bildirim izni istenir; verilmezse açılmaz ve false döner.
  Future<bool> kademeAyarla(bool ac, Profil? profil) async {
    if (ac && !await _servis.izinIste()) return false;
    _kademeAcik = ac;
    await _depolama.yaz(_anahtar, ac ? '1' : '0');
    notifyListeners();
    await esitle(profil);
    return true;
  }

  /// Profile göre planı yeniden kurar (profil değişince ve uygulama açılınca çağrılır).
  Future<void> esitle(Profil? profil) async {
    await _servis.iptal(kademeBirHaftaId);
    await _servis.iptal(kademeGunuId);
    if (!_kademeAcik || profil == null || profil.statu != Statu.memur657 || profil.kademeTarihi == null) return;
    final maas = profil.maas;
    final sonKademe = maas != null && maas.kademe >= GostergeTablosu.kademeSayisi(maas.derece);
    if (sonKademe) return;
    for (final h in kademeHatirlatmalari(profil.kademeTarihi!, _simdi())) {
      await _servis.planla(id: h.id, baslik: h.baslik, govde: h.govde, zaman: h.zaman);
    }
  }

  /// Çıkış veya hesap silme: bu cihazda kurulmuş tüm hatırlatmaları kaldırır.
  Future<void> hepsiniIptal() async {
    await _servis.iptal(kademeBirHaftaId);
    await _servis.iptal(kademeGunuId);
  }

  Future<void> tercihiSil() async {
    await hepsiniIptal();
    _kademeAcik = false;
    await _depolama.sil(_anahtar);
    notifyListeners();
  }
}
