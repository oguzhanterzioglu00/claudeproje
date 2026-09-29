import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/depolama.dart';
import '../hatirlatici/hatirlatici_servisi.dart';
import '../ilanlar/arka_plan.dart';
import 'haber_kaynagi.dart';
import 'haber_modeli.dart';

/// Kamu personelini ilgilendiren yeni Resmî Gazete maddeleri için bildirim (opt-in). Günlük sayı künyeleri
/// ("29 Eylül 2026 Tarihli ... Resmî Gazete") bildirilmez; yalnızca personel/maaş/atama gibi maddeler bildirilir.
/// Çalışma biçimi [YeniIlanTakibi] ile aynıdır (uygulama açıkken ve Android'de arka planda).
class YeniHaberTakibi extends ChangeNotifier {
  YeniHaberTakibi({
    required HaberKaynagi kaynak,
    required HatirlaticiServisi servis,
    required AnahtarDeger depolama,
    required String hesapId,
    ArkaPlanZamanlayici? arkaPlan,
    DateTime Function()? simdi,
  }) : _kaynak = kaynak,
       _servis = servis,
       _depolama = depolama,
       _hesapId = hesapId,
       _arkaPlan = arkaPlan,
       _simdi = simdi ?? DateTime.now;

  static const bildirimKimligi = 8101;
  static const enFazlaBireysel = 3;

  /// Bu günden eski maddeler (uzun süre kapalı kalan uygulamada) bildirilmez.
  static const enFazlaGun = 3;
  static const _saklanacakKimlik = 500;

  static String tercihAnahtari(String hesapId) => 'haber_bildirim_v1_$hesapId';
  static String _gorulenAnahtari(String hesapId) => 'haber_gorulen_v1_$hesapId';

  final HaberKaynagi _kaynak;
  final HatirlaticiServisi _servis;
  final AnahtarDeger _depolama;
  final String _hesapId;
  final ArkaPlanZamanlayici? _arkaPlan;
  final DateTime Function() _simdi;

  bool _acik = false;
  bool _yuklendi = false;
  bool _atildi = false;
  bool _kontrolde = false;

  bool get acik => _acik;
  bool get yuklendi => _yuklendi;
  bool get destekleniyor => _servis.destekleniyor;

  @override
  void notifyListeners() {
    if (!_atildi) super.notifyListeners();
  }

  @override
  void dispose() {
    _atildi = true;
    super.dispose();
  }

  static bool tercihAcikMi(String? ham) {
    if (ham == null) return false;
    try {
      final j = jsonDecode(ham);
      return j is Map && j['acik'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> yukle() async {
    _acik = tercihAcikMi(await _depolama.oku(tercihAnahtari(_hesapId)));
    _yuklendi = true;
    notifyListeners();
  }

  Future<void> _kaydet() => _depolama.yaz(tercihAnahtari(_hesapId), jsonEncode({'acik': _acik}));

  Future<void> _arkaPlaniGuncelle() =>
      arkaPlaniGuncelle(depolama: _depolama, hesapId: _hesapId, zamanlayici: _arkaPlan);

  /// Açarken bildirim izni istenir (verilmezse açılmaz, false döner); mevcut maddeler "görüldü" sayılır.
  Future<bool> ayarla(bool ac) async {
    if (ac && !await _servis.izinIste()) return false;
    _acik = ac;
    await _kaydet();
    notifyListeners();
    if (ac) await _temelCiz();
    await _arkaPlaniGuncelle();
    return true;
  }

  Future<void> arkaPlaniSenkronla() => _arkaPlaniGuncelle();

  Future<Set<String>> _gorulenler() async {
    final ham = await _depolama.oku(_gorulenAnahtari(_hesapId));
    if (ham == null) return {};
    try {
      final j = jsonDecode(ham);
      return j is List
          ? {
              for (final e in j)
                if (e is String) e,
            }
          : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> _gorulenleriYaz(Iterable<String> kimlikler) {
    final liste = kimlikler.toList();
    final kirpilmis = liste.length > _saklanacakKimlik ? liste.sublist(liste.length - _saklanacakKimlik) : liste;
    return _depolama.yaz(_gorulenAnahtari(_hesapId), jsonEncode(kirpilmis));
  }

  Future<void> _temelCiz() async {
    try {
      final haberler = await _kaynak.getir();
      await _gorulenleriYaz({...await _gorulenler(), for (final h in haberler) h.id});
    } catch (_) {
      if (await _depolama.oku(_gorulenAnahtari(_hesapId)) == null) await _gorulenleriYaz(const []);
    }
  }

  static final _gunlukKunye = RegExp(r'^rg-\d{8}$');

  /// Akışa bakar; görülmemiş personel maddeleri için bildirim gösterir. Gösterilen bildirim sayısını döner.
  Future<int> kontrolEt() async {
    if (!_acik || _kontrolde) return 0;
    _kontrolde = true;
    try {
      final List<Haber> haberler;
      try {
        haberler = await _kaynak.getir();
      } catch (_) {
        return 0;
      }
      final gorulen = await _gorulenler();
      final bugun = _simdi();
      final yeniler = [
        for (final h in haberler)
          if (!gorulen.contains(h.id) &&
              h.resmiKaynak &&
              !_gunlukKunye.hasMatch(h.id) &&
              bugun.difference(h.yayinTarihi).inDays <= enFazlaGun)
            h,
      ];
      await _gorulenleriYaz({...gorulen, for (final h in haberler) h.id});
      if (yeniler.isEmpty) return 0;
      if (yeniler.length <= enFazlaBireysel) {
        var sira = 0;
        for (final h in yeniler) {
          await _servis.hemenGoster(
            id: bildirimKimligi + sira++,
            baslik: 'Resmî Gazete',
            govde: h.baslik.length <= 120 ? h.baslik : '${h.baslik.substring(0, 120).trimRight()}...',
          );
        }
        return yeniler.length;
      }
      await _servis.hemenGoster(
        id: bildirimKimligi,
        baslik: '${yeniler.length} yeni Resmî Gazete maddesi',
        govde: 'Kamu personelini ilgilendiren yeni maddeler yayımlandı.',
      );
      return 1;
    } finally {
      _kontrolde = false;
    }
  }

  Future<void> oturumKapandi() async => _arkaPlan?.durdur();

  /// Hesap silinirken tercih ve görülen madde kayıtları da silinir.
  Future<void> tercihiSil() async {
    _acik = false;
    await _depolama.sil(tercihAnahtari(_hesapId));
    await _depolama.sil(_gorulenAnahtari(_hesapId));
    await _arkaPlaniGuncelle();
    notifyListeners();
  }
}
