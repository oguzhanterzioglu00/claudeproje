import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/depolama.dart';
import '../hatirlatici/hatirlatici_servisi.dart';
import '../profil/domain/profil.dart';
import 'arka_plan.dart';
import 'ilan_kaynagi.dart';
import 'ilan_modeli.dart';

/// [YeniIlanTakibi.kontrolSonucu] durumu.
enum KontrolDurumu { kapali, mesgul, alinamadi, yeniYok, bildirildi }

/// Yeni ilan bildirimi tercihi: açık/kapalı ve hangi ilan türleri için.
class IlanBildirimTercihi {
  const IlanBildirimTercihi({this.acik = false, this.turler = const {}});

  final bool acik;
  final Set<IlanTuru> turler;

  IlanBildirimTercihi kopya({bool? acik, Set<IlanTuru>? turler}) =>
      IlanBildirimTercihi(acik: acik ?? this.acik, turler: turler ?? this.turler);

  Map<String, Object?> toJson() => {
    'acik': acik,
    'turler': [for (final t in turler) t.name],
  };

  factory IlanBildirimTercihi.fromJson(Object? j) {
    if (j is! Map<String, Object?>) return const IlanBildirimTercihi();
    final turler = j['turler'];
    return IlanBildirimTercihi(
      acik: j['acik'] == true,
      turler: {
        if (turler is List)
          for (final t in turler)
            for (final e in IlanTuru.values)
              if (e.name == t) e,
      },
    );
  }

  /// Statüye göre makul başlangıç: memur ve sözleşmeli için memur+sözleşmeli alımı, işçi için işçi+sözleşmeli.
  static Set<IlanTuru> varsayilan(Statu? s) => switch (s) {
    Statu.memur657 || Statu.sozlesmeli => {IlanTuru.memur, IlanTuru.sozlesmeli},
    Statu.isci => {IlanTuru.isci, IlanTuru.sozlesmeli},
    _ => {for (final t in IlanTuru.values) t},
  };
}

/// Yeni kamu ilanlarını fark edip bildirim gösterir.
///
/// Uygulama açıkken ve ön plana gelince (ve açıkken belirli aralıklarla) ilan akışına bakılır; daha önce
/// görülmemiş, seçili türdeki ilanlar için cihazda bildirim gösterilir. Uygulama kapalıyken bildirim gelmez
/// (bunun için sunucu tarafı anlık bildirim gerekir). Görülen ilan kimlikleri yalnızca cihazda saklanır.
class YeniIlanTakibi extends ChangeNotifier {
  YeniIlanTakibi({
    required IlanKaynagi kaynak,
    required HatirlaticiServisi servis,
    required AnahtarDeger depolama,
    required String hesapId,
    ArkaPlanZamanlayici? arkaPlan,
    DateTime Function()? simdi,
  }) : _kaynak = kaynak,
       _arkaPlan = arkaPlan,
       _hesapId = hesapId,
       _servis = servis,
       _depolama = depolama,
       _tercihAnahtari = 'ilan_bildirim_v1_$hesapId',
       _gorulenAnahtari = 'ilan_gorulen_v1_$hesapId',
       _simdi = simdi ?? DateTime.now;

  static const bildirimKimligi = 8001;
  static const enFazlaBireysel = 3;
  static const _saklanacakKimlik = 500;

  /// Arka plan işinin hangi hesabın tercihine bakacağını bildiren kayıt anahtarı.
  static const arkaPlanHesapAnahtari = 'ilan_arka_plan_hesap_v1';

  final ArkaPlanZamanlayici? _arkaPlan;
  final String _hesapId;
  final IlanKaynagi _kaynak;
  final HatirlaticiServisi _servis;
  final AnahtarDeger _depolama;
  final String _tercihAnahtari;
  final String _gorulenAnahtari;
  final DateTime Function() _simdi;

  IlanBildirimTercihi _tercih = const IlanBildirimTercihi();
  bool _yuklendi = false;
  bool _atildi = false;
  bool _kontrolde = false;

  IlanBildirimTercihi get tercih => _tercih;
  bool get yuklendi => _yuklendi;
  bool get destekleniyor => _servis.destekleniyor;

  /// Uygulama kapalıyken de kontrol yapılabiliyor mu (Android).
  bool get arkaPlanVar => _arkaPlan?.destekleniyor ?? false;

  @override
  void notifyListeners() {
    if (!_atildi) super.notifyListeners();
  }

  @override
  void dispose() {
    _atildi = true;
    super.dispose();
  }

  Future<void> yukle() async {
    final ham = await _depolama.oku(_tercihAnahtari);
    try {
      _tercih = ham == null ? const IlanBildirimTercihi() : IlanBildirimTercihi.fromJson(jsonDecode(ham));
    } catch (_) {
      _tercih = const IlanBildirimTercihi();
    }
    _yuklendi = true;
    notifyListeners();
  }

  Future<void> _kaydet() => _depolama.yaz(_tercihAnahtari, jsonEncode(_tercih.toJson()));

  /// Bildirimi açar/kapatır. Açarken izin istenir (verilmezse açılmaz, false döner) ve mevcut ilanlar
  /// "görüldü" sayılır: yalnızca bundan sonra yayımlananlar bildirilir.
  Future<bool> ayarla(bool ac, {Statu? statu}) async {
    if (ac) {
      if (!await _servis.izinIste()) return false;
      _tercih = _tercih.kopya(
        acik: true,
        turler: _tercih.turler.isEmpty ? IlanBildirimTercihi.varsayilan(statu) : null,
      );
      await _kaydet();
      notifyListeners();
      await _temelCiz();
      await _depolama.yaz(arkaPlanHesapAnahtari, _hesapId);
      await _arkaPlan?.baslat();
    } else {
      _tercih = _tercih.kopya(acik: false);
      await _kaydet();
      notifyListeners();
      await _arkaPlan?.durdur();
    }
    return true;
  }

  /// Uygulama açılırken: bildirim açıksa arka plan kontrolünü (yeniden) kurar, kapalıysa durdurur.
  Future<void> arkaPlaniSenkronla() async {
    if (_tercih.acik) {
      await _depolama.yaz(arkaPlanHesapAnahtari, _hesapId);
      await _arkaPlan?.baslat();
    } else {
      await _arkaPlan?.durdur();
    }
  }

  /// Oturum kapanınca: bu cihazda başkasının hesabına ait arka plan bildirimi kalmasın. Tercih korunur;
  /// aynı hesapla yeniden girilince [arkaPlaniSenkronla] tekrar kurar.
  Future<void> oturumKapandi() async {
    if (await _depolama.oku(arkaPlanHesapAnahtari) == _hesapId) await _depolama.sil(arkaPlanHesapAnahtari);
    await _arkaPlan?.durdur();
  }

  Future<void> turAyarla(IlanTuru tur, bool secili) async {
    final yeni = {..._tercih.turler};
    secili ? yeni.add(tur) : yeni.remove(tur);
    _tercih = _tercih.kopya(turler: yeni);
    await _kaydet();
    notifyListeners();
  }

  Future<Set<String>> _gorulenler() async {
    final ham = await _depolama.oku(_gorulenAnahtari);
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
    return _depolama.yaz(_gorulenAnahtari, jsonEncode(kirpilmis));
  }

  Future<void> _temelCiz() async {
    try {
      final ilanlar = await _kaynak.getir();
      await _gorulenleriYaz({...await _gorulenler(), for (final i in ilanlar) i.id});
    } catch (_) {
      // Akış şu an alınamadı: ilk başarılı kontrolde bildirim gitmesin diye temel boş bırakılmaz, sonraki kontrol dener.
      if (await _depolama.oku(_gorulenAnahtari) == null) await _gorulenleriYaz(const []);
    }
  }

  /// Akışa bakar; yeni ve seçili türdeki ilanlar için bildirim gösterir. Gösterilen bildirim sayısını döner.
  Future<int> kontrolEt() async => (await kontrolSonucu()).bildirim;

  /// [kontrolEt] ile aynı işi yapar ve ne olduğunu da bildirir (ayarlardaki "Şimdi kontrol et" için).
  Future<({KontrolDurumu durum, int bildirim, int bakilan})> kontrolSonucu() async {
    if (!_tercih.acik) return (durum: KontrolDurumu.kapali, bildirim: 0, bakilan: 0);
    if (_kontrolde) return (durum: KontrolDurumu.mesgul, bildirim: 0, bakilan: 0);
    _kontrolde = true;
    try {
      final List<KamuIlani> ilanlar;
      try {
        ilanlar = await _kaynak.getir();
      } catch (_) {
        return (durum: KontrolDurumu.alinamadi, bildirim: 0, bakilan: 0);
      }
      final gorulen = await _gorulenler();
      final bugun = _simdi();
      final yeniler = [
        for (final i in ilanlar)
          if (!gorulen.contains(i.id) && _tercih.turler.contains(i.tur) && i.acikMi(bugun)) i,
      ];
      await _gorulenleriYaz({...gorulen, for (final i in ilanlar) i.id});
      if (yeniler.isEmpty) return (durum: KontrolDurumu.yeniYok, bildirim: 0, bakilan: ilanlar.length);
      if (yeniler.length <= enFazlaBireysel) {
        var sira = 0;
        for (final i in yeniler) {
          await _servis.hemenGoster(
            id: bildirimKimligi + sira++,
            baslik: i.kurum.isEmpty ? 'Yeni kamu ilanı' : 'Yeni ilan: ${i.kurum}',
            govde: i.baslik,
          );
        }
        return (durum: KontrolDurumu.bildirildi, bildirim: yeniler.length, bakilan: ilanlar.length);
      }
      await _servis.hemenGoster(
        id: bildirimKimligi,
        baslik: '${yeniler.length} yeni kamu ilanı',
        govde: '${[for (final i in yeniler.take(2)) i.kurum.isEmpty ? i.baslik : i.kurum].join(', ')} ve diğerleri',
      );
      return (durum: KontrolDurumu.bildirildi, bildirim: 1, bakilan: ilanlar.length);
    } finally {
      _kontrolde = false;
    }
  }

  /// Bildirimin çalıştığını denemek için hemen bir test bildirimi gösterir. Bildirimler telefon
  /// ayarlarında kapalıysa false döner (bildirim gösterilmez).
  Future<bool> testBildirimiGonder() async {
    if (!await _servis.bildirimlerAcikMi()) return false;
    await _servis.hemenGoster(
      id: bildirimKimligi + 9,
      baslik: 'Kamu Pusulası test bildirimi',
      govde: 'Bildirimler çalışıyor. Yeni ilan çıktığında böyle haber vereceğim.',
    );
    return true;
  }

  /// Hesap silinirken tercih ve görülen ilan kayıtları da silinir.
  Future<void> tercihiSil() async {
    _tercih = const IlanBildirimTercihi();
    await _depolama.sil(_tercihAnahtari);
    await _depolama.sil(_gorulenAnahtari);
    if (await _depolama.oku(arkaPlanHesapAnahtari) == _hesapId) await _depolama.sil(arkaPlanHesapAnahtari);
    await _arkaPlan?.durdur();
    notifyListeners();
  }
}
