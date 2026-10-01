import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/depolama.dart';
import 'ilan_modeli.dart';

/// Kullanıcının kaydettiği ilanlar. Ilanın kendisi (başlık, kurum, tarihler, bağlantı) saklanır; böylece
/// ilan akıştan kalksa ya da internet olmasa da "Kaydedilenler"de görünür. Yalnızca cihazda tutulur.
class KayitliIlanlar extends ChangeNotifier {
  KayitliIlanlar(this._depolama, {required String hesapId}) : _anahtar = 'kayitli_ilanlar_v1_$hesapId';

  static const enFazla = 100;

  final AnahtarDeger _depolama;
  final String _anahtar;
  List<KamuIlani> _liste = const [];
  bool _yuklendi = false;
  bool _atildi = false;

  /// En son kaydedilen başta.
  List<KamuIlani> get liste => _liste;
  bool get yuklendi => _yuklendi;
  bool icerir(String id) => _liste.any((i) => i.id == id);

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
    final ham = await _depolama.oku(_anahtar);
    var liste = <KamuIlani>[];
    if (ham != null) {
      try {
        final j = jsonDecode(ham);
        if (j is List) {
          liste = [
            for (final e in j)
              if (KamuIlani.fromJson(e) case final i?) i,
          ];
        }
      } catch (_) {
        liste = [];
      }
    }
    _liste = liste;
    _yuklendi = true;
    notifyListeners();
  }

  /// Kayıtlıysa kaldırır, değilse başa ekler.
  Future<void> degistir(KamuIlani ilan) async {
    if (icerir(ilan.id)) {
      _liste = [
        for (final i in _liste)
          if (i.id != ilan.id) i,
      ];
    } else {
      _liste = [ilan, ..._liste].take(enFazla).toList();
    }
    notifyListeners();
    await _depolama.yaz(_anahtar, jsonEncode([for (final i in _liste) i.toJson()]));
  }

  /// Yedekten gelen ilanları mevcutların arkasına ekler (aynı kimlikli olanlar atlanır, sınır korunur).
  /// Eklenen ilan sayısını döner.
  Future<int> birlestir(Iterable<KamuIlani> gelen) async {
    final yeni = [
      for (final i in gelen)
        if (!icerir(i.id)) i,
    ];
    final bos = enFazla - _liste.length;
    final eklenecek = yeni.take(bos < 0 ? 0 : bos).toList();
    if (eklenecek.isEmpty) return 0;
    _liste = [..._liste, ...eklenecek];
    notifyListeners();
    await _depolama.yaz(_anahtar, jsonEncode([for (final i in _liste) i.toJson()]));
    return eklenecek.length;
  }

  /// Hesap silinirken.
  Future<void> temizle() async {
    _liste = const [];
    await _depolama.sil(_anahtar);
    notifyListeners();
  }
}
