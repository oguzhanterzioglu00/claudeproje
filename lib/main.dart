import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry, TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/depolama.dart';
import 'core/tema.dart';
import 'core/sunucu_ayari.dart';
import 'core/telefon_cercevesi.dart';
import 'core/akis.dart';
import 'features/haberler/haber_kaynagi.dart';
import 'features/hatirlatici/hatirlatici_servisi.dart';
import 'features/hesap/data/kimlik_servisi.dart';
import 'features/hesap/data/oturum_deposu.dart';
import 'features/hesap/data/supabase_kimlik_istemcisi.dart';
import 'features/hesap/data/supabase_kimlik_servisi.dart';
import 'features/hesap/data/yerel_kimlik_servisi.dart';
import 'features/ilanlar/arka_plan.dart';
import 'features/ilanlar/ilan_kaynagi.dart';
import 'features/kabuk/uygulama_akisi.dart';
import 'features/profil/data/fotograf_deposu.dart';
import 'features/profil/data/profil_kaydi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _yaziTipiLisanslariniKaydet();
  await WorkmanagerZamanlayici.hazirla();
  // Arka uç ayarı verilmişse gerçek hesaplar (e-posta, Google); verilmemişse cihaz içi örnek hesap.
  KimlikServisi? kimlik;
  if (SunucuAyari.tanimli) {
    await Supabase.initialize(url: SunucuAyari.url, publishableKey: SunucuAyari.anahtar);
    kimlik = SupabaseKimlikServisi(
      SupabaseKimlikIstemcisi(Supabase.instance.client),
      googleSunucuIstemcisi: SunucuAyari.googleWebIstemcisi,
    );
  }
  // Apple ile giriş yalnızca iPhone/iPad'de yerel olarak çalışır (Android'de düğme gösterilmez).
  runApp(PusulaUygulamasi(kimlik: kimlik, appleGoster: !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS));
}

/// Uygulamaya gömülü yazı tiplerinin (SIL Open Font License 1.1) lisans sayfasında görünmesi için.
void _yaziTipiLisanslariniKaydet() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['Sora', 'Figtree', 'Noto Sans (yalnızca ₺ işareti)'],
      'Bu yazı tipleri SIL Open Font License, Version 1.1 kapsamında lisanslanmıştır.\n'
      'Tam metin: https://openfontlicense.org\n\n'
      'Sora © The Sora Project Authors; Figtree © The Figtree Project Authors; '
      'Noto Sans © The Noto Project Authors.',
    );
  });
}

/// Uygulama kökü. Bağımlılıklar (kimlik servisi, depolama, fotoğraf kaynağı)
/// testlerde ve ileride gerçek arka uçla değiştirilebilir.
class PusulaUygulamasi extends StatefulWidget {
  const PusulaUygulamasi({
    super.key,
    this.kimlik,
    this.depolama = const YerelDepolama(),
    this.profilKaydiUret,
    this.fotografKaynagi = const ImagePickerFotografKaynagi(),
    this.appleGoster = false,
    this.sosyalGiris = false,
    this.becayisAcik = false,
    this.hatirlatici,
    this.ilanKaynagi,
    this.haberKaynagi,
    this.arkaPlan = const WorkmanagerZamanlayici(),
  });

  /// Boşsa cihazda çalışan örnek servis ([YerelKimlikServisi]); gerçek sürümde [SupabaseKimlikServisi] verilir.
  final KimlikServisi? kimlik;
  final AnahtarDeger depolama;
  final ProfilKaydi Function(String hesapId)? profilKaydiUret;
  final FotografKaynagi fotografKaynagi;
  final bool appleGoster;

  /// Google/Apple girişi henüz gerçek olmadığı için mağaza sürümünde kapalıdır.
  final bool sosyalGiris;

  /// Becayiş eşleştirme arka uç ve ödeme bağlanana kadar kapalıdır (sekmede "Yakında" görünür).
  final bool becayisAcik;

  /// Boşsa cihaz bildirimleriyle çalışan servis; testlerde sahtesi verilir.
  final HatirlaticiServisi? hatirlatici;

  /// Boşsa gerçek akış (Kariyer Kapısı ilanları, Resmî Gazete haberleri); testlerde örnek/sahte kaynak verilir.
  final IlanKaynagi? ilanKaynagi;
  final HaberKaynagi? haberKaynagi;

  /// Uygulama kapalıyken yeni ilan kontrolü; varsayılan Android'de `workmanager` (testlerde sahtesi verilir).
  final ArkaPlanZamanlayici arkaPlan;

  @override
  State<PusulaUygulamasi> createState() => _PusulaUygulamasiState();
}

class _PusulaUygulamasiState extends State<PusulaUygulamasi> with WidgetsBindingObserver {
  late final OturumDeposu _oturum = OturumDeposu(widget.kimlik ?? YerelKimlikServisi(depolama: widget.depolama));

  late final HatirlaticiServisi _hatirlatici = widget.hatirlatici ?? YerelHatirlaticiServisi();
  late final AkisIstemcisi _akis = AkisIstemcisi();
  late final IlanKaynagi _ilanKaynagi = widget.ilanKaynagi ?? AkisIlanKaynagi(_akis);
  late final HaberKaynagi _haberKaynagi = widget.haberKaynagi ?? AkisHaberKaynagi(_akis);

  @override
  void initState() {
    super.initState();
    _oturum.yukle();
    WidgetsBinding.instance.addObserver(this);
  }

  /// Tarayıcıdaki Google girişinden vazgeçilip uygulamaya dönülürse bekleyen giriş iptal edilir.
  @override
  void didChangeAppLifecycleState(AppLifecycleState durum) {
    if (durum == AppLifecycleState.resumed) {
      final k = widget.kimlik;
      if (k is SupabaseKimlikServisi) k.uygulamaOnePlanaGeldi();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _oturum.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Kamu Pusulası',
    debugShowCheckedModeBanner: false,
    theme: pusulaTema(),
    // Tarih seçici, iptal/tamam düğmeleri ve klavye Türkçe olsun.
    locale: const Locale('tr', 'TR'),
    supportedLocales: const [Locale('tr', 'TR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (context, child) => TelefonCercevesi(child: child!),
    home: UygulamaAkisi(
      oturum: _oturum,
      depolama: widget.depolama,
      profilKaydiUret: widget.profilKaydiUret ?? (id) => YerelProfilKaydi(hesapId: id),
      fotografKaynagi: widget.fotografKaynagi,
      appleGoster: widget.appleGoster,
      sosyalGiris: widget.sosyalGiris,
      becayisAcik: widget.becayisAcik,
      hatirlatici: _hatirlatici,
      ilanKaynagi: _ilanKaynagi,
      haberKaynagi: _haberKaynagi,
      arkaPlan: widget.arkaPlan,
    ),
  );
}
