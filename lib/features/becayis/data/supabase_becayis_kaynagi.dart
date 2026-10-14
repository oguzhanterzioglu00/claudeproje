import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profil/domain/profil.dart';
import '../domain/ilan.dart';
import 'becayis_deposu.dart';
import 'servisler.dart';

class SupabaseBecayisKaynagi implements BecayisIlanKaynagi {
  SupabaseBecayisKaynagi(this.client, {required this.kullaniciId});

  final SupabaseClient client;
  final String kullaniciId;

  @override
  Future<List<Ilan>> getir() async {
    final rows = await client
        .from('becayis_ilanlari')
        .select(
          'user_id,kurum_id,kurum_adi,sinif,unvan,mevcut_il,hedef_iller,zincir_izni,mavi_tik,gorunen_ad,aktif',
        )
        .eq('aktif', true)
        .order('guncelleme', ascending: false);
    return rows
        .map((e) => Ilan.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: true);
  }

  @override
  Future<void> kaydet(Ilan ilan) => client
      .from('becayis_ilanlari')
      .upsert(ilan.toJson(), onConflict: 'user_id');

  @override
  Future<void> kapat() => client
      .from('becayis_ilanlari')
      .update({'aktif': false})
      .eq('user_id', kullaniciId);
}

BecayisDeposu supabaseBecayisDeposu(
  SupabaseClient client,
  Profil profil, {
  bool odemeAktif = false,
}) {
  final kullaniciId = client.auth.currentUser?.id;
  if (kullaniciId == null) return BecayisDeposu.bos(profil);
  final depo = BecayisDeposu(
    benim: Ilan(
      id: kullaniciId,
      kullaniciId: kullaniciId,
      kurumId: profil.kurumKimligi,
      kurumAdi: profil.kurumAdi,
      sinif: profil.sinif,
      unvan: profil.unvan,
      mevcutIl: profil.il,
      hedefIller: const [],
      zincirIzni: false,
      gorunenAd: _gizliAd(profil.ad),
    ),
    digerleri: const [],
    kisiler: const {},
    epostam: profil.kurumsalEposta,
    ilanKaynagi: SupabaseBecayisKaynagi(client, kullaniciId: kullaniciId),
    odeme: odemeAktif
        ? MagazaOdemeServisi(dogrulayici: SupabaseMakbuzDogrulayici(client))
        : const SahteOdemeServisi(basarili: false),
    iletisimOzelligiAktif: odemeAktif,
    dogrulamaAktif: false,
    yayinda: false,
  );
  unawaited(depo.yenile());
  return depo;
}

String _gizliAd(String tamAd) {
  final parcalar = tamAd
      .trim()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .toList();
  if (parcalar.isEmpty) return 'Kullanıcı';
  final ilkHarf = String.fromCharCode(parcalar.first.runes.first).toUpperCase();
  if (parcalar.length == 1) {
    return '$ilkHarf.';
  }
  return '$ilkHarf. ${parcalar.last}';
}
