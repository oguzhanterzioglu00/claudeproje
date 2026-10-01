import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/baglanti.dart';
import '../../core/bilesenler.dart';
import '../../core/bos_durum.dart';
import '../../core/hareket.dart';
import '../../core/iskelet.dart';
import '../../core/depolama.dart';
import '../../core/metin.dart';
import '../../core/tema.dart';
import '../../core/yukselen.dart';
import '../profil/domain/profil.dart';
import 'ilan_alarm_sayfasi.dart';
import 'ilan_alarmi.dart';
import 'ilan_kaynagi.dart';
import 'ilan_modeli.dart';
import 'kayitli_ilanlar.dart';
import 'yeni_ilan_takibi.dart';

/// Otomatik derlenen kamu ilanları: arama, tür süzgeci, kaydetme ve kaynak bilgisi.
class IlanlarSayfasi extends StatefulWidget {
  const IlanlarSayfasi({
    super.key,
    this.kaynak = const OrnekIlanKaynagi(),
    this.bugun,
    this.kaynagiAc,
    this.kayitlar,
    this.alarmlar,
    this.takip,
    this.statu,
  });

  final IlanKaynagi kaynak;

  /// Kaydedilen ilanlar (cihazda kalıcı). Verilmezse ekran ömrü boyunca bellekte tutulur.
  final KayitliIlanlar? kayitlar;

  /// İlan alarmları (cihazda kalıcı). Verilmezse ekran ömrü boyunca bellekte tutulur.
  final IlanAlarmlari? alarmlar;

  /// Bildirim tercihi ve izin; alarm kurulurken kullanılır. Null ise alarm yalnızca listede işaretlenir.
  final YeniIlanTakibi? takip;
  final Statu? statu;

  /// Testlerde sabit tarih vermek için; boşsa bugün.
  final DateTime? bugun;

  /// "Kaynağı aç" düğmesi; gerçek sürümde tarayıcıda resmî sayfa açılır.
  final ValueChanged<KamuIlani>? kaynagiAc;

  @override
  State<IlanlarSayfasi> createState() => _IlanlarSayfasiState();
}

enum _Suzgec {
  tumu('Tümü'),
  kayitli('Kaydedilenler'),
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
    _Suzgec.kayitli => true,
  };
}

class _IlanlarSayfasiState extends State<IlanlarSayfasi> {
  late Future<List<KamuIlani>> _ilanlar = widget.kaynak.getir();
  final _ara = TextEditingController();
  _Suzgec _suzgec = _Suzgec.tumu;
  late final KayitliIlanlar _kayitlar = widget.kayitlar ?? KayitliIlanlar(BellekDepolama(), hesapId: 'yerel');

  late final IlanAlarmlari _alarmlar = widget.alarmlar ?? IlanAlarmlari(BellekDepolama(), hesapId: 'yerel');
  List<KamuIlani> _sonIlanlar = const [];

  @override
  void initState() {
    super.initState();
    _kayitlar.addListener(_kayitDegisti);
    _alarmlar.addListener(_kayitDegisti);
  }

  void _kayitDegisti() {
    if (mounted) setState(() {});
  }

  DateTime get _bugun => widget.bugun ?? DateTime.now();

  /// Örnek (uydurma) veri kullanılıyorsa ekranda "ÖRNEK" rozeti görünür; gerçek akışta kaynak künyesi görünür.
  bool get _ornek => widget.kaynak is OrnekIlanKaynagi;

  @override
  void dispose() {
    _kayitlar.removeListener(_kayitDegisti);
    _alarmlar.removeListener(_kayitDegisti);
    _ara.dispose();
    super.dispose();
  }

  void _yenile() {
    setState(() {
      _ilanlar = widget.kaynak.getir();
    });
  }

  /// Aşağı çekerek yenileme: yeni liste gelene (ya da hata verene) kadar göstergede bekler.
  Future<void> _cekYenile() async {
    _yenile();
    try {
      await _ilanlar;
    } catch (_) {}
  }

  bool get _kayitliSuzgeci => _suzgec == _Suzgec.kayitli;

  List<KamuIlani> _liste(List<KamuIlani> hepsi) {
    final q = normalize(_ara.text);
    return hepsi.where((i) {
      // Kaydedilenler süresi dolmuş olsa da görünür (kullanıcı kendisi kaydetmiştir).
      if (!_kayitliSuzgeci && (!i.acikMi(_bugun) || !_suzgec.uyar(i))) return false;
      if (q.isEmpty) return true;
      return normalize('${i.baslik} ${i.kurum} ${i.konum}').contains(q);
    }).toList();
  }

  Future<void> _alarmSayfasi({String onceden = ''}) => AltSayfa.goster<void>(
    context,
    builder: (c) => IlanAlarmSayfasi(
      alarmlar: _alarmlar,
      ilanlar: _sonIlanlar,
      bugun: _bugun,
      takip: widget.takip,
      statu: widget.statu,
      onceden: onceden,
    ),
  );

  Future<void> _ayrinti(KamuIlani i) => AltSayfa.goster<void>(
    context,
    builder: (c) => _Ayrinti(ilan: i, bugun: _bugun, kaynagiAc: widget.kaynagiAc),
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: FutureBuilder<List<KamuIlani>>(
      future: _ilanlar,
      builder: (context, snap) {
        if (snap.hasData) _sonIlanlar = snap.data!;
        final yukleniyor = !_kayitliSuzgeci && snap.connectionState != ConnectionState.done;
        final hata = !_kayitliSuzgeci && snap.hasError;
        final liste = _kayitliSuzgeci
            ? _liste(_kayitlar.liste)
            : snap.hasData
            ? _liste(snap.data!)
            : const <KamuIlani>[];
        // "Sana uygun" süzgeci yalnızca kaynak uyum puanı veriyorsa anlamlıdır (örnek veride var, gerçek akışta yok).
        final suzgecler = [
          for (final s in _Suzgec.values)
            if (s != _Suzgec.sanaUygun || (snap.data?.any((i) => i.uyum != null) ?? true)) s,
        ];

        return RefreshIndicator(
          color: PusulaRenk.lacivert,
          onRefresh: _cekYenile,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                            _kayitliSuzgeci
                                ? '${liste.length} kayıtlı ilan'
                                : snap.hasData
                                ? '${liste.length} açık ilan'
                                : 'İlanlar yükleniyor',
                            style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w700),
                          ),
                          Text('İlanlar', style: PusulaYazi.baslik(28, aralik: -1.2)),
                        ],
                      ),
                    ),
                    if (_ornek) ...[const OrnekRozeti(), const SizedBox(width: 8)],
                    _AlarmDugmesi(sayi: _alarmlar.liste.length, onTap: _alarmSayfasi),
                  ],
                ),
              ),
              if (!_ornek) ...[const SizedBox(height: 10), const _KaynakKunyesi()],
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
              if (_ara.text.trim().length >= 2) ...[
                const SizedBox(height: 10),
                _AramaAlarmi(
                  metin: _ara.text.trim(),
                  onTap: () => _alarmSayfasi(onceden: _ara.text.trim()),
                ),
              ],
              const SizedBox(height: 14),
              Yukselen(
                gecikme: const Duration(milliseconds: 160),
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: suzgecler.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final s = suzgecler[i];
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
                const IskeletListe()
              else if (hata)
                BosDurum(
                  gorsel: BosGorselTuru.baglanti,
                  baslik: 'İlanlar yüklenemedi',
                  alt: 'Bağlantını kontrol edip tekrar dene.',
                  dugme: 'Tekrar dene',
                  onDugme: _yenile,
                )
              else if (liste.isEmpty)
                BosDurum(
                  gorsel: _kayitliSuzgeci && _ara.text.trim().isEmpty ? BosGorselTuru.kayit : BosGorselTuru.arama,
                  baslik: _kayitliSuzgeci && _ara.text.trim().isEmpty ? 'Kayıtlı ilanın yok' : 'Uygun ilan bulunamadı',
                  alt: _kayitliSuzgeci && _ara.text.trim().isEmpty
                      ? 'Bir ilanın yanındaki işarete dokunarak kaydedebilirsin.'
                      : 'Aramayı veya süzgeci değiştirmeyi dene.',
                )
              else
                for (var k = 0; k < liste.length; k++) ...[
                  Yukselen(
                    gecikme: Duration(milliseconds: 200 + k * 70),
                    child: _IlanKarti(
                      ilan: liste[k],
                      bugun: _bugun,
                      kayitli: _kayitlar.icerir(liste[k].id),
                      alarmli: _alarmlar.uyan(liste[k]) != null,
                      onKaydet: () => _kayitlar.degistir(liste[k]),
                      onAc: () => _ayrinti(liste[k]),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        );
      },
    ),
  );
}

/// Kariyer Kapısı RSS Tasarım Kılavuzu: 100 karakteri (boşluklar dahil) aşan başlıklar "..." ile kısaltılır
/// (kartta; ayrıntı sayfasında başlığın tamamı görünür).
String _kisalt(String baslik) => baslik.length <= 100 ? baslik : '${baslik.substring(0, 100).trimRight()}...';

String _kisaTarih(DateTime t) => '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';

/// Kariyer Kapısı "RSS Tasarım Kılavuzu" gereği: logo ve "Kamu İşe Alım İlanları" ibaresi ilan listesinin üstünde.
class _KaynakKunyesi extends StatelessWidget {
  const _KaynakKunyesi();

  static final _logo = Uri.parse('https://kariyerkapisi.gov.tr/img/logo-kariyerkapisi.png');

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Kamu İşe Alım İlanları. Kaynak: Kariyer Kapısı, T.C. Cumhurbaşkanlığı',
    child: ExcludeSemantics(
      child: Row(
        children: [
          Image.network(
            _logo.toString(),
            height: 26,
            errorBuilder: (context, hata, iz) => Text(
              'Kariyer Kapısı',
              style: PusulaYazi.metin(13, renk: const Color(0xFF064890), agirlik: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Kamu İşe Alım İlanları',
              overflow: TextOverflow.ellipsis,
              style: PusulaYazi.metin(13, renk: const Color(0xFF064890), agirlik: FontWeight.w700),
            ),
          ),
        ],
      ),
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
    this.alarmli = false,
  });

  final KamuIlani ilan;
  final DateTime bugun;
  final bool kayitli;

  /// İlan kullanıcının bir alarmına uyuyor.
  final bool alarmli;
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
    final acil = kalan != null && oran > 0.9;
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
                    Text(_kisalt(ilan.baslik), style: PusulaYazi.metin(16, agirlik: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(LucideIcons.mapPin, size: 13, color: PusulaRenk.soluk),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            ilan.konum.isEmpty ? ilan.kurum : '${ilan.kurum} · ${ilan.konum}',
                            overflow: TextOverflow.ellipsis,
                            style: PusulaYazi.metin(13, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
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
                      // Kaydedince ikon yaylanarak büyüyüp yerine oturur (hareketi azalt açıksa anında değişir).
                      child: AnimatedSwitcher(
                        duration: hareketsiz ? Duration.zero : const Duration(milliseconds: 380),
                        switchInCurve: Curves.elasticOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                        child: Icon(
                          kayitli ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                          key: ValueKey(kayitli),
                          size: 20,
                          color: PusulaRenk.lacivert,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (alarmli) ...[
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Hap('Alarmına uyuyor', zemin: PusulaRenk.amber, yazi: PusulaRenk.lacivert, ikon: LucideIcons.bellRing),
            ),
          ],
          const SizedBox(height: 12),
          if (kalan == null)
            Row(
              children: [
                if (ilan.uyum != null) ...[
                  Hap(
                    '%${ilan.uyum} uyum',
                    zemin: PusulaRenk.yesilZemin,
                    yazi: PusulaRenk.yesilYazi,
                    ikon: LucideIcons.check,
                  ),
                  const SizedBox(width: 10),
                ],
                const Icon(LucideIcons.calendar, size: 14, color: PusulaRenk.lacivert),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ilan.baslamadiMi(bugun)
                        ? 'Başvurular ${_kisaTarih(ilan.yayinTarihi)} tarihinde başlar'
                        : 'Son başvuru tarihi ilan sayfasında',
                    overflow: TextOverflow.ellipsis,
                    style: PusulaYazi.metin(12, renk: PusulaRenk.lacivert, agirlik: FontWeight.w700),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                if (ilan.uyum != null) ...[
                  Hap(
                    '%${ilan.uyum} uyum',
                    zemin: PusulaRenk.yesilZemin,
                    yazi: PusulaRenk.yesilYazi,
                    ikon: LucideIcons.check,
                  ),
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
                Text(
                  kalan == 0 ? 'Bugün son' : '$kalan gün',
                  style: PusulaYazi.metin(
                    12,
                    renk: acil ? PusulaRenk.kirmizi : PusulaRenk.lacivert,
                    agirlik: FontWeight.w700,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
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
      Text(
        ilan.konum.isEmpty ? ilan.kurum : '${ilan.kurum} · ${ilan.konum}',
        style: PusulaYazi.metin(14, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: PusulaRenk.zemin, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Satir('Tür', ilan.kategori.isEmpty ? ilan.tur.etiket : ilan.kategori),
            _Satir(ilan.baslamadiMi(bugun) ? 'Başvuru başlangıcı' : 'Yayın', _tarih(ilan.yayinTarihi)),
            _Satir(
              'Son başvuru',
              ilan.sonBasvuru == null
                  ? 'İlan sayfasında yazar'
                  : '${_tarih(ilan.sonBasvuru!)} (${ilan.kalanGun(bugun)} gün kaldı)',
            ),
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
        Text(
          ad,
          style: PusulaYazi.metin(13, renk: PusulaRenk.soluk, agirlik: FontWeight.w700),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            deger,
            textAlign: TextAlign.end,
            style: PusulaYazi.metin(13, agirlik: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

/// Başlıktaki zil düğmesi: alarm sayfasını açar, kurulu alarm sayısını rozetle gösterir.
class _AlarmDugmesi extends StatelessWidget {
  const _AlarmDugmesi({required this.sayi, required this.onTap});

  final int sayi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: sayi == 0 ? 'İlan alarmları' : 'İlan alarmları, $sayi alarm kurulu',
    excludeSemantics: true,
    onTap: onTap,
    child: Basilabilir(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: sayi > 0 ? PusulaRenk.amber : PusulaRenk.beyaz,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: SizedBox.square(
                dimension: 46,
                child: Icon(sayi > 0 ? LucideIcons.bellRing : LucideIcons.bellPlus, size: 22, color: PusulaRenk.lacivert),
              ),
            ),
          ),
          if (sayi > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: PusulaRenk.lacivert,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: PusulaRenk.zemin, width: 1.5),
                ),
                child: Text('$sayi', style: PusulaYazi.metin(11, renk: PusulaRenk.beyaz, agirlik: FontWeight.w800)),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Arama kutusuna yazılan metni tek dokunuşla alarma çeviren öneri.
class _AramaAlarmi extends StatelessWidget {
  const _AramaAlarmi({required this.metin, required this.onTap});

  final String metin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Yukselen(
    child: Align(
      alignment: Alignment.centerLeft,
      child: Basilabilir(
        child: Material(
          color: PusulaRenk.amber,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.bellPlus, size: 16, color: PusulaRenk.lacivert),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '"$metin" için alarm kur',
                      overflow: TextOverflow.ellipsis,
                      style: PusulaYazi.metin(13, agirlik: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
