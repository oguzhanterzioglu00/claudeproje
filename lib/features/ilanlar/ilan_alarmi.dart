import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/depolama.dart';
import '../../core/metin.dart';
import 'ilan_modeli.dart';

/// Kullanıcının kurduğu ilan alarmı: anahtar kelime(ler), isteğe bağlı il ve tür. Yeni bir ilan bunların
/// hepsine uyarsa bildirim gelir. Örnek: "zabıt katibi" + "İstanbul".
///
/// Eşleştirme Türkçe harf farkını yok sayar ("sağlik" ile "SAĞLIK" aynıdır) ve birden çok sözcük
/// yazılırsa hepsinin ilanda geçmesini ister.
class IlanAlarmi {
  const IlanAlarmi({required this.id, this.kelime = '', this.il = '', this.tur});

  final String id;
  final String kelime;
  final String il;

  /// null: her tür.
  final IlanTuru? tur;

  /// Alarmın kullanıcıya gösterilen adı: "zabıt katibi · İstanbul · Memur alımı".
  String get ad {
    final parcalar = [
      if (kelime.trim().isNotEmpty) kelime.trim(),
      if (il.trim().isNotEmpty) il.trim(),
      if (tur != null) tur!.etiket,
    ];
    return parcalar.isEmpty ? 'Tüm ilanlar' : parcalar.join(' · ');
  }

  /// İlan alarmın kelime, il ve tür koşullarının hepsine uyuyor mu?
  bool eslesir(KamuIlani i) {
    if (tur != null && i.tur != tur) return false;
    final metin = aramaAnahtari('${i.baslik} ${i.kurum} ${i.konum} ${i.kategori}');
    for (final sozcuk in aramaAnahtari(kelime).split(RegExp(r'\s+')).where((s) => s.isNotEmpty)) {
      if (!metin.contains(sozcuk)) return false;
    }
    final ilAnahtari = aramaAnahtari(il);
    if (ilAnahtari.isNotEmpty && !metin.contains(ilAnahtari)) return false;
    return true;
  }

  Map<String, Object?> toJson() => {'id': id, 'kelime': kelime, 'il': il, 'tur': tur?.name};

  /// Bozuk kayıtta null döner.
  static IlanAlarmi? fromJson(Object? j) {
    if (j is! Map<String, Object?>) return null;
    final id = j['id'];
    if (id is! String || id.isEmpty) return null;
    final kelime = j['kelime'] is String ? j['kelime']! as String : '';
    final il = j['il'] is String ? j['il']! as String : '';
    if (kelime.trim().isEmpty && il.trim().isEmpty && j['tur'] == null) return null;
    IlanTuru? tur;
    for (final t in IlanTuru.values) {
      if (t.name == j['tur']) tur = t;
    }
    return IlanAlarmi(id: id, kelime: kelime, il: il, tur: tur);
  }
}

/// Alarmların cihazda kalıcı listesi. Yalnızca bu hesaba ait ve yalnızca cihazdadır.
class IlanAlarmlari extends ChangeNotifier {
  IlanAlarmlari(this._depolama, {required String hesapId}) : _anahtar = anahtar(hesapId);

  static const enFazla = 10;

  static String anahtar(String hesapId) => 'ilan_alarmlari_v1_$hesapId';

  /// Arka plan izolatı da alarmları buradan okur (nesne paylaşılamaz, depolama paylaşılır).
  static Future<List<IlanAlarmi>> oku(AnahtarDeger depolama, String hesapId) async {
    final ham = await depolama.oku(anahtar(hesapId));
    if (ham == null) return const [];
    try {
      final j = jsonDecode(ham);
      if (j is! List) return const [];
      return [
        for (final e in j)
          if (IlanAlarmi.fromJson(e) case final a?) a,
      ];
    } catch (_) {
      return const [];
    }
  }

  final AnahtarDeger _depolama;
  final String _anahtar;
  List<IlanAlarmi> _liste = const [];
  bool _yuklendi = false;
  bool _atildi = false;

  List<IlanAlarmi> get liste => _liste;
  bool get yuklendi => _yuklendi;
  bool get dolu => _liste.length >= enFazla;

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
    var liste = <IlanAlarmi>[];
    if (ham != null) {
      try {
        final j = jsonDecode(ham);
        if (j is List) {
          liste = [
            for (final e in j)
              if (IlanAlarmi.fromJson(e) case final a?) a,
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

  /// İlana uyan ilk alarmı döner (kartta "Alarm" rozeti için); yoksa null.
  IlanAlarmi? uyan(KamuIlani i) {
    for (final a in _liste) {
      if (a.eslesir(i)) return a;
    }
    return null;
  }

  /// Alarm ekler. Boş (kelime, il ve tür yok), aynı alarm zaten varsa ya da sınır dolmuşsa false döner.
  Future<bool> ekle({String kelime = '', String il = '', IlanTuru? tur}) async {
    final k = kelime.trim();
    final i = il.trim();
    if ((k.isEmpty && i.isEmpty && tur == null) || dolu) return false;
    final ayni = _liste.any(
      (a) => aramaAnahtari(a.kelime) == aramaAnahtari(k) && aramaAnahtari(a.il) == aramaAnahtari(i) && a.tur == tur,
    );
    if (ayni) return false;
    final yeni = IlanAlarmi(id: DateTime.now().microsecondsSinceEpoch.toString(), kelime: k, il: i, tur: tur);
    _liste = [yeni, ..._liste];
    notifyListeners();
    await _kaydet();
    return true;
  }

  Future<void> sil(String id) async {
    _liste = [
      for (final a in _liste)
        if (a.id != id) a,
    ];
    notifyListeners();
    await _kaydet();
  }

  Future<void> _kaydet() => _depolama.yaz(_anahtar, jsonEncode([for (final a in _liste) a.toJson()]));

  /// Hesap silinirken.
  Future<void> temizle() async {
    _liste = const [];
    await _depolama.sil(_anahtar);
    notifyListeners();
  }
}
