import 'package:flutter/foundation.dart';

import '../../profil/domain/profil.dart';
import '../domain/eslesme.dart';
import '../domain/eslestirici.dart';
import '../domain/ilan.dart';
import '../domain/kisi_bilgisi.dart';
import 'servisler.dart';

abstract interface class BecayisIlanKaynagi {
  Future<List<Ilan>> getir();
  Future<void> kaydet(Ilan ilan);
  Future<void> kapat();
}

/// Becayiş ekranlarının ortak durumu. Arka uç bağlanınca ağ çağrıları burada
/// toplanır; ekranlar yalnızca bu sınıfı bilir.
class BecayisDeposu extends ChangeNotifier {
  BecayisDeposu({
    required Ilan benim,
    required List<Ilan> digerleri,
    required Map<String, KisiBilgisi> kisiler,
    required this.epostam,
    this.odeme = const SahteOdemeServisi(),
    this.dogrulama = const SahteDogrulamaServisi(),
    this.eslestirici = const Eslestirici(),
    this.fiyat = 249.99,
    this.ilanKaynagi,
    this.iletisimOzelligiAktif = true,
    this.dogrulamaAktif = true,
    bool yayinda = true,
  }) : _benim = benim,
       _digerleri = List.of(digerleri),
       _kisiler = Map.of(kisiler),
       _yayinda = yayinda;

  /// Becayiş arka ucu bağlanana kadar kullanılan boş depo: yayında değildir, hiçbir başka kullanıcı ya da ilan
  /// içermez (örnek/uydurma veri yok). Sekme bu durumda "Yakında" gösterir.
  factory BecayisDeposu.bos(Profil p) => BecayisDeposu(
    benim: Ilan(
      id: 'ben',
      kullaniciId: 'u-ben',
      kurumId: p.kurumKimligi,
      kurumAdi: p.kurumAdi,
      sinif: p.sinif,
      unvan: p.unvan,
      mevcutIl: p.il,
      hedefIller: const [],
      gorunenAd: 'Sen',
    ),
    digerleri: const [],
    kisiler: {
      'ben': KisiBilgisi(
        tamAd: p.ad,
        sicilNo: p.sicilNo.isEmpty ? '—' : p.sicilNo,
        telefon: '',
        eposta: p.kurumsalEposta,
      ),
    },
    epostam: p.kurumsalEposta,
    iletisimOzelligiAktif: false,
    dogrulamaAktif: false,
    yayinda: false,
  );

  final OdemeServisi odeme;
  final DogrulamaServisi dogrulama;
  final Eslestirici eslestirici;
  final Map<String, KisiBilgisi> _kisiler;
  final List<Ilan> _digerleri;

  /// Kullanıcının kurumsal e-posta adresi (mavi tik doğrulaması için).
  final String epostam;

  /// İletişim açma ücreti (₺). Mağaza fiyat basamağına göre ayarlanır.
  final double fiyat;
  final BecayisIlanKaynagi? ilanKaynagi;

  /// Canlı sürümde sunucu doğrulaması tamamlanana kadar ödeme/iletişim açma gösterilmez.
  final bool iletisimOzelligiAktif;

  /// Gerçek kod gönderme servisi yoksa sahte doğrulama arayüzü gösterilmez.
  final bool dogrulamaAktif;

  Ilan _benim;
  bool _yayinda;
  bool _odendi = false;
  bool _yukleniyor = false;
  String? _hata;
  final Set<String> _onaylar = {};

  Ilan get benim => _benim;
  bool get yayinda => _yayinda;
  bool get yukleniyor => _yukleniyor;
  String? get hata => _hata;
  List<Ilan> get digerleri => List.unmodifiable(_digerleri);
  List<Ilan> get tumIlanlar => [_benim, ..._digerleri];

  /// Kullanıcının ilanı için bulunan eşleşmeler (ikili önce, skor azalan).
  List<Eslesme> get eslesmeler =>
      _yayinda ? eslestirici.bul(tumIlanlar, ilanId: _benim.id) : const [];

  /// Bu ilan, kullanıcının bir eşleşmesinde yer alıyorsa en yüksek skoru; yoksa null.
  int? uyumSkoru(Ilan ilan) {
    int? en;
    for (final e in eslesmeler) {
      if (e.tip == EslesmeTipi.ikili && e.icerir(ilan.id)) {
        en = en == null || e.skor > en ? e.skor : en;
      }
    }
    return en;
  }

  bool onayladim(Eslesme e) => _onaylar.contains(e.id);

  /// Karşı tarafın onayı. Sahte veri: örnekte herkes ilgileniyor.
  bool karsiOnayladi(Eslesme e) => true;

  /// İki taraf da onayladı mı; ödeme yalnızca o zaman istenir.
  bool hazir(Eslesme e) => onayladim(e) && karsiOnayladi(e);

  /// İletişim, ilan başına tek seferlik ödemeyle açılır ve o ilanın tüm
  /// eşleşmeleri için geçerlidir.
  bool get iletisimAcik => _odendi;

  KisiBilgisi? kisi(String ilanId) => _odendi ? _kisiler[ilanId] : null;

  void ilgileniyorum(Eslesme e) {
    if (_onaylar.add(e.id)) notifyListeners();
  }

  /// Ödeme yalnızca eşleşme [hazir]ken yapılır.
  Future<bool> odemeYap(Eslesme e) async {
    if (!hazir(e)) return false;
    final ok = await odeme.satinAl(_benim.id);
    if (ok) {
      _odendi = true;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> epostaKoduGonder() => dogrulama.kodGonder(epostam);

  Future<bool> epostaDogrula(String kod) async {
    final ok = await dogrulama.kodDogrula(epostam, kod);
    if (ok) {
      _benim = _benim.copyWith(maviTik: true);
      notifyListeners();
    }
    return ok;
  }

  Future<bool> yenile() async {
    final kaynak = ilanKaynagi;
    if (kaynak == null) return true;
    _yukleniyor = true;
    _hata = null;
    notifyListeners();
    try {
      final ilanlar = await kaynak.getir();
      final benimIndex = ilanlar.indexWhere(
        (i) => i.kullaniciId == _benim.kullaniciId,
      );
      if (benimIndex >= 0) {
        _benim = ilanlar.removeAt(benimIndex);
        _yayinda = true;
      } else {
        _yayinda = false;
      }
      _digerleri
        ..clear()
        ..addAll(ilanlar.where((i) => i.kullaniciId != _benim.kullaniciId));
      return true;
    } catch (_) {
      _hata =
          'Becayiş ilanları şu anda yüklenemedi. Bağlantını kontrol edip tekrar dene.';
      return false;
    } finally {
      _yukleniyor = false;
      notifyListeners();
    }
  }

  Future<bool> ilanYayinla({
    required List<String> hedefIller,
    required bool zincirIzni,
  }) async {
    final eski = _benim;
    final yeni = _benim.copyWith(
      hedefIller: hedefIller,
      zincirIzni: zincirIzni,
    );
    _yukleniyor = true;
    _hata = null;
    notifyListeners();
    try {
      await ilanKaynagi?.kaydet(yeni);
      _benim = yeni;
      _yayinda = true;
      return true;
    } catch (_) {
      _benim = eski;
      _hata = 'İlan yayınlanamadı. Bağlantını kontrol edip tekrar dene.';
      return false;
    } finally {
      _yukleniyor = false;
      notifyListeners();
    }
  }

  Future<bool> ilanKapat() async {
    _yukleniyor = true;
    _hata = null;
    notifyListeners();
    try {
      await ilanKaynagi?.kapat();
      _yayinda = false;
      _benim = _benim.copyWith(hedefIller: const []);
      return true;
    } catch (_) {
      _hata = 'İlan kapatılamadı. Bağlantını kontrol edip tekrar dene.';
      return false;
    } finally {
      _yukleniyor = false;
      notifyListeners();
    }
  }
}
