import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../../core/akis.dart';
import '../../core/depolama.dart';
import '../hatirlatici/hatirlatici_servisi.dart';
import '../haberler/haber_kaynagi.dart';
import '../haberler/yeni_haber_takibi.dart';
import 'ilan_kaynagi.dart';
import 'yeni_ilan_takibi.dart';

/// Uygulama kapalıyken yeni ilan kontrolünü zamanlayan altyapı. Sunucu ya da üçüncü taraf hesabı gerekmez:
/// telefon kendisi periyodik olarak ilan akışına bakar.
abstract interface class ArkaPlanZamanlayici {
  /// Bu platformda arka plan kontrolü var mı (yalnızca Android).
  bool get destekleniyor;

  Future<void> baslat();

  Future<void> durdur();
}

/// Android'de `workmanager` ile en sık 15 dakikada bir çalışır (Android'in alt sınırı); sistem pil tasarrufu
/// için ertelenebilir, üreticiye özgü pil ayarları ("uygulamayı uyut") gecikmeyi artırabilir. iOS'ta ve
/// web'de hiçbir şey yapmaz.
class WorkmanagerZamanlayici implements ArkaPlanZamanlayici {
  const WorkmanagerZamanlayici();

  static const gorevAdi = 'yeni-ilan-kontrolu';

  @override
  bool get destekleniyor => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// `main()`'de bir kez çağrılır; arka plan izolatının giriş noktasını kaydeder.
  static Future<void> hazirla() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await Workmanager().initialize(arkaPlanGirisi);
    } catch (e) {
      debugPrint('Arka plan altyapısı hazırlanamadı: $e');
    }
  }

  @override
  Future<void> baslat() async {
    if (!destekleniyor) return;
    try {
      await Workmanager().registerPeriodicTask(
        gorevAdi,
        gorevAdi,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
    } catch (e) {
      debugPrint('Arka plan kontrolü başlatılamadı: $e');
    }
  }

  @override
  Future<void> durdur() async {
    if (!destekleniyor) return;
    try {
      await Workmanager().cancelByUniqueName(gorevAdi);
    } catch (e) {
      debugPrint('Arka plan kontrolü durdurulamadı: $e');
    }
  }
}

/// Testler için: çağrıları sayar.
class SahteArkaPlanZamanlayici implements ArkaPlanZamanlayici {
  SahteArkaPlanZamanlayici({this.destekleniyor = true});

  @override
  final bool destekleniyor;
  int baslatildi = 0;
  int durduruldu = 0;

  @override
  Future<void> baslat() async => baslatildi++;

  @override
  Future<void> durdur() async => durduruldu++;
}

/// Bu hesapta ilan ya da Resmî Gazete bildirimlerinden biri açıksa arka plan işini başlatır (hesap kaydıyla
/// birlikte), ikisi de kapalıysa durdurur. Tercihleri depolamadan okur, böylece iki takipçi birbirini bilmeden
/// aynı işi paylaşır.
Future<void> arkaPlaniGuncelle({
  required AnahtarDeger depolama,
  required String hesapId,
  ArkaPlanZamanlayici? zamanlayici,
}) async {
  final ilanAcik = IlanBildirimTercihi.acikMi(await depolama.oku(YeniIlanTakibi.tercihAnahtari(hesapId)));
  final haberAcik = YeniHaberTakibi.tercihAcikMi(await depolama.oku(YeniHaberTakibi.tercihAnahtari(hesapId)));
  if (ilanAcik || haberAcik) {
    await depolama.yaz(YeniIlanTakibi.arkaPlanHesapAnahtari, hesapId);
    await zamanlayici?.baslat();
  } else {
    if (await depolama.oku(YeniIlanTakibi.arkaPlanHesapAnahtari) == hesapId) {
      await depolama.sil(YeniIlanTakibi.arkaPlanHesapAnahtari);
    }
    await zamanlayici?.durdur();
  }
}

/// Arka plan işinin yaptığı: kayıtlı hesabın tercihlerini okur, açık olanlar için ilan ve Resmî Gazete akışına
/// bakıp yenileri bildirir. Ayrı bir izolatta çalıştığı için yalnızca cihaz depolamasına ve ağa dayanır. Hesap
/// kaydı yoksa ya da hiçbir bildirim açık değilse hiçbir şey yapmaz; bir kontrol yapıldıysa true döner.
Future<bool> arkaPlanKontrolu({
  required AnahtarDeger depolama,
  required IlanKaynagi kaynak,
  required HatirlaticiServisi servis,
  HaberKaynagi? haberKaynagi,
  DateTime Function()? simdi,
}) async {
  final hesapId = await depolama.oku(YeniIlanTakibi.arkaPlanHesapAnahtari);
  if (hesapId == null || hesapId.isEmpty) return false;
  var kontrolEdildi = false;
  final ilan = YeniIlanTakibi(kaynak: kaynak, servis: servis, depolama: depolama, hesapId: hesapId, simdi: simdi);
  try {
    await ilan.yukle();
    if (ilan.tercih.acik) {
      await ilan.kontrolEt();
      kontrolEdildi = true;
    }
  } finally {
    ilan.dispose();
  }
  if (haberKaynagi != null) {
    final haber = YeniHaberTakibi(
      kaynak: haberKaynagi,
      servis: servis,
      depolama: depolama,
      hesapId: hesapId,
      simdi: simdi,
    );
    try {
      await haber.yukle();
      if (haber.acik) {
        await haber.kontrolEt();
        kontrolEdildi = true;
      }
    } finally {
      haber.dispose();
    }
  }
  return kontrolEdildi;
}

/// Arka plan izolatının giriş noktası (`Workmanager().initialize` buna bağlanır).
@pragma('vm:entry-point')
void arkaPlanGirisi() {
  Workmanager().executeTask((gorev, girdi) async {
    try {
      final istemci = AkisIstemcisi(onbellek: Duration.zero);
      await arkaPlanKontrolu(
        depolama: const YerelDepolama(),
        kaynak: AkisIlanKaynagi(istemci),
        haberKaynagi: AkisHaberKaynagi(istemci),
        servis: YerelHatirlaticiServisi(),
      );
      return true;
    } catch (e) {
      debugPrint('Arka plan kontrolü başarısız: $e');
      return false; // WorkManager yeniden dener
    }
  });
}
