import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/bilesenler.dart';
import '../../core/bos_durum.dart';
import '../../core/hareket.dart';
import '../../core/tema.dart';
import '../../core/yukselen.dart';
import '../profil/domain/profil.dart';
import 'ilan_alarmi.dart';
import 'ilan_modeli.dart';
import 'yeni_ilan_takibi.dart';

/// İlan alarmı alt sayfası: kurulu alarmlar (silinebilir) ve yeni alarm formu (kelime, il, tür).
/// Alarm kurulunca bildirim izni istenir; izin yoksa alarm kurulmaz, çünkü bildirimsiz alarm işe yaramaz.
class IlanAlarmSayfasi extends StatefulWidget {
  const IlanAlarmSayfasi({
    super.key,
    required this.alarmlar,
    required this.ilanlar,
    required this.bugun,
    this.takip,
    this.statu,
    this.onceden = '',
  });

  final IlanAlarmlari alarmlar;

  /// Şu an akıştaki ilanlar: her alarmın yanında "N açık ilan uyuyor" göstermek için.
  final List<KamuIlani> ilanlar;
  final DateTime bugun;

  /// Bildirim tercihi ve izin; null ise (ör. web) alarm yalnızca ilan listesinde işaretlenir.
  final YeniIlanTakibi? takip;
  final Statu? statu;

  /// Arama kutusundan gelen kelime; forma yazılı başlar.
  final String onceden;

  @override
  State<IlanAlarmSayfasi> createState() => _IlanAlarmSayfasiState();
}

class _IlanAlarmSayfasiState extends State<IlanAlarmSayfasi> {
  late final _kelime = TextEditingController(text: widget.onceden);
  final _il = TextEditingController();
  IlanTuru? _tur;
  String? _mesaj;
  bool _mesgul = false;

  @override
  void initState() {
    super.initState();
    widget.alarmlar.addListener(_degisti);
  }

  void _degisti() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.alarmlar.removeListener(_degisti);
    _kelime.dispose();
    _il.dispose();
    super.dispose();
  }

  int _uyan(IlanAlarmi a) => widget.ilanlar.where((i) => i.acikMi(widget.bugun) && a.eslesir(i)).length;

  Future<void> _kur() async {
    if (_mesgul) return;
    final bos = _kelime.text.trim().isEmpty && _il.text.trim().isEmpty && _tur == null;
    if (bos) {
      setState(() => _mesaj = 'Bir kelime, il ya da tür seç.');
      return;
    }
    if (widget.alarmlar.dolu) {
      setState(() => _mesaj = 'En fazla ${IlanAlarmlari.enFazla} alarm kurabilirsin. Birini sil.');
      return;
    }
    setState(() {
      _mesgul = true;
      _mesaj = null;
    });
    // Bildirimler kapalıysa açılır (izin istenir); yalnızca alarma uyan ilanlar bildirilir.
    final takip = widget.takip;
    if (takip != null && takip.destekleniyor && !takip.tercih.acik) {
      final izin = await takip.ayarla(true, statu: widget.statu, yalnizcaAlarm: true);
      if (!izin) {
        if (mounted) {
          setState(() {
            _mesgul = false;
            _mesaj = 'Bildirim izni verilmedi. Alarm bildirim gönderemez; telefon ayarlarından bildirimlere izin ver.';
          });
        }
        return;
      }
    }
    final eklendi = await widget.alarmlar.ekle(kelime: _kelime.text, il: _il.text, tur: _tur);
    if (!mounted) return;
    setState(() {
      _mesgul = false;
      if (eklendi) {
        _kelime.clear();
        _il.clear();
        _tur = null;
        _mesaj = null;
      } else {
        _mesaj = 'Bu alarm zaten kurulu.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final liste = widget.alarmlar.liste;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.82),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.bellRing, size: 22, color: PusulaRenk.lacivert),
                const SizedBox(width: 10),
                Expanded(child: Text('İlan alarmları', style: PusulaYazi.baslik(22, aralik: -0.9))),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Yeni bir ilan alarmının hepsine uyduğunda haber veririm. Örnek: "zabıt katibi" ve "İstanbul".',
              style: PusulaYazi.metin(13, renk: PusulaRenk.soluk, agirlik: FontWeight.w500).copyWith(height: 1.4),
            ),
            const SizedBox(height: 14),
            if (liste.isEmpty)
              const BosDurum(
                gorselYuksekligi: 84,
                gorsel: BosGorselTuru.alarm,
                baslik: 'Henüz alarmın yok',
                alt: 'Aşağıdan kurduğunda yeni ilanlar için bildirim alırsın.',
              )
            else
              for (final a in liste) ...[
                _AlarmSatiri(alarm: a, uyan: _uyan(a), onSil: () => widget.alarmlar.sil(a.id)),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 10),
            Text('Yeni alarm', style: PusulaYazi.metin(14, agirlik: FontWeight.w800)),
            const SizedBox(height: 8),
            _Alan(denetci: _kelime, ipucu: 'Kelime (ör. zabıt katibi, hemşire)', ikon: LucideIcons.search),
            const SizedBox(height: 8),
            _Alan(denetci: _il, ipucu: 'İl veya kurum (isteğe bağlı)', ikon: LucideIcons.mapPin),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TurHapi(etiket: 'Her tür', secili: _tur == null, onTap: () => setState(() => _tur = null)),
                for (final t in IlanTuru.values.where((t) => t != IlanTuru.diger))
                  _TurHapi(etiket: t.etiket, secili: _tur == t, onTap: () => setState(() => _tur = t)),
              ],
            ),
            if (_mesaj != null) ...[
              const SizedBox(height: 10),
              Semantics(
                liveRegion: true,
                child: Text(_mesaj!, style: PusulaYazi.metin(13, renk: PusulaRenk.kirmizi, agirlik: FontWeight.w700)),
              ),
            ],
            const SizedBox(height: 14),
            BirincilDugme(
              metin: 'Alarm kur',
              ikon: LucideIcons.bellPlus,
              yukseklik: 54,
              onPressed: _mesgul ? null : _kur,
            ),
          ],
        ),
      ),
    );
  }
}

class _AlarmSatiri extends StatelessWidget {
  const _AlarmSatiri({required this.alarm, required this.uyan, required this.onSil});

  final IlanAlarmi alarm;
  final int uyan;
  final VoidCallback onSil;

  @override
  Widget build(BuildContext context) => Yukselen(
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: PusulaRenk.zemin,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PusulaRenk.cizgi, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: PusulaRenk.amber, borderRadius: BorderRadius.circular(13)),
            child: const Icon(LucideIcons.bell, size: 19, color: PusulaRenk.lacivert),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alarm.ad, style: PusulaYazi.metin(14, agirlik: FontWeight.w700)),
                Text(
                  uyan == 0 ? 'Şu an uyan açık ilan yok' : 'Şu an $uyan açık ilan uyuyor',
                  style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: '${alarm.ad} alarmını sil',
            excludeSemantics: true,
            onTap: onSil,
            child: IconButton(
              onPressed: onSil,
              icon: const Icon(LucideIcons.trash2, size: 20, color: PusulaRenk.kirmizi),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Alan extends StatelessWidget {
  const _Alan({required this.denetci, required this.ipucu, required this.ikon});

  final TextEditingController denetci;
  final String ipucu;
  final IconData ikon;

  @override
  Widget build(BuildContext context) => TextField(
    controller: denetci,
    textInputAction: TextInputAction.next,
    style: PusulaYazi.metin(15, agirlik: FontWeight.w500),
    decoration: InputDecoration(
      hintText: ipucu,
      hintStyle: PusulaYazi.metin(14, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
      prefixIcon: Icon(ikon, size: 19, color: PusulaRenk.lacivert),
      filled: true,
      fillColor: PusulaRenk.beyaz,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
      ),
    ),
  );
}

class _TurHapi extends StatelessWidget {
  const _TurHapi({required this.etiket, required this.secili, required this.onTap});

  final String etiket;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Basilabilir(
    child: Semantics(
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              etiket,
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
}
