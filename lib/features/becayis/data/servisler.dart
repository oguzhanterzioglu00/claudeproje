import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Uygulama içi satın alma. Gerçek sürümde `in_app_purchase` ile mağaza ödemesi
/// yapılır ve makbuz sunucuda doğrulanır (bkz. docs/becayis-spec.md §4).
abstract interface class OdemeServisi {
  /// [ilanId] için iletişim açma ürününü satın alır; başarılıysa true.
  Future<bool> satinAl(String ilanId);
}

abstract interface class MakbuzDogrulayici {
  Future<bool> dogrula({
    required String ilanId,
    required String urunKodu,
    required String kaynak,
    required String makbuz,
    String? islemZamani,
  });
}

/// Apple App Store ve Google Play satın almasını başlatır. Yetki yalnızca
/// Supabase Edge Function makbuzu mağaza sunucusunda doğrularsa açılır.
class MagazaOdemeServisi implements OdemeServisi {
  MagazaOdemeServisi({
    required this.dogrulayici,
    InAppPurchase? magaza,
    this.urunKodu = 'becayis_iletisim_ilan',
  }) : _magaza = magaza ?? InAppPurchase.instance;

  final MakbuzDogrulayici dogrulayici;
  final InAppPurchase _magaza;
  final String urunKodu;

  @override
  Future<bool> satinAl(String ilanId) async {
    if (!await _magaza.isAvailable()) return false;
    final sorgu = await _magaza.queryProductDetails({urunKodu});
    if (sorgu.error != null || sorgu.productDetails.isEmpty) return false;

    final sonuc = Completer<bool>();
    late final StreamSubscription<List<PurchaseDetails>> abonelik;
    abonelik = _magaza.purchaseStream.listen(
      (satinAlmalar) async {
        for (final satinAlma in satinAlmalar.where(
          (p) => p.productID == urunKodu,
        )) {
          if (satinAlma.status == PurchaseStatus.purchased ||
              satinAlma.status == PurchaseStatus.restored) {
            final dogrulandi = await dogrulayici.dogrula(
              ilanId: ilanId,
              urunKodu: urunKodu,
              kaynak: satinAlma.verificationData.source,
              makbuz: satinAlma.verificationData.serverVerificationData,
              islemZamani: satinAlma.transactionDate,
            );
            if (dogrulandi && satinAlma.pendingCompletePurchase) {
              await _magaza.completePurchase(satinAlma);
            }
            if (!sonuc.isCompleted) sonuc.complete(dogrulandi);
          } else if (satinAlma.status == PurchaseStatus.error ||
              satinAlma.status == PurchaseStatus.canceled) {
            if (!sonuc.isCompleted) sonuc.complete(false);
          }
        }
      },
      onError: (_) {
        if (!sonuc.isCompleted) sonuc.complete(false);
      },
    );

    final basladi = await _magaza.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: sorgu.productDetails.first),
    );
    if (!basladi && !sonuc.isCompleted) sonuc.complete(false);
    final tamam = await sonuc.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () => false,
    );
    await abonelik.cancel();
    return tamam;
  }
}

class SupabaseMakbuzDogrulayici implements MakbuzDogrulayici {
  const SupabaseMakbuzDogrulayici(this.client);

  final SupabaseClient client;

  @override
  Future<bool> dogrula({
    required String ilanId,
    required String urunKodu,
    required String kaynak,
    required String makbuz,
    String? islemZamani,
  }) async {
    final yanit = await client.functions.invoke(
      'becayis-odeme-dogrula',
      body: {
        'ilan_id': ilanId,
        'urun_kodu': urunKodu,
        'kaynak': kaynak,
        'makbuz': makbuz,
        'islem_zamani': islemZamani,
      },
    );
    return yanit.status == 200 &&
        yanit.data is Map &&
        yanit.data['dogrulandi'] == true;
  }
}

/// Kurumsal e-posta doğrulaması (bkz. docs/becayis-spec.md §5).
abstract interface class DogrulamaServisi {
  /// Yalnızca .gov.tr / .edu.tr adreslerine kod gönderir; geçersiz adreste false.
  Future<bool> kodGonder(String eposta);

  Future<bool> kodDogrula(String eposta, String kod);
}

/// Arka uç ve mağaza bağlanana kadar kullanılan sahte servisler.
class SahteOdemeServisi implements OdemeServisi {
  const SahteOdemeServisi({
    this.sure = const Duration(milliseconds: 1500),
    this.basarili = true,
  });

  final Duration sure;
  final bool basarili;

  @override
  Future<bool> satinAl(String ilanId) async {
    await Future<void>.delayed(sure);
    return basarili;
  }
}

class SahteDogrulamaServisi implements DogrulamaServisi {
  const SahteDogrulamaServisi();

  static bool kurumsalMi(String eposta) {
    final e = eposta.trim().toLowerCase();
    return e.contains('@') && (e.endsWith('.gov.tr') || e.endsWith('.edu.tr'));
  }

  @override
  Future<bool> kodGonder(String eposta) async => kurumsalMi(eposta);

  /// Sahte: 6 haneli herhangi bir kod kabul edilir.
  @override
  Future<bool> kodDogrula(String eposta, String kod) async =>
      kurumsalMi(eposta) && RegExp(r'^\d{6}$').hasMatch(kod);
}
