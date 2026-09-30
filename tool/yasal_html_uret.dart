// Uygulamadaki yasal metinlerden (lib/features/ayarlar/yasal_metinler.dart) mağazaların istediği
// herkese açık sayfaları üretir: gizlilik.html, kosullar.html, hesap-silme.html.
// Kullanım: dart run tool/yasal_html_uret.dart build/web
import 'dart:io';

import 'package:pusula/features/ayarlar/yasal_metinler.dart';

String _kacis(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

String _sayfa(String baslik, String govde) => '''<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${_kacis(baslik)} — Kamu Pusulası</title>
<style>
body{font:16px/1.6 system-ui,-apple-system,Segoe UI,Roboto,sans-serif;max-width:720px;margin:0 auto;padding:24px 16px;color:#141b3a}
h1{font-size:26px;margin:0 0 4px}h2{font-size:18px;margin:28px 0 6px}p{margin:0 0 12px}
.not{color:#5b6488;font-size:14px}a{color:#2a4bd7}
</style>
</head>
<body>
$govde
<p class="not">Kamu Pusulası bağımsız bir uygulamadır; hiçbir kamu kurumunun resmî uygulaması değildir.</p>
</body>
</html>
''';

String _metin(YasalMetin m) {
  final b = StringBuffer('<h1>${_kacis(m.baslik)}</h1>\n<p class="not">${_kacis(m.guncelleme)}</p>\n');
  for (final bolum in m.bolumler) {
    b.write('<h2>${_kacis(bolum.baslik)}</h2>\n<p>${_kacis(bolum.metin)}</p>\n');
  }
  return b.toString();
}

const _hesapSilme = '''<h1>Hesap ve veri silme</h1>
<p class="not">Kamu Pusulası</p>
<h2>Uygulama içinden</h2>
<p>Profil sayfasında "Profil bilgilerimi sil" ve "Hesabımı ve verilerimi sil" düğmelerini kullanabilirsin. Hesabın,
profilin ve fotoğrafın bu işlemle telefonundan silinir.</p>
<h2>Verilerin nerede tutulur?</h2>
<p>Hesap ve profil bilgilerin yalnızca kendi telefonunda saklanır; sunucularımıza gönderilmez. Bu yüzden uygulamayı
telefonundan kaldırmak da tüm verilerini siler. Bizde silinecek bir kopya bulunmaz.</p>
<h2>Yardım</h2>
<p>Sorun yaşarsan ya da KVKK kapsamında başvuru yapmak istersen: bilgi@ayasyazilim.com.tr
(konu: "KVKK İlgili Kişi Başvurusu").</p>
''';

void main(List<String> args) {
  final hedef = Directory(args.isEmpty ? 'build/web' : args.first)..createSync(recursive: true);
  File('${hedef.path}/gizlilik.html').writeAsStringSync(_sayfa('Gizlilik / Aydınlatma Metni', _metin(YasalMetinler.aydinlatma)));
  File('${hedef.path}/kosullar.html').writeAsStringSync(_sayfa('Kullanım Koşulları', _metin(YasalMetinler.kosullar)));
  File('${hedef.path}/hesap-silme.html').writeAsStringSync(_sayfa('Hesap ve veri silme', _hesapSilme));
  stdout.writeln('Yasal sayfalar yazıldı: ${hedef.path}');
}
