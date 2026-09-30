import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/bilesenler.dart';
import '../../../core/tema.dart';
import '../../../core/ucgenler.dart';
import '../../../core/yukselen.dart';

const _soluk = Color(0xFFC9D2EC);

/// İlk açılış: uygulamayı anlatan kaydırmalı tanıtım. Son sayfadaki "Başlayalım"
/// (veya herhangi bir sayfadaki "Atla") [onBasla]'yı çağırır.
class KarsilamaSayfasi extends StatefulWidget {
  const KarsilamaSayfasi({super.key, required this.onBasla, this.becayisAcik = true});

  final VoidCallback onBasla;

  /// Kapalıyken (becayiş henüz yayında değil) becayiş slaydı gösterilmez.
  final bool becayisAcik;

  @override
  State<KarsilamaSayfasi> createState() => _KarsilamaSayfasiState();
}

class _KarsilamaSayfasiState extends State<KarsilamaSayfasi> {
  static const _becayisSlaydi = 'Becayişte eşleş';

  List<_Slayt> get _slaytlar =>
      widget.becayisAcik ? _tumSlaytlar : _tumSlaytlar.where((s) => s.baslik != _becayisSlaydi).toList();

  static const _tumSlaytlar = <_Slayt>[
    _Slayt(
      baslik: 'Hoş geldin',
      aciklama: 'Memur, sözleşmeli ve işçi — tüm kamu çalışanlarının cebindeki rehber.',
      gorsel: _MarkaGorseli(),
    ),
    _Slayt(
      baslik: 'Maaşın, net olarak',
      aciklama: 'Derece, kademe ve hizmet yılınla güncel katsayılara göre tahmini net maaşını hesapla.',
      gorsel: _MaasGorseli(),
      ornek: true,
    ),
    _Slayt(
      baslik: 'Hakkını kaynağıyla öğren',
      aciklama: 'Sorunu yaz; cevabı ilgili mevzuat maddesiyle birlikte al. Hukuki tavsiye yerine geçmez.',
      gorsel: _AsistanGorseli(),
      ornek: true,
    ),
    _Slayt(
      baslik: _becayisSlaydi,
      aciklama:
          'Aynı kurum ve sınıftaki memurlarla karşılıklı yer değiştirme eşleşmelerini bul. '
          'Talep, amirin uygun bulmasına bağlıdır.',
      gorsel: _BecayisGorseli(),
      ornek: true,
    ),
    _Slayt(
      baslik: 'İlanlar ve gündem tek yerde',
      aciklama: 'Kamu ilanlarını ve mevzuat gelişmelerini kaynağı ve tarihiyle takip et.',
      gorsel: _IlanHaberGorseli(),
      ornek: true,
    ),
  ];

  final _kontrol = PageController();
  int _sayfa = 0;

  bool get _son => _sayfa == _slaytlar.length - 1;

  @override
  void dispose() {
    _kontrol.dispose();
    super.dispose();
  }

  void _ileri() {
    if (_son) {
      widget.onBasla();
      return;
    }
    final hareketsiz = MediaQuery.disableAnimationsOf(context);
    _kontrol.nextPage(
      duration: hareketsiz ? Duration.zero : const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: PusulaRenk.lacivert,
    body: Stack(
      children: [
        // Köşeden taşan, silik logo deseni.
        const Positioned(
          right: -90,
          top: -50,
          child: Opacity(opacity: 0.08, child: PusulaUcgenler(boyut: 320, orta: PusulaRenk.mavi)),
        ),
        SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
                  child: Visibility(
                    visible: !_son,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: TextButton(
                      onPressed: widget.onBasla,
                      child: Text(
                        'Atla',
                        style: PusulaYazi.metin(14, renk: _soluk, agirlik: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _kontrol,
                  itemCount: _slaytlar.length,
                  onPageChanged: (i) => setState(() => _sayfa = i),
                  itemBuilder: (context, i) => _SlaytGorunumu(slayt: _slaytlar[i], ilk: i == 0),
                ),
              ),
              _Noktalar(sayi: _slaytlar.length, secili: _sayfa),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
                child: Column(
                  children: [
                    BirincilDugme(
                      yukseklik: 58,
                      metin: _son ? 'Başlayalım' : 'Devam',
                      ikon: LucideIcons.arrowRight,
                      onPressed: _ileri,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.shield, size: 15, color: _soluk),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Bilgilerin yalnızca bu cihazda saklanır',
                            style: PusulaYazi.metin(12, renk: _soluk, agirlik: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Slayt {
  const _Slayt({required this.baslik, required this.aciklama, required this.gorsel, this.ornek = false});

  final String baslik;
  final String aciklama;
  final Widget gorsel;

  /// Görsel örnek verilerle çizildiyse altında "Örnek görünüm" notu çıkar.
  final bool ornek;
}

class _SlaytGorunumu extends StatelessWidget {
  const _SlaytGorunumu({required this.slayt, required this.ilk});

  final _Slayt slayt;
  final bool ilk;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, kisit) {
      final gorselYuksekligi = (kisit.maxHeight * 0.5).clamp(150.0, 300.0);
      return SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: kisit.maxHeight - 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Görsel süs olduğu için yazı boyutu ayarından etkilenmez (sabit çizim).
              ExcludeSemantics(
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
                  child: SizedBox(
                    height: gorselYuksekligi,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(width: 300, child: slayt.gorsel),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 22,
                child: slayt.ornek
                    ? Center(
                        child: Text(
                          'Örnek görünüm',
                          style: PusulaYazi.metin(11, renk: _soluk.withValues(alpha: 0.7), agirlik: FontWeight.w600),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 10),
              Yukselen(
                child: Text(
                  slayt.baslik,
                  textAlign: TextAlign.center,
                  style: PusulaYazi.baslik(ilk ? 34 : 28, renk: PusulaRenk.beyaz, aralik: -1.4),
                ),
              ),
              const SizedBox(height: 12),
              Yukselen(
                gecikme: const Duration(milliseconds: 100),
                child: Text(
                  slayt.aciklama,
                  textAlign: TextAlign.center,
                  style: PusulaYazi.metin(16, renk: _soluk, agirlik: FontWeight.w500).copyWith(height: 1.45),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Noktalar extends StatelessWidget {
  const _Noktalar({required this.sayi, required this.secili});

  final int sayi;
  final int secili;

  @override
  Widget build(BuildContext context) {
    final hareketsiz = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Sayfa ${secili + 1} / $sayi',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < sayi; i++)
            AnimatedContainer(
              duration: hareketsiz ? Duration.zero : const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == secili ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == secili ? PusulaRenk.amber : PusulaRenk.beyaz.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Görseller: uygulamanın gerçek bileşenlerinin sadeleştirilmiş, örnek verili çizimleri.

class _MarkaGorseli extends StatelessWidget {
  const _MarkaGorseli();

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      label: 'Kamu Pusulası logosu',
      image: true,
      excludeSemantics: true,
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(56),
          boxShadow: [BoxShadow(color: PusulaRenk.mavi.withValues(alpha: 0.45), blurRadius: 60, spreadRadius: 4)],
        ),
        child: Image.asset('assets/marka/logo_tam.png', fit: BoxFit.contain, filterQuality: FilterQuality.medium),
      ),
    ),
  );
}

class _MaasGorseli extends StatelessWidget {
  const _MaasGorseli();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: PusulaRenk.mavi, borderRadius: BorderRadius.circular(26)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.wallet, size: 18, color: _soluk),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tahmini net maaşın',
                style: PusulaYazi.metin(13, renk: PusulaRenk.beyaz, agirlik: FontWeight.w700),
              ),
            ),
            const OrnekRozeti(),
          ],
        ),
        const SizedBox(height: 10),
        Text('₺23.457', style: PusulaYazi.baslik(42, renk: PusulaRenk.beyaz, aralik: -2)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: const LinearProgressIndicator(
            value: 0.86,
            minHeight: 8,
            backgroundColor: PusulaRenk.lacivert,
            color: PusulaRenk.amber,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final s in const ['Net ₺23.457', 'Kesinti ₺3.819', 'Brüt ₺27.276'])
              Text(
                s,
                style: PusulaYazi.metin(11, renk: PusulaRenk.beyaz, agirlik: FontWeight.w700),
              ),
          ],
        ),
      ],
    ),
  );
}

class _AsistanGorseli extends StatelessWidget {
  const _AsistanGorseli();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: PusulaRenk.amber,
            borderRadius: BorderRadius.circular(20).copyWith(bottomRight: const Radius.circular(6)),
          ),
          child: Text(
            'Becayiş şartları nedir?',
            style: PusulaYazi.metin(14, renk: PusulaRenk.lacivert, agirlik: FontWeight.w700),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: PusulaRenk.mor, borderRadius: BorderRadius.circular(12)),
            child: const Icon(LucideIcons.sparkles, size: 18, color: PusulaRenk.amber),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PusulaRenk.beyaz,
                borderRadius: BorderRadius.circular(20).copyWith(topLeft: const Radius.circular(6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aynı kurumda ve aynı sınıfta olup farklı yerlerde görev yapan memurlar karşılıklı yer değiştirebilir.',
                    style: PusulaYazi.metin(13, agirlik: FontWeight.w500).copyWith(height: 1.35),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: PusulaRenk.zemin, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.bookOpen, size: 15, color: PusulaRenk.mor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '657 sayılı DMK, md. 73',
                            style: PusulaYazi.metin(12, renk: PusulaRenk.mor, agirlik: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _BecayisGorseli extends StatelessWidget {
  const _BecayisGorseli();

  Widget _kisi(String yon) => Expanded(
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(color: PusulaRenk.beyaz, borderRadius: BorderRadius.circular(22)),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: PusulaRenk.turkuaz, shape: BoxShape.circle),
            child: const Icon(LucideIcons.userRound, size: 22, color: PusulaRenk.lacivert),
          ),
          const SizedBox(height: 8),
          Text('Hemşire', style: PusulaYazi.metin(14, agirlik: FontWeight.w700)),
          Text(
            'Sağlık Bakanlığı',
            style: PusulaYazi.metin(11, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: PusulaRenk.zemin, borderRadius: BorderRadius.circular(10)),
            child: Text(yon, style: PusulaYazi.metin(11, agirlik: FontWeight.w700)),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Stack(
        alignment: Alignment.center,
        children: [
          Row(children: [_kisi('İzmir → Ankara'), const SizedBox(width: 14), _kisi('Ankara → İzmir')]),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: PusulaRenk.amber,
              shape: BoxShape.circle,
              border: Border.all(color: PusulaRenk.lacivert, width: 3),
            ),
            child: const Icon(LucideIcons.arrowRightLeft, size: 20, color: PusulaRenk.lacivert),
          ),
        ],
      ),
      const SizedBox(height: 14),
      const Hap('Eşleşme bulundu', zemin: PusulaRenk.yesilZemin, yazi: PusulaRenk.yesilYazi, ikon: LucideIcons.check),
    ],
  );
}

class _IlanHaberGorseli extends StatelessWidget {
  const _IlanHaberGorseli();

  Widget _kart({
    required Color renk,
    required Color ikonRengi,
    required IconData ikon,
    required String baslik,
    required String alt,
    required Widget alt2,
  }) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: PusulaRenk.beyaz, borderRadius: BorderRadius.circular(22)),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: renk, borderRadius: BorderRadius.circular(14)),
          child: Icon(ikon, size: 22, color: ikonRengi),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(baslik, style: PusulaYazi.metin(14, agirlik: FontWeight.w700)),
              Text(
                alt,
                style: PusulaYazi.metin(11, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              alt2,
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _kart(
        renk: PusulaRenk.kirmizi,
        ikonRengi: PusulaRenk.beyaz,
        ikon: LucideIcons.landmark,
        baslik: 'Hemşire alımı',
        alt: 'Sağlık Bakanlığı · 81 il',
        alt2: Row(
          children: [
            const Icon(LucideIcons.clock, size: 13, color: PusulaRenk.lacivert),
            const SizedBox(width: 4),
            Text('12 gün kaldı', style: PusulaYazi.metin(11, agirlik: FontWeight.w700)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _kart(
        renk: PusulaRenk.amber,
        ikonRengi: PusulaRenk.lacivert,
        ikon: LucideIcons.banknote,
        baslik: 'Maaş katsayıları güncellendi',
        alt: 'Hazine ve Maliye Bakanlığı · Bugün',
        alt2: const Hap(
          'Resmî kaynak',
          zemin: PusulaRenk.yesilZemin,
          yazi: PusulaRenk.yesilYazi,
          ikon: LucideIcons.badgeCheck,
          boyut: 10,
        ),
      ),
    ],
  );
}
