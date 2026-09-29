import 'package:flutter/material.dart';

import '../../../core/bilesenler.dart';
import '../../../core/sayi_adimi.dart';
import '../../../core/yukselen.dart';
import '../domain/izin_hesaplayici.dart';
import 'arac_parcalari.dart';

/// Yıllık izin hakkı: hizmet yılına göre süre (657 md. 102), geçen yıldan devreden ve kalan gün.
class IzinSayfasi extends StatefulWidget {
  const IzinSayfasi({super.key, this.baslangicHizmetYili = 5});

  final int baslangicHizmetYili;

  @override
  State<IzinSayfasi> createState() => _IzinSayfasiState();
}

class _IzinSayfasiState extends State<IzinSayfasi> {
  late int _hizmet = widget.baslangicHizmetYili.clamp(0, 40);
  int _gecen = 0;
  int _kullanilan = 0;

  @override
  Widget build(BuildContext context) {
    final s = IzinHesaplayici.hesapla(hizmetYili: _hizmet, gecenYildanKalan: _gecen, buYilKullanilan: _kullanilan);
    final kalan = s.kalan;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
          children: [
            const Yukselen(child: GeriBaslik(ustYazi: 'Araçlar', baslik: 'İzin hakkı', sag: SizedBox.shrink())),
            const SizedBox(height: 16),
            Yukselen(
              gecikme: const Duration(milliseconds: 80),
              child: s.hizmetYiliYetersiz
                  ? const SonucKarti(
                      etiket: 'Yıllık izin hakkın',
                      deger: '—',
                      altYazi: 'Kanundaki süreler hizmeti 1 yıldan fazla olanlar için',
                      anlamsalEtiket: 'Hizmet süresi 1 yıldan az; kanundaki yıllık izin süreleri uygulanmaz.',
                    )
                  : SonucKarti(
                      etiket: 'Kullanabileceğin kalan izin',
                      deger: '$kalan gün',
                      altYazi: kalan < 0 ? 'Hakkından ${-kalan} gün fazla kullanmış görünüyorsun' : null,
                      anlamsalEtiket: 'Kalan yıllık izin $kalan gün',
                      satirlar: [
                        ('Bu yılın izni', '${s.yillikHak} gün'),
                        ('Geçen yıldan devreden', '${s.devreden} gün'),
                        ('Bu yıl kullanılan', '${s.buYilKullanilan} gün'),
                      ],
                    ),
            ),
            const SizedBox(height: 14),
            SayiAdimi(
              etiket: 'Hizmet yılın',
              alt: 'İzinde sayılan tamamlanmış hizmet yılı',
              deger: '$_hizmet',
              eksiEtiketi: 'Hizmet yılını azalt',
              artiEtiketi: 'Hizmet yılını artır',
              onEksi: _hizmet > 0 ? () => setState(() => _hizmet--) : null,
              onArti: _hizmet < 40 ? () => setState(() => _hizmet++) : null,
            ),
            const SizedBox(height: 12),
            SayiAdimi(
              etiket: 'Geçen yıldan kalan',
              alt: 'Kullanmadığın gün (en çok geçen yıl hakkın kadar)',
              deger: '$_gecen',
              eksiEtiketi: 'Geçen yıldan kalanı azalt',
              artiEtiketi: 'Geçen yıldan kalanı artır',
              onEksi: _gecen > 0 ? () => setState(() => _gecen--) : null,
              onArti: _gecen < IzinHesaplayici.enFazlaGun ? () => setState(() => _gecen++) : null,
            ),
            const SizedBox(height: 12),
            SayiAdimi(
              etiket: 'Bu yıl kullandığın',
              alt: 'Gün',
              deger: '$_kullanilan',
              eksiEtiketi: 'Kullanılanı azalt',
              artiEtiketi: 'Kullanılanı artır',
              onEksi: _kullanilan > 0 ? () => setState(() => _kullanilan--) : null,
              onArti: _kullanilan < 60 ? () => setState(() => _kullanilan++) : null,
            ),
            const SizedBox(height: 18),
            const NotSatiri(
              '657 sayılı Kanun md. 102: hizmeti 1 yıldan 10 yıla kadar (10 yıl dahil) olanlara 20 gün, 10 yıldan '
              'fazla olanlara 30 gün; zorunlu hâllerde gidiş ve dönüş için en çok ikişer gün eklenebilir. '
              'Md. 103: cari yıl ile bir önceki yıl hariç, önceki yıllara ait kullanılmayan izin hakları düşer. '
              'Hangi sürelerin hizmet yılına sayıldığı kurum uygulamasına bağlıdır; kesin sonuç için personel biriminden teyit et.',
            ),
          ],
        ),
      ),
    );
  }
}
