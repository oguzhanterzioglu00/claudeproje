import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/bilesenler.dart';
import '../../core/hareket.dart';
import '../../core/sayi_adimi.dart';
import '../../core/tema.dart';
import '../../core/ucgenler.dart';
import '../../core/yukselen.dart';
import '../araclar/presentation/arac_parcalari.dart';
import '../profil/domain/profil.dart';
import '../profil/presentation/profil_alanlari.dart';
import 'dilekce_sablonlari.dart';

/// Tarih seçici; testlerde değiştirilir. Vazgeçilirse null döner.
typedef DilekceTarihSec = Future<DateTime?> Function(BuildContext context, DateTime baslangic, DateTime ilk, DateTime son);

Future<DateTime?> _varsayilanTarihSec(BuildContext context, DateTime baslangic, DateTime ilk, DateTime son) =>
    showDatePicker(context: context, initialDate: baslangic, firstDate: ilk, lastDate: son);

/// Dilekçe araçları: bir tür seçilir, form doldurulur, profilden otomatik dolan dilekçe metni kopyalanır.
class DilekceSayfasi extends StatelessWidget {
  const DilekceSayfasi({super.key, this.profil, this.bugun, this.tarihSec = _varsayilanTarihSec});

  final Profil? profil;
  final DateTime? bugun;
  final DilekceTarihSec tarihSec;

  static const katmanlar = [
    GorselKatmani('assets/gorsel/arac/dilekce_zemin.svg', nefes: 0.035, hiz: 1, derinlik: 0.3),
    GorselKatmani('assets/gorsel/arac/dilekce_orta.svg', suzulme: 4, hiz: 2, faz: 0.25, derinlik: 0.7),
    GorselKatmani('assets/gorsel/arac/dilekce_on.svg', suzulme: 7, donme: 0.03, hiz: 3, faz: 0.5, derinlik: 1.2),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
        children: [
          const Yukselen(child: GeriBaslik(ustYazi: 'Araçlar', baslik: 'Dilekçe', sag: SizedBox.shrink())),
          const SizedBox(height: 16),
          const Yukselen(gecikme: Duration(milliseconds: 80), child: _Kapak()),
          const SizedBox(height: 14),
          for (final (i, t) in DilekceTuru.values.indexed) ...[
            Yukselen(
              gecikme: Duration(milliseconds: 140 + i * 60),
              child: _TurKarti(
                tur: t,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DilekceFormu(tur: t, profil: profil, bugun: bugun, tarihSec: tarihSec),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          const NotSatiri(
            'Şablonlar genel bir örnektir. Kurumunun kendi form ya da yazım kuralları varsa onlara uy; '
            'hukuki tavsiye yerine geçmez.',
          ),
        ],
      ),
    ),
  );
}

class _Kapak extends StatelessWidget {
  const _Kapak();

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(30),
    child: Container(
      height: 168,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PusulaRenk.mavi, PusulaRenk.lacivert],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -50,
            top: -50,
            child: Opacity(opacity: 0.12, child: PusulaUcgenler(boyut: 210, orta: PusulaRenk.beyaz)),
          ),
          const Positioned(
            right: 0,
            top: 6,
            bottom: 6,
            child: SizedBox(
              width: 172,
              child: HareketliGorsel(
                katmanlar: DilekceSayfasi.katmanlar,
                anlamEtiketi: 'Dilekçe kâğıdı, kalem ve mühür çizimi',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 166, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Hazır dilekçe',
                  style: PusulaYazi.baslik(24, renk: PusulaRenk.beyaz, aralik: -1),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bilgilerin profilinden dolar, sen yalnızca tarihi seç.',
                  style: PusulaYazi.metin(13, renk: const Color(0xFFC9D2EC), agirlik: FontWeight.w500).copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _TurKarti extends StatelessWidget {
  const _TurKarti({required this.tur, required this.onTap});

  final DilekceTuru tur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    label: '${tur.baslik}. ${tur.aciklama}',
    excludeSemantics: true,
    onTap: onTap,
    child: PusulaKart(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: tur.renk, borderRadius: BorderRadius.circular(16)),
            child: Icon(
              tur.ikon,
              size: 24,
              color: tur.renk.computeLuminance() > 0.45 ? PusulaRenk.lacivert : PusulaRenk.beyaz,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tur.baslik, style: PusulaYazi.metin(15, agirlik: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  tur.aciklama,
                  style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500).copyWith(height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Hap(tur.madde, zemin: PusulaRenk.zemin, yazi: PusulaRenk.lacivert, boyut: 11),
        ],
      ),
    ),
  );
}

/// Seçilen dilekçe türünün formu ve canlı önizlemesi.
class DilekceFormu extends StatefulWidget {
  const DilekceFormu({super.key, required this.tur, this.profil, this.bugun, this.tarihSec = _varsayilanTarihSec});

  final DilekceTuru tur;
  final Profil? profil;
  final DateTime? bugun;
  final DilekceTarihSec tarihSec;

  @override
  State<DilekceFormu> createState() => _DilekceFormuState();
}

class _DilekceFormuState extends State<DilekceFormu> {
  final _metinler = <String, TextEditingController>{};
  final _secimler = <String, String>{};
  final _tarihler = <String, DateTime>{};
  final _sayilar = <String, int>{};

  DateTime get _bugun => widget.bugun ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    for (final a in widget.tur.alanlar) {
      if (a.tur == AlanTuru.metin) _metinler[a.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _metinler.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _gorunur(DilekceAlani a) => a.id != 'yakinlik' || _secimler['olay'] == 'Yakınımın vefatı';

  DilekceSonucu get _sonuc => widget.tur.uret(
    DilekceGirdisi(
      profil: widget.profil,
      tarih: _bugun,
      metinler: {
        for (final e in _metinler.entries) e.key: e.value.text,
        ..._secimler,
      },
      tarihler: _tarihler,
      sayilar: _sayilar,
    ),
  );

  Future<void> _tarihSec(DilekceAlani a) async {
    final secilen = await widget.tarihSec(
      context,
      _tarihler[a.id] ?? _bugun,
      DateTime(_bugun.year - 1),
      DateTime(_bugun.year + 2, 12, 31),
    );
    if (secilen != null && mounted) setState(() => _tarihler[a.id] = secilen);
  }

  Future<void> _kopyala(DilekceSonucu s) async {
    final mesaj = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: s.metin));
    mesaj.showSnackBar(
      SnackBar(
        content: Text(
          s.tamam
              ? 'Dilekçe panoya kopyalandı. Yapıştırıp yazdırabilir ya da kurumunun sistemine ekleyebilirsin.'
              : 'Dilekçe kopyalandı; [...] ile işaretli boşlukları yapıştırdıktan sonra doldur.',
          style: PusulaYazi.metin(14, renk: PusulaRenk.beyaz, agirlik: FontWeight.w600),
        ),
        backgroundColor: PusulaRenk.lacivert,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tur;
    final s = _sonuc;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
          children: [
            Yukselen(child: GeriBaslik(ustYazi: 'Dilekçe · 657 sayılı Kanun ${t.madde}', baslik: t.baslik, sag: const SizedBox.shrink())),
            if (t.uyari != null) ...[const SizedBox(height: 14), NotSatiri(t.uyari!)],
            const SizedBox(height: 14),
            for (final a in t.alanlar.where(_gorunur)) ...[
              _AlanGirisi(
                alan: a,
                metin: _metinler[a.id],
                secim: _secimler[a.id],
                tarih: _tarihler[a.id],
                sayi: _sayilar[a.id],
                onDegis: () => setState(() {}),
                onSecim: (v) => setState(() => _secimler[a.id] = v),
                onTarih: () => _tarihSec(a),
                onSayi: (v) => setState(() => _sayilar[a.id] = v),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 4),
            Text('Önizleme', style: PusulaYazi.baslik(16, agirlik: FontWeight.w700, aralik: -0.4)),
            const SizedBox(height: 8),
            _Kagit(metin: s.metin),
            if (s.eksikProfil.isNotEmpty) ...[
              const SizedBox(height: 10),
              NotSatiri('Profilinde eksik: ${s.eksikProfil.join(', ')}. Profil sayfasından tamamlarsan dilekçeye otomatik yazılır.'),
            ],
            if (s.eksikAlanlar.isNotEmpty) ...[
              const SizedBox(height: 10),
              NotSatiri('Doldurulacak: ${s.eksikAlanlar.toSet().join(', ')}.'),
            ],
            const SizedBox(height: 14),
            BirincilDugme(
              metin: 'Metni kopyala',
              ikon: LucideIcons.copy,
              yukseklik: 56,
              onPressed: () => _kopyala(s),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlanGirisi extends StatelessWidget {
  const _AlanGirisi({
    required this.alan,
    required this.metin,
    required this.secim,
    required this.tarih,
    required this.sayi,
    required this.onDegis,
    required this.onSecim,
    required this.onTarih,
    required this.onSayi,
  });

  final DilekceAlani alan;
  final TextEditingController? metin;
  final String? secim;
  final DateTime? tarih;
  final int? sayi;
  final VoidCallback onDegis;
  final ValueChanged<String> onSecim;
  final VoidCallback onTarih;
  final ValueChanged<int> onSayi;

  @override
  Widget build(BuildContext context) => switch (alan.tur) {
    AlanTuru.metin => MetinAlani(
      etiket: alan.zorunlu ? alan.etiket : '${alan.etiket} (isteğe bağlı)',
      denetleyici: metin!,
      ipucu: alan.ipucu.isEmpty || alan.ipucu == 'İsteğe bağlı' ? null : alan.ipucu,
      onDegis: onDegis,
    ),
    AlanTuru.tarih => Semantics(
      button: true,
      label: '${alan.etiket}${tarih == null ? '' : ', ${DilekceTuru.tarihMetni(tarih!)}'}',
      excludeSemantics: true,
      onTap: onTarih,
      child: PusulaKart(
        onTap: onTarih,
        radius: 20,
        padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alan.etiket, style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    tarih == null ? 'Tarih seç' : DilekceTuru.tarihMetni(tarih!),
                    style: PusulaYazi.baslik(20, aralik: -0.6, renk: tarih == null ? PusulaRenk.soluk : PusulaRenk.lacivert),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.calendar, size: 22, color: PusulaRenk.lacivert),
          ],
        ),
      ),
    ),
    AlanTuru.sayi => SayiAdimi(
      etiket: alan.etiket,
      deger: sayi == null ? '—' : '$sayi',
      eksiEtiketi: '${alan.etiket} azalt',
      artiEtiketi: '${alan.etiket} artır',
      onEksi: sayi == null || sayi! <= alan.enAz ? null : () => onSayi(sayi! - 1),
      onArti: sayi != null && sayi! >= alan.enCok ? null : () => onSayi((sayi ?? alan.enAz - 1) + 1),
    ),
    AlanTuru.secim => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(alan.etiket, style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w700)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in alan.secenekler)
              Basilabilir(
                child: Semantics(
                  button: true,
                  selected: secim == o,
                  child: Material(
                    color: secim == o ? PusulaRenk.lacivert : PusulaRenk.beyaz,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onSecim(o),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Text(
                          o,
                          style: PusulaYazi.metin(
                            13,
                            renk: secim == o ? PusulaRenk.beyaz : PusulaRenk.lacivert,
                            agirlik: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  };
}

/// Dilekçe kâğıdı: köşeli parantezli boşluklar sarı vurgulanır.
class _Kagit extends StatelessWidget {
  const _Kagit({required this.metin});

  final String metin;

  static final _bosluk = RegExp(r'\[[^\]]*\]');

  @override
  Widget build(BuildContext context) {
    final stil = PusulaYazi.metin(14, agirlik: FontWeight.w500).copyWith(height: 1.55);
    final parcalar = <InlineSpan>[];
    var son = 0;
    for (final m in _bosluk.allMatches(metin)) {
      if (m.start > son) parcalar.add(TextSpan(text: metin.substring(son, m.start)));
      parcalar.add(
        TextSpan(
          text: m.group(0),
          style: const TextStyle(backgroundColor: Color(0xFFFFF1D6), fontWeight: FontWeight.w700),
        ),
      );
      son = m.end;
    }
    if (son < metin.length) parcalar.add(TextSpan(text: metin.substring(son)));
    return AnimatedSize(
      duration: PusulaHareket.orta,
      curve: PusulaHareket.yumusak,
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: PusulaRenk.beyaz,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PusulaRenk.lacivert, width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x14182350), blurRadius: 14, offset: Offset(0, 6))],
        ),
        child: SelectableText.rich(TextSpan(style: stil, children: parcalar)),
      ),
    );
  }
}
