import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/baglanti.dart';
import '../../core/bilesenler.dart';
import '../../core/metin.dart';
import '../../core/tema.dart';
import '../../core/yukselen.dart';
import 'ilan_kaynagi.dart';
import 'ilan_modeli.dart';

/// Otomatik derlenen kamu ilanları: arama, tür süzgeci, kaydetme ve kaynak bilgisi.
class IlanlarSayfasi extends StatefulWidget {
  const IlanlarSayfasi({
    super.key,
    this.kaynak = const OrnekIlanKaynagi(),
    this.bugun,
    this.kaynagiAc,
  });

  final IlanKaynagi kaynak;

  /// Testlerde sabit tarih vermek için; boşsa bugün.
  final DateTime? bugun;

  /// "Kaynağı aç" düğmesi; gerçek sürümde tarayıcıda resmî sayfa açılır.
  final ValueChanged<KamuIlani>? kaynagiAc;

  @override
  State<IlanlarSayfasi> createState() => _IlanlarSayfasiState();
}

enum _Suzgec {
  tumu('Tümü'),
  sanaUygun('Sana uygun'),
  memur('KPSS'),
  isci('İşçi alımı'),
  sozlesmeli('Sözleşmeli');

  const _Suzgec(this.etiket);

  final String etiket;

  bool uyar(KamuIlani i) => switch (this) {
        _Suzgec.tumu => true,
        _Suzgec.sanaUygun => (i.uyum ?? 0) >= 70,
        _Suzgec.memur => i.tur == IlanTuru.memur,
        _Suzgec.isci => i.tur == IlanTuru.isci,
        _Suzgec.sozlesmeli => i.tur == IlanTuru.sozlesmeli,
      };
}

class _IlanlarSayfasiState extends State<IlanlarSayfasi> {
  late Future<List<KamuIlani>> _ilanlar = widget.kaynak.getir();
  final _ara = TextEditingController();
  _Suzgec _suzgec = _Suzgec.tumu;
  final Set<String> _kayitli = {};

  DateTime get _bugun => widget.bugun ?? DateTime.now();

  @override
  void dispose() {
    _ara.dispose();
    super.dispose();
  }

  void _yenile() {
    setState(() {
      _ilanlar = widget.kaynak.getir();
    });
  }

  List<KamuIlani> _liste(List<KamuIlani> hepsi) {
    final q = normalize(_ara.text);
    return hepsi.where((i) {
      if (!i.acikMi(_bugun) || !_suzgec.uyar(i)) return false;
      if (q.isEmpty) return true;
      return normalize('${i.baslik} ${i.kurum} ${i.konum}').contains(q);
    }).toList();
  }

  Future<void> _ayrinti(KamuIlani i) => AltSayfa.goster<void>(
        context,
        builder: (c) => _Ayrinti(ilan: i, bugun: _bugun, kaynagiAc: widget.kaynagiAc),
      );

  @override
  Widget build(BuildContext context) => SafeArea(
        child: FutureBuilder<List<KamuIlani>>(
          future: _ilanlar,
          builder: (context, snap) {
            final yukleniyor = snap.connectionState != ConnectionState.done;
            final hata = snap.hasError;
            final liste = snap.hasData ? _liste(snap.data!) : const <KamuIlani>[];

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
              children: [
                Yukselen(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              snap.hasData ? '${liste.length} açık ilan' : 'İlanlar yükleniyor',
                              style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w700),
                            ),
                            Text('İlanlar', style: PusulaYazi.baslik(28, aralik: -1.2)),
                          ],
                        ),
                      ),
                      const OrnekRozeti(),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Yukselen(
                  gecikme: const Duration(milliseconds: 80),
                  child: TextField(
                    controller: _ara,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    style: PusulaYazi.metin(15, agirlik: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Kurum, unvan veya şehir ara',
                      hintStyle: PusulaYazi.metin(15, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
                      prefixIcon: const Icon(LucideIcons.search, size: 20, color: PusulaRenk.lacivert),
                      filled: true,
                      fillColor: PusulaRenk.beyaz,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Yukselen(
                  gecikme: const Duration(milliseconds: 160),
                  child: SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _Suzgec.values.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final s = _Suzgec.values[i];
                        final secili = s == _suzgec;
                        return Semantics(
                          button: true,
                          selected: secili,
                          child: Material(
                            color: secili ? PusulaRenk.lacivert : PusulaRenk.beyaz,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => setState(() => _suzgec = s),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Center(
                                  child: Text(
                                    s.etiket,
                                    style: PusulaYazi.metin(
                                      13,
                                      renk: secili ? PusulaRenk.beyaz : PusulaRenk.lacivert,
                                      agirlik: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (yukleniyor)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator(color: PusulaRenk.lacivert)),
                  )
                else if (hata)
                  _Mesaj(
                    ikon: LucideIcons.wifiOff,
                    baslik: 'İlanlar yüklenemedi',
                    alt: 'Bağlantını kontrol edip tekrar dene.',
                    dugme: 'Tekrar dene',
                    onDugme: _yenile,
                  )
                else if (liste.isEmpty)
                  const _Mesaj(
                    ikon: LucideIcons.search,
                    baslik: 'Uygun ilan bulunamadı',
                    alt: 'Aramayı veya süzgeci değiştirmeyi dene.',
                  )
                else
                  for (var k = 0; k < liste.length; k++) ...[
                    Yukselen(
                      gecikme: Duration(milliseconds: 200 + k * 70),
                      child: _IlanKarti(
                        ilan: liste[k],
                        bugun: _bugun,
                        kayitli: _kayitli.contains(liste[k].id),
                        onKaydet: () => setState(() {
                          if (!_kayitli.remove(liste[k].id)) _kayitli.add(liste[k].id);
                        }),
                        onAc: () => _ayrinti(liste[k]),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            );
          },
        ),
      );
}

class _IlanKarti extends StatelessWidget {
  const _IlanKarti({
    required this.ilan,
    required this.bugun,
    required this.kayitli,
    required this.onKaydet,
    required this.onAc,
  });

  final KamuIlani ilan;
  final DateTime bugun;
  final bool kayitli;
  final VoidCallback onKaydet;
  final VoidCallback onAc;

  static IconData _ikon(IlanTuru t) => switch (t) {
        IlanTuru.memur => LucideIcons.landmark,
        IlanTuru.isci => LucideIcons.hardHat,
        IlanTuru.sozlesmeli => LucideIcons.fileText,
        IlanTuru.diger => LucideIcons.briefcase,
      };

  static Color _renk(IlanTuru t) => switch (t) {
        IlanTuru.memur => PusulaRenk.kirmizi,
        IlanTuru.isci => PusulaRenk.lacivert,
        IlanTuru.sozlesmeli => PusulaRenk.mavi,
        IlanTuru.diger => PusulaRenk.mor,
      };

  @override
  Widget build(BuildContext context) {
    final kalan = ilan.kalanGun(bugun);
    final oran = ilan.gecenOran(bugun);
    final acil = oran > 0.9;
    final hareketsiz = MediaQuery.disableAnimationsOf(context);

    return PusulaKart(
      onTap: onAc,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: _renk(ilan.tur), borderRadius: BorderRadius.circular(16)),
                child: Icon(_ikon(ilan.tur), size: 26, color: PusulaRenk.beyaz),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ilan.baslik, style: PusulaYazi.metin(16, agirlik: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(LucideIcons.mapPin, size: 13, color: PusulaRenk.soluk),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text('${ilan.kurum} · ${ilan.konum}',
                            overflow: TextOverflow.ellipsis,
                            style: PusulaYazi.metin(13, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)),
                      ),
                    ]),
                  ],
                ),
              ),
              Semantics(
                container: true, // kartın dokunma alanına katılmasın, ayrı bir düğme olsun
                button: true,
                label: kayitli ? 'Kaydı kaldır' : 'Kaydet',
                excludeSemantics: true,
                onTap: onKaydet,
                child: Material(
                  color: kayitli ? PusulaRenk.amber : PusulaRenk.zemin,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onKaydet,
                    child: SizedBox.square(
                      dimension: 44,
                      child: Icon(
                        kayitli ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                        size: 20,
                        color: PusulaRenk.lacivert,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (ilan.uyum != null) ...[
                Hap('%${ilan.uyum} uyum',
                    zemin: PusulaRenk.yesilZemin, yazi: PusulaRenk.yesilYazi, ikon: LucideIcons.check),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: hareketsiz ? oran : 0, end: oran),
                    duration: hareketsiz ? Duration.zero : const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: PusulaRenk.cizgi,
                      color: acil ? PusulaRenk.kirmizi : PusulaRenk.lacivert,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(LucideIcons.clock, size: 14, color: PusulaRenk.lacivert),
              const SizedBox(width: 4),
              Text(kalan == 0 ? 'Bugün son' : '$kalan gün',
                  style: PusulaYazi.metin(12, renk: acil ? PusulaRenk.kirmizi : PusulaRenk.lacivert, agirlik: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Mesaj extends StatelessWidget {
  const _Mesaj({required this.ikon, required this.baslik, required this.alt, this.dugme, this.onDugme});

  final IconData ikon;
  final String baslik;
  final String alt;
  final String? dugme;
  final VoidCallback? onDugme;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: PusulaRenk.beyaz,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: PusulaRenk.lacivert, width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: PusulaRenk.cizgi, borderRadius: BorderRadius.circular(16)),
              child: Icon(ikon, size: 24, color: PusulaRenk.lacivert),
            ),
            const SizedBox(height: 8),
            Text(baslik, style: PusulaYazi.metin(16, agirlik: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(alt,
                textAlign: TextAlign.center,
                style: PusulaYazi.metin(13, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)),
            if (dugme != null) ...[
              const SizedBox(height: 14),
              BirincilDugme(metin: dugme!, onPressed: onDugme, yukseklik: 48),
            ],
          ],
        ),
      );
}

class _Ayrinti extends StatelessWidget {
  const _Ayrinti({required this.ilan, required this.bugun, this.kaynagiAc});

  final KamuIlani ilan;
  final DateTime bugun;
  final ValueChanged<KamuIlani>? kaynagiAc;

  static String _tarih(DateTime t) =>
      '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(ilan.baslik, style: PusulaYazi.baslik(22, aralik: -0.9)),
          const SizedBox(height: 4),
          Text('${ilan.kurum} · ${ilan.konum}',
              style: PusulaYazi.metin(14, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: PusulaRenk.zemin, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Satir('Tür', ilan.tur.etiket),
                _Satir('Yayın', _tarih(ilan.yayinTarihi)),
                _Satir('Son başvuru', '${_tarih(ilan.sonBasvuru)} (${ilan.kalanGun(bugun)} gün kaldı)'),
                if (ilan.ozet.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(ilan.ozet, style: PusulaYazi.metin(13, agirlik: FontWeight.w500).copyWith(height: 1.4)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.info, size: 18, color: PusulaRenk.soluk),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kaynak: ${ilan.kaynakAdi} · Son güncelleme: ${_tarih(ilan.kaynakGuncelleme)}. '
                  'İlanlar otomatik derlenir; başvurmadan önce şartları ve tarihleri kaynaktan doğrula.',
                  style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500).copyWith(height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          BirincilDugme(
            yukseklik: 56,
            metin: 'Kaynağı aç',
            ikon: LucideIcons.externalLink,
            // Bağlantısı olmayan ilanda düğme pasif; olanda tarayıcıda açılır (testte [kaynagiAc]).
            onPressed: ilan.baglanti == null
                ? null
                : () => kaynagiAc != null ? kaynagiAc!(ilan) : baglantiAc(context, ilan.baglanti),
          ),
        ],
      );
}

class _Satir extends StatelessWidget {
  const _Satir(this.ad, this.deger);

  final String ad;
  final String deger;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ad, style: PusulaYazi.metin(13, renk: PusulaRenk.soluk, agirlik: FontWeight.w700)),
            const SizedBox(width: 12),
            Flexible(child: Text(deger, textAlign: TextAlign.end, style: PusulaYazi.metin(13, agirlik: FontWeight.w700))),
          ],
        ),
      );
}
