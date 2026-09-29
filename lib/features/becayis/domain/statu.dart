/// Kamu çalışanının istihdam statüsü. Becayiş yalnızca 657 sayılı Kanun'a tabi
/// memurlar içindir (bkz. docs/becayis-spec.md §1.1).
enum Statu {
  memur657('657 sayılı Kanun memuru'),
  sozlesmeli('4/B sözleşmeli personel'),
  isci('İşçi'),
  akademik('Akademik personel'),
  diger('Diğer kamu çalışanı');

  const Statu(this.etiket);

  final String etiket;
}

class Profil {
  const Profil({required this.ad, required this.statu, this.adayMemur = false});

  final String ad;
  final Statu statu;

  /// Asaleti henüz onaylanmamış memur. İkincil kaynaklara göre becayiş yapamaz;
  /// birincil metinle teyit edilene kadar dışlanır.
  final bool adayMemur;

  bool get becayisYapabilir => statu == Statu.memur657 && !adayMemur;

  /// Becayiş kapalıysa kullanıcıya gösterilecek neden.
  String? get becayisKapaliNedeni {
    if (becayisYapabilir) return null;
    if (adayMemur) {
      return 'Becayiş için memurluğunun asaleti onaylanmış olmalı. Adaylık süren bitince burası açılır.';
    }
    return 'Becayiş, 657 sayılı Kanun md. 73 uyarınca yalnızca devlet memurları arasında yapılır. '
        '${statu.etiket} olarak bu özelliği kullanamazsın; maaş, haklar, ilanlar ve haberler açık.';
  }
}
