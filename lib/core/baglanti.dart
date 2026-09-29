import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'tema.dart';

/// Bir adresi dış uygulamada (tarayıcı) açar; açılabildiyse true döner.
typedef BaglantiAcici = Future<bool> Function(Uri adres);

Future<bool> _varsayilanAcici(Uri adres) => launchUrl(adres, mode: LaunchMode.externalApplication);

/// Kaynak bağlantısını açar. Güvenlik için yalnızca `https` adresleri açılır;
/// açılamazsa kullanıcıya kısa bir mesaj gösterilir. [acici] testlerde değiştirilir.
Future<void> baglantiAc(BuildContext context, Uri? adres, {BaglantiAcici? acici}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  var acildi = false;
  if (adres != null && adres.scheme == 'https') {
    try {
      acildi = await (acici ?? _varsayilanAcici)(adres);
    } catch (_) {
      acildi = false;
    }
  }
  if (!acildi) {
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          'Bağlantı açılamadı. Adresi kaynağın sitesinden kontrol et.',
          style: PusulaYazi.metin(14, renk: PusulaRenk.beyaz, agirlik: FontWeight.w600),
        ),
        backgroundColor: PusulaRenk.lacivert,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
