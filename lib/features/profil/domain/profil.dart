import '../../../core/metin.dart';
import '../../maas/domain/memur_maas_hesaplayici.dart';

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

  /// Maaşı brüt ücretten net'e hesaplanabilen statüler: 5510 md. 4/1-(a) kapsamındaki sözleşmeli ve işçi.
  bool get brutUcretliMi => this == sozlesmeli || this == isci;
}

/// Kullanıcının profili. Tüm özellikler (maaş, becayiş, ilan uyumu) buradan beslenir.
/// Veriler KVKK kapsamındadır: yalnızca gerekli alanlar, kullanıcı istediğinde silinebilir.
class Profil {
  const Profil({
    required this.ad,
    required this.statu,
    this.adayMemur = false,
    this.kurumAdi = '',
    this.sinif = '',
    this.unvan = '',
    this.il = '',
    this.sicilNo = '',
    this.kurumsalEposta = '',
    this.maas,
    this.kademeTarihi,
    this.brutUcret,
  });

  final String ad;
  final Statu statu;

  /// Asaleti henüz onaylanmamış memur. İkincil kaynaklara göre becayiş yapamaz;
  /// birincil metinle teyit edilene kadar dışlanır.
  final bool adayMemur;

  final String kurumAdi;

  /// Hizmet sınıfı (657 md. 36), ör. "Sağlık Hizmetleri".
  final String sinif;
  final String unvan;

  /// Çalıştığı il.
  final String il;

  /// Dilekçede kullanılır; yalnızca cihazda saklanır.
  final String sicilNo;

  /// Mavi tik doğrulaması için .gov.tr / .edu.tr adresi.
  final String kurumsalEposta;

  /// Bordrodan bilinen maaş girdileri; maaş hesabı ve ana sayfa bunu kullanır.
  final MaasGirdisi? maas;

  /// Bulunduğu kademeye geldiği tarih (kademe ilerlemesi sayacı için; yalnızca memurlar).
  final DateTime? kademeTarihi;

  /// Aylık brüt ücret (TL); yalnızca sözleşmeli ve işçi için (bordrodan).
  final double? brutUcret;

  /// Kurum adından eşleştirmede kullanılan kararlı kimlik.
  String get kurumKimligi => kurumKimligiUret(kurumAdi);

  bool get becayisYapabilir => statu == Statu.memur657 && !adayMemur;

  /// Becayiş ilanı için profilde eksik olan alanların adları.
  List<String> get eksikBecayisAlanlari => [
    if (kurumAdi.trim().isEmpty) 'Kurum',
    if (sinif.trim().isEmpty) 'Hizmet sınıfı',
    if (unvan.trim().isEmpty) 'Unvan',
    if (il.trim().isEmpty) 'Çalıştığın il',
  ];

  /// Becayiş kapalıysa kullanıcıya gösterilecek neden.
  String? get becayisKapaliNedeni {
    if (becayisYapabilir) return null;
    if (adayMemur) {
      return 'Becayiş için memurluğunun asaleti onaylanmış olmalı: kanunun 73. maddesi aday memurları ayrıca anmıyor, '
          'ancak yer değiştirme yönetmeliği ve kurum uygulaması aday memurlara becayişi kapatıyor. Adaylık süren bitince burası açılır.';
    }
    return 'Becayiş, 657 sayılı Kanun md. 73 uyarınca yalnızca devlet memurları arasında yapılır. '
        '${statu.etiket} olarak bu özelliği kullanamazsın; maaş, haklar, ilanlar ve haberler açık.';
  }

  Profil kopya({
    String? ad,
    Statu? statu,
    bool? adayMemur,
    String? kurumAdi,
    String? sinif,
    String? unvan,
    String? il,
    String? sicilNo,
    String? kurumsalEposta,
    MaasGirdisi? maas,
    DateTime? kademeTarihi,
    bool kademeTarihiniTemizle = false,
    double? brutUcret,
    bool brutUcretiTemizle = false,
  }) => Profil(
    ad: ad ?? this.ad,
    statu: statu ?? this.statu,
    adayMemur: adayMemur ?? this.adayMemur,
    kurumAdi: kurumAdi ?? this.kurumAdi,
    sinif: sinif ?? this.sinif,
    unvan: unvan ?? this.unvan,
    il: il ?? this.il,
    sicilNo: sicilNo ?? this.sicilNo,
    kurumsalEposta: kurumsalEposta ?? this.kurumsalEposta,
    maas: maas ?? this.maas,
    kademeTarihi: kademeTarihiniTemizle ? null : (kademeTarihi ?? this.kademeTarihi),
    brutUcret: brutUcretiTemizle ? null : (brutUcret ?? this.brutUcret),
  );

  Map<String, Object?> toJson() => {
    'ad': ad,
    'statu': statu.name,
    'adayMemur': adayMemur,
    'kurumAdi': kurumAdi,
    'sinif': sinif,
    'unvan': unvan,
    'il': il,
    'sicilNo': sicilNo,
    'kurumsalEposta': kurumsalEposta,
    'maas': maas?.toJson(),
    'kademeTarihi': kademeTarihi == null ? null : _gunMetni(kademeTarihi!),
    'brutUcret': brutUcret,
  };

  static String _gunMetni(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  /// Bozuk veya eski kayıtta (yanlış tipler dahil) güvenli varsayılanlara döner;
  /// asla hata fırlatmaz.
  factory Profil.fromJson(Map<String, Object?> j) {
    String metin(String k) => j[k] is String ? j[k]! as String : '';
    final statuAdi = j['statu'];
    final maas = j['maas'];
    return Profil(
      ad: metin('ad'),
      statu: Statu.values.firstWhere((s) => s.name == statuAdi, orElse: () => Statu.diger),
      adayMemur: j['adayMemur'] == true,
      kurumAdi: metin('kurumAdi'),
      sinif: metin('sinif'),
      unvan: metin('unvan'),
      il: metin('il'),
      sicilNo: metin('sicilNo'),
      kurumsalEposta: metin('kurumsalEposta'),
      maas: maas is Map<String, Object?> ? MaasGirdisi.fromJson(maas) : null,
      kademeTarihi: _tarih(j['kademeTarihi']),
      brutUcret: j['brutUcret'] is num ? (j['brutUcret']! as num).toDouble().clamp(0.0, 10000000.0) : null,
    );
  }

  /// "2025-03-14" biçimindeki metni tarihe çevirir; bozuk/olanaksız değerde null döner.
  static DateTime? _tarih(Object? v) {
    if (v is! String) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(v);
    if (m == null) return null;
    final y = int.parse(m.group(1)!), a = int.parse(m.group(2)!), g = int.parse(m.group(3)!);
    final t = DateTime(y, a, g);
    // 31 Şubat gibi taşan tarihleri reddet.
    return t.year == y && t.month == a && t.day == g && y >= 1950 && y <= 2100 ? t : null;
  }

  @override
  bool operator ==(Object other) =>
      other is Profil &&
      other.ad == ad &&
      other.statu == statu &&
      other.adayMemur == adayMemur &&
      other.kurumAdi == kurumAdi &&
      other.sinif == sinif &&
      other.unvan == unvan &&
      other.il == il &&
      other.sicilNo == sicilNo &&
      other.kurumsalEposta == kurumsalEposta &&
      other.maas == maas &&
      other.kademeTarihi == kademeTarihi &&
      other.brutUcret == brutUcret;

  @override
  int get hashCode => Object.hash(
    ad,
    statu,
    adayMemur,
    kurumAdi,
    sinif,
    unvan,
    il,
    sicilNo,
    kurumsalEposta,
    maas,
    kademeTarihi,
    brutUcret,
  );
}

/// "Sağlık Bakanlığı" → "saglik-bakanligi" (Türkçe harfler sadeleştirilir).
String kurumKimligiUret(String ad) {
  const harita = {'ı': 'i', 'ğ': 'g', 'ü': 'u', 'ş': 's', 'ö': 'o', 'ç': 'c'};
  final b = StringBuffer();
  for (final r in normalize(ad).runes) {
    final c = String.fromCharCode(r);
    b.write(harita[c] ?? c);
  }
  return b.toString().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
}

/// Profil ekranındaki seçenekler.
abstract final class ProfilSecenekleri {
  /// 657 sayılı Kanun md. 36 hizmet sınıfları. Tam liste yayın öncesi kanun
  /// metniyle teyit edilmeli.
  static const siniflar = [
    'Genel İdare Hizmetleri',
    'Teknik Hizmetler',
    'Sağlık Hizmetleri',
    'Eğitim ve Öğretim Hizmetleri',
    'Avukatlık Hizmetleri',
    'Din Hizmetleri',
    'Emniyet Hizmetleri',
    'Mülki İdare Amirliği Hizmetleri',
    'Yardımcı Hizmetler',
  ];

  /// Sık kullanılan kurumlar. Gerçek sürümde DETSİS kurum listesinden gelir;
  /// kurumun listede olmaması durumunda kullanıcı adı elle yazabilir.
  static const kurumlar = [
    'Sağlık Bakanlığı',
    'Milli Eğitim Bakanlığı',
    'Adalet Bakanlığı',
    'İçişleri Bakanlığı',
    'Aile ve Sosyal Hizmetler Bakanlığı',
    'Tarım ve Orman Bakanlığı',
    'Çevre, Şehircilik ve İklim Değişikliği Bakanlığı',
    'Ulaştırma ve Altyapı Bakanlığı',
    'Hazine ve Maliye Bakanlığı',
    'Gençlik ve Spor Bakanlığı',
    'Kültür ve Turizm Bakanlığı',
    'Enerji ve Tabii Kaynaklar Bakanlığı',
    'Sanayi ve Teknoloji Bakanlığı',
    'Ticaret Bakanlığı',
    'Dışişleri Bakanlığı',
    'Çalışma ve Sosyal Güvenlik Bakanlığı',
    'Emniyet Genel Müdürlüğü',
    'Sosyal Güvenlik Kurumu',
    'Gelir İdaresi Başkanlığı',
    'Diyanet İşleri Başkanlığı',
    'Karayolları Genel Müdürlüğü',
    'Orman Genel Müdürlüğü',
    'Devlet Su İşleri Genel Müdürlüğü',
    'Üniversite Rektörlüğü',
    'Belediye',
    'İl Özel İdaresi',
  ];

  static const iller = [
    'Adana',
    'Adıyaman',
    'Afyonkarahisar',
    'Ağrı',
    'Aksaray',
    'Amasya',
    'Ankara',
    'Antalya',
    'Ardahan',
    'Artvin',
    'Aydın',
    'Balıkesir',
    'Bartın',
    'Batman',
    'Bayburt',
    'Bilecik',
    'Bingöl',
    'Bitlis',
    'Bolu',
    'Burdur',
    'Bursa',
    'Çanakkale',
    'Çankırı',
    'Çorum',
    'Denizli',
    'Diyarbakır',
    'Düzce',
    'Edirne',
    'Elazığ',
    'Erzincan',
    'Erzurum',
    'Eskişehir',
    'Gaziantep',
    'Giresun',
    'Gümüşhane',
    'Hakkari',
    'Hatay',
    'Iğdır',
    'Isparta',
    'İstanbul',
    'İzmir',
    'Kahramanmaraş',
    'Karabük',
    'Karaman',
    'Kars',
    'Kastamonu',
    'Kayseri',
    'Kırıkkale',
    'Kırklareli',
    'Kırşehir',
    'Kilis',
    'Kocaeli',
    'Konya',
    'Kütahya',
    'Malatya',
    'Manisa',
    'Mardin',
    'Mersin',
    'Muğla',
    'Muş',
    'Nevşehir',
    'Niğde',
    'Ordu',
    'Osmaniye',
    'Rize',
    'Sakarya',
    'Samsun',
    'Siirt',
    'Sinop',
    'Sivas',
    'Şanlıurfa',
    'Şırnak',
    'Tekirdağ',
    'Tokat',
    'Trabzon',
    'Tunceli',
    'Uşak',
    'Van',
    'Yalova',
    'Yozgat',
    'Zonguldak',
  ];
}
