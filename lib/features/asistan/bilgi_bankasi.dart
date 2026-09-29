// Bu dosya tools tarafından üretilen kanun alıntılarını içerir; alıntılar resmî birleştirilmiş
// metinden (mevzuat.gov.tr, 657 sayılı Devlet Memurları Kanunu) aynen alınmıştır.
// Her alıntı ve özet, kanun metniyle karşılaştırılarak yazılmıştır; kanun değiştikçe güncellenmelidir.

import 'asistan_servisi.dart';

/// Asistanın cevap verebildiği bir konu: özet cevap + kanun maddesinden alıntılar.
class BilgiKonusu {
  const BilgiKonusu({
    required this.id,
    required this.baslik,
    required this.etiket,
    required this.ornekSoru,
    required this.anahtarlar,
    required this.cevap,
    required this.kaynaklar,
    this.uyari,
    this.surum,
    this.kapsamDisi = false,
  });

  final String id;
  final String baslik;

  /// Hızlı soru düğmesindeki kısa ad.
  final String etiket;

  /// Kullanıcıya önerilen örnek soru (hızlı soru düğmesi).
  final String ornekSoru;

  /// Eşleştirme için küçük harfli, Türkçe harfleri sadeleştirilmiş (ı→i, ş→s ...) anahtar kelimeler.
  final List<String> anahtarlar;
  final String cevap;
  final List<MevzuatKaynagi> kaynaklar;

  /// Cevabın altında gösterilen dikkat notu (kanunun dışında kalan konular).
  final String? uyari;

  /// Konunun kaynağı 657 sayılı Kanun değilse cevabın altında gösterilen kaynak/sürüm notu.
  final String? surum;

  /// Asistanın henüz cevaplayamadığı ama bilinen bir konu: dürüstçe "kapsam dışı" der.
  final bool kapsamDisi;
}

/// Doğrulanmış mevzuat bilgi bankası.
abstract final class BilgiBankasi {
  /// Metnin alındığı sürüm; ekranda cevabın altında gösterilir.
  static const surum =
      'Kaynak: mevzuat.gov.tr birleştirilmiş metin (31/7/2026 tarihinde yürürlüğe giren 7590 sayılı Kanun değişikliğine kadar işlenmiş)';

  /// 5510 sayılı Kanun konuları için sürüm notu.
  static const surum5510 =
      'Kaynak: mevzuat.gov.tr 5510 sayılı Kanun birleştirilmiş metni (24/7/2026 tarihli 7590 sayılı Kanun değişikliğine kadar işlenmiş)';

  static const konular = <BilgiKonusu>[
    BilgiKonusu(
      id: 'becayis',
      baslik: 'Becayiş (karşılıklı yer değiştirme)',
      etiket: 'Becayiş',
      ornekSoru: 'Becayiş şartları nedir?',
      anahtarlar: ['becayis', 'karsilikli yer', 'karsilikli tayin', 'yer degistirme karsilikli'],
      cevap:
          'Becayiş, aynı kurumda ve aynı sınıfta olup farklı yerlerde görev yapan iki memurun karşılıklı olarak yer değiştirmesidir. Talep, atamaya yetkili amirin uygun bulmasına bağlıdır; yani kurum reddedebilir.',
      kaynaklar: [
        MevzuatKaynagi(
          baslik: '657 sayılı Devlet Memurları Kanunu, md. 73 (Karşılıklı yer değiştirme)',
          alinti:
              'Aynı Kurumun başka başka yerlerde bulunan aynı sınıftaki memurları, karşılıklı olarak yer değiştirme suretiyle atanmalarını isteyebilirler. Bu isteğin yerine getirilmesi atamaya yetkili amirlerince uygun bulunmasına bağlıdır.',
        ),
      ],
    ),
    BilgiKonusu(
      id: 'yillik_izin',
      baslik: 'Yıllık izin',
      etiket: 'Yıllık izin',
      ornekSoru: 'Yıllık izin kaç gün?',
      anahtarlar: [
        'izin',
        'yillik izin',
        'yillik',
        'izin hakki',
        'izin haklari',
        'kullanilmayan izin',
        'kac gun izin',
        'izin suresi',
        'izin kullan',
        'izin devret',
        'izin dusme'
      ],
      cevap:
          'Devlet memurlarının yıllık izni, hizmeti 1 yıldan 10 yıla kadar (10 yıl dahil) olanlar için 20 gün, 10 yıldan fazla olanlar için 30 gündür. Zorunlu hallerde gidiş ve dönüş için en çok ikişer gün eklenebilir. Yıllık izin, amirin uygun bulacağı zamanlarda toptan ya da kısım kısım kullanılabilir; birbirini izleyen iki yılın izni bir arada verilebilir. Cari yıl ile bir önceki yıl dışında, önceki yıllara ait kullanılmayan izin hakları düşer. Öğretmenler yaz tatili ve dinlenme tatillerinde izinli sayıldığından ayrıca yıllık izin verilmez.',
      kaynaklar: [
        MevzuatKaynagi(
          baslik: '657 sayılı Devlet Memurları Kanunu, md. 102 (Yıllık izin)',
          alinti:
              'Devlet memurlarının yıllık izin süresi, hizmeti 1 yıldan on yıla kadar (On yıl dahil) olanlar için yirmi gün, hizmeti on yıldan fazla olanlar için 30 gündür. Zorunlu hallerde bu sürelere gidiş ve dönüş için en çok ikişer gün eklenebilir.',
        ),
        MevzuatKaynagi(
          baslik: '657 sayılı Devlet Memurları Kanunu, md. 103 (Yıllık izinlerin kullanılışı)',
          alinti:
              'Yıllık izinler, amirin uygun bulacağı zamanlarda, toptan veya ihtiyaca göre kısım kısım kullanılabilir. Birbirini izliyen iki yılın izni bir arada verilebilir. (Değişik cümle: 6/7/1995 – KHK-562/2 md.) Cari yıl ile bir önceki yıl hariç, önceki yıllara ait kullanılmayan izin hakları düşer.',
        ),
        MevzuatKaynagi(
          baslik: '657 sayılı Devlet Memurları Kanunu, md. 103 (Öğretmenler)',
          alinti:
              'Öğretmenler yaz tatili ile dinlenme tatillerinde izinli sayılırlar. Bunlara, hastalık ve diğer mazeret izinleri dışında, ayrıca yıllık izin verilmez.',
        ),
      ],
      uyari:
          'Hangi sürelerin "hizmet yılı"na sayıldığı ve izin kullanım usulü kanunun dışındaki düzenlemelere ve kurum uygulamasına bağlıdır; kesin bilgi için kurumunun personel birimine danış.',
    ),
    BilgiKonusu(
      id: 'mazeret_izni',
      baslik: 'Mazeret izinleri (analık, babalık, evlilik, ölüm, süt izni)',
      etiket: 'Mazeret izni',
      ornekSoru: 'Mazeret izni kaç gün?',
      anahtarlar: [
        'izin',
        'mazeret',
        'babalik',
        'analik',
        'dogum izni',
        'dogum',
        'dogur',
        'evlenme',
        'evlilik',
        'olum izni',
        'olum',
        'sut izni',
        'emzirme',
        'hamile',
        'gebelik'
      ],
      cevap:
          'Mazeret izinleri 104. maddede sayılır. Kadın memura doğumdan önce 8, doğumdan sonra 16 hafta olmak üzere toplam 24 hafta analık izni verilir; çoğul gebelikte doğum öncesi süreye 2 hafta eklenir (doğum sonrası süre, 1/5/2026\'da yürürlüğe giren 7578 sayılı Kanunla 8 haftadan 16 haftaya çıkarılmıştır). Eşi doğum yapan memura isteği üzerine 10 gün babalık izni verilir. Memurun veya çocuğunun evlenmesinde ya da eşinin, çocuğunun, kendisinin veya eşinin ana, baba ve kardeşinin ölümünde isteği üzerine 7 gün izin verilir. Bunların dışında mazeretler için amirin onayıyla bir yıl içinde 10 gün, zaruret hâlinde (öğretmenler hariç) 10 gün daha izin verilebilir; ikinci kez verilen izin yıllık izinden düşülür. Kadın memura doğum sonrası analık izninin bitiminden itibaren ilk altı ayda günde 3 saat, ikinci altı ayda günde 1,5 saat süt izni verilir.',
      kaynaklar: [
        MevzuatKaynagi(
          baslik: '657 sayılı Devlet Memurları Kanunu, md. 104/A (Analık izni)',
          alinti:
              'A) Kadın memura; doğumdan önce sekiz, doğumdan sonra onaltı hafta olmak üzere toplam yirmidört hafta süreyle analık izni verilir.',
        ),
        MevzuatKaynagi(
          baslik: '657 sayılı Devlet Memurları Kanunu, md. 104/B (Babalık, evlilik, ölüm)',
          alinti:
              'B) Memura, eşinin doğum yapması hâlinde, isteği üzerine on gün babalık izni; kendisinin veya çocuğunun evlenmesi ya da eşinin, çocuğunun, kendisinin veya eşinin ana, baba ve kardeşinin ölümü hâllerinde isteği üzerine yedi gün izin verilir.',
        ),
        MevzuatKaynagi(
          baslik: '657 sayılı Devlet Memurları Kanunu, md. 104/C (Diğer mazeretler)',
          alinti:
              'C) (A) ve (B) fıkralarında belirtilen hâller dışında, merkezde atamaya yetkili amir, ilde vali, ilçede kaymakam ve yurt dışında diplomatik misyon şefi tarafından, birim amirinin muvafakati ile bir yıl içinde toptan veya bölümler hâlinde, mazeretleri sebebiyle memurlara on gün izin verilebilir. Zaruret hâlinde öğretmenler hariç olmak üzere, aynı usûlle on gün daha mazeret izni verilebilir. Bu takdirde, ikinci kez verilen bu izin, yıllık izinden düşülür.',
        ),
        MevzuatKaynagi(
          baslik: '657 sayılı Devlet Memurları Kanunu, md. 104/D (Süt izni)',
          alinti:
              'D) Kadın memura, çocuğunu emzirmesi için doğum sonrası analık izni süresinin bitim tarihinden itibaren ilk altı ayda günde üç saat, ikinci altı ayda günde birbuçuk saat süt izni verilir. Süt izninin hangi saatler arasında ve günde kaç kez kullanılacağı hususunda, kadın memurun tercihi esastır.',
        ),
      ],
      uyari:
          'Evlat edinme, koruyucu aile, yarım çalışma ve engelli ya da süreğen hastalığı olan çocuk için ek haklar da 104. maddede düzenlenmiştir; kendi durumun için kurumunun personel birimine danış.',
    ),
    BilgiKonusu(
      id: 'hastalik_izni',
      baslik: 'Hastalık ve refakat izni (rapor)',
      etiket: 'Rapor / hastalık',
      ornekSoru: 'Rapor kullanımı ile ilgili haklarım neler?',
      anahtarlar: [
        'izin',
        'rapor',
        'hastalik',
        'refakat',
        'hasta izni',
        'saglik izni',
        'raporlu',
        'istirahat',
        'tedavi',
        'kanser'
      ],
      cevap:
          'Memura, aylık ve özlük hakları korunarak, rapordaki lüzum üzerine; kanser, verem, akıl hastalığı gibi uzun süreli tedavi gerektiren hastalıklarda 18 aya kadar, diğer hastalıklarda 12 aya kadar hastalık izni verilir. İzin sonunda hastalığın devam ettiği resmî sağlık kurulu raporuyla tespit edilirse izin aynı süreler kadar uzatılır; bu sürenin sonunda da iyileşemeyen memur hakkında emeklilik hükümleri uygulanır. Görevi sırasında veya görevinden dolayı kazaya ya da saldırıya uğrayan veya meslek hastalığına tutulan memur iyileşinceye kadar izinli sayılır. Bakmakla yükümlü olduğun ya da refakat etmezsen hayatı tehlikeye girecek ana, baba, eş, çocuk veya kardeşinden biri ağır bir kaza geçirir ya da tedavisi uzun süren bir hastalığa yakalanırsa, sağlık kurulu raporuyla belgelendirilmesi şartıyla 3 aya kadar refakat izni verilir; gerektiğinde bu süre bir katına kadar uzatılır.',
      kaynaklar: [
        MevzuatKaynagi(
          baslik: '657 sayılı Devlet Memurları Kanunu, md. 105 (Hastalık izni)',
          alinti:
              'Memura, aylık ve özlük hakları korunarak, verilecek raporda gösterilecek lüzum üzerine, kanser, verem ve akıl hastalığı gibi uzun süreli bir tedaviye ihtiyaç gösteren hastalığı hâlinde onsekiz aya kadar, diğer hastalık hâllerinde ise oniki aya kadar izin verilir.',
        ),
        MevzuatKaynagi(
          baslik: '657 sayılı Devlet Memurları Kanunu, md. 105 (Refakat izni)',
          alinti:
              'Ayrıca, memurun bakmakla yükümlü olduğu veya memur refakat etmediği takdirde hayatı tehlikeye girecek ana, baba, eş ve çocukları ile kardeşlerinden birinin ağır bir kaza geçirmesi veya tedavisi uzun süren bir hastalığının bulunması hâllerinde, bu hâllerin sağlık kurulu raporuyla belgelendirilmesi şartıyla, aylık ve özlük hakları korunarak, üç aya kadar izin verilir. Gerektiğinde bu süre bir katına kadar uzatılır.',
        ),
      ],
      uyari: 'Raporların hangi hekimlerce ve hangi sürelerle verileceği kanunda değil, ilgili yönetmelikte belirlenir.',
    ),
    BilgiKonusu(
      id: 'ayliksiz_izin',
      baslik: 'Aylıksız izin',
      etiket: 'Aylıksız izin',
      ornekSoru: 'Aylıksız izin ne zaman verilir?',
      anahtarlar: ['izin', 'ayliksiz', 'ucretsiz izin', 'ucretsiz'],
      cevap:
          'Aylıksız izin 108. maddede düzenlenir. Hastalık izninin bitiminden sonra sağlık kurulu raporuyla belgelendirilmesi şartıyla istek üzerine 18 aya kadar aylıksız izin verilebilir. Doğum yapan memura doğum sonrası analık izninin (ya da 104/F yarım çalışma izninin) bitiminden, eşi doğum yapan memura doğum tarihinden itibaren istekleri üzerine 24 aya kadar aylıksız izin verilir. Yıllık izinde esas alınan süreler itibarıyla 5 hizmet yılını tamamlamış memura, isteği hâlinde memuriyeti boyunca en fazla iki defada kullanılmak üzere toplam 1 yıla kadar aylıksız izin verilebilir. Aylıksız izin bitmeden mazeret ortadan kalkarsa 10 gün içinde göreve dönmek zorunludur; süre bitiminde ya da mazeretin kalkmasını izleyen 10 gün içinde göreve dönmeyen memuriyetten çekilmiş sayılır.',
      kaynaklar: [
        MevzuatKaynagi(
          baslik: '657 sayılı Devlet Memurları Kanunu, md. 108/A (Hastalık sonrası)',
          alinti:
              'A) Memura, 105 inci maddenin son fıkrası uyarınca verilen iznin bitiminden itibaren, sağlık kurulu raporuyla belgelendirilmesi şartıyla, istekleri üzerine onsekiz aya kadar aylıksız izin verilebilir.',
        ),
        MevzuatKaynagi(
          baslik: '657 sayılı Devlet Memurları Kanunu, md. 108/B (Doğum sonrası)',
          alinti:
              'B) Doğum yapan memura, 104 üncü madde uyarınca verilen doğum sonrası analık izni süresinin veya aynı maddenin (F) fıkrası uyarınca verilen izin süresinin bitiminden; eşi doğum yapan memura ise, doğum tarihinden itibaren istekleri üzerine yirmidört aya kadar aylıksız izin verilir.',
        ),
        MevzuatKaynagi(
          baslik: '657 sayılı Devlet Memurları Kanunu, md. 108/E (Beş hizmet yılından sonra)',
          alinti:
              'E) Memura, yıllık izinde esas alınan süreler itibarıyla beş hizmet yılını tamamlamış olması ve isteği hâlinde memuriyeti boyunca ve en fazla iki defada kullanılmak üzere, toplam bir yıla kadar aylıksız izin verilebilir.',
        ),
        MevzuatKaynagi(
          baslik: '657 sayılı Devlet Memurları Kanunu, md. 108/F (Göreve dönüş)',
          alinti:
              'F) Aylıksız izin süresinin bitiminden önce mazereti gerektiren sebebin ortadan kalkması hâlinde, on gün içinde göreve dönülmesi zorunludur. Aylıksız izin süresinin bitiminde veya mazeret sebebinin kalkmasını izleyen on gün içinde görevine dönmeyenler, memuriyetten çekilmiş sayılır.',
        ),
      ],
      uyari: 'Yurt dışı görev, eş durumu ve muvazzaf askerlik gibi diğer aylıksız izin hâlleri de 108. maddededir.',
    ),
    BilgiKonusu(
      id: 'kademe_derece',
      baslik: 'Kademe ilerlemesi ve derece yükselmesi',
      etiket: 'Kademe ve derece',
      ornekSoru: 'Kademe ve derece yükselmesi şartları nedir?',
      anahtarlar: [
        'kademe',
        'derece yukselme',
        'derece yukselmesi',
        'terfi',
        'yukselme',
        'ilerleme',
        'kademe ilerleme'
      ],
      cevap:
          'Kademe, derece içinde görevin önemi veya sorumluluğu artmadan memurun aylığındaki ilerlemedir. Kademe ilerlemesi için bulunduğun kademede en az bir yıl çalışmış olman ve derecende ilerleyebileceğin bir kademenin bulunması aranır; şartları taşıyanlar, hak kazandıkları tarihten geçerli olmak üzere başka bir işleme gerek kalmadan bir ileri kademeye ilerlemiş sayılır. Derece yükselmesi için üst derecelerde boş bir kadro bulunması, derecen içinde en az 3 yıl ve bu derecenin 3. kademesinde 1 yıl bulunmuş olman ve kadronun görevi için öngörülen nitelikleri taşıman gerekir; onay mercii atamaya yetkili amirdir.',
      kaynaklar: [
        MevzuatKaynagi(
          baslik: '657 sayılı Devlet Memurları Kanunu, md. 64 (Kademe ilerlemesi)',
          alinti:
              'Kademe; derece içinde, görevin önemi veya sorumluluğu artmadan, memurun aylığındaki ilerlemedir. Memurun kademe ilerlemesinin yapılabilmesi için bulunduğu kademede en az bir yıl çalışmış olması ve bulunduğu derecede ilerleyebileceği bir kademenin bulunması şartları aranır.',
        ),
        MevzuatKaynagi(
          baslik: '657 sayılı Devlet Memurları Kanunu, md. 64 (Hak kazanma)',
          alinti:
              'Bu maddede belirtilen şartları haiz her sınıf ve derecedeki memurlar, hak kazandıkları tarihten geçerli olmak üzere ve başkaca bir işleme gerek kalmaksızın bir ileri kademeye ilerlemiş sayılırlar.',
        ),
        MevzuatKaynagi(
          baslik: '657 sayılı Devlet Memurları Kanunu, md. 68/A (Derece yükselmesi)',
          alinti:
              'A) Derece yükselmesi yapılabilmesi için: a) Üst derecelerden boş bir kadronun bulunması, b) Derecesi içinde en az 3 yıl ve bu derecenin 3 üncü kademesinde 1 yıl bulunmuş, c) Kadronun tahsis edildiği görev için öngörülen nitelikleri elde etmiş, […] olması şarttır.',
        ),
      ],
      uyari:
          'Derece yükselmesinde kadro ve öğrenim durumuna bağlı ek koşullar ile bazı sınıflar için özel hükümler vardır (md. 68/B, 67).',
    ),
    BilgiKonusu(
      id: 'tayin',
      baslik: 'Tayin (yer değiştirme) ve nakil',
      etiket: 'Tayin',
      ornekSoru: 'Tayin şartları nelerdir?',
      anahtarlar: [
        'tayin',
        'nakil',
        'naklen',
        'yer degistirme',
        'atama',
        'es durumu',
        'aile birligi',
        'kurum ici',
        'kurumlar arasi'
      ],
      cevap:
          'Yer değiştirme suretiyle atamalar; hizmetin gereklerine ve iller arasındaki ekonomik, sosyal, kültürel ve ulaşım benzerliğine göre belirlenen bölgeler arasında adil ve dengeli bir sistem içinde yapılır (md. 72). Kurumlar, memurları kazanılmış hak aylık dereceleriyle kurum içindeki aynı ya da başka yerlerdeki kadrolara naklen atayabilir; memurlar istekleriyle kazanılmış hak derecelerinin en çok üç derece altındaki kadrolara atanabilir (md. 76). Memurların kurumlar arasında nakli, kurumların muvafakatiyle mümkündür (md. 74). Aynı kurumun aynı sınıftaki memurları karşılıklı yer değiştirmeyi (becayiş) isteyebilir (md. 73). Aile birliği için, memur olan eşin de isteği hâlinde atanabilmesi amacıyla kurumlar arasında koordinasyon sağlanır (md. 72). Hangi yerlere ne kadar hizmetle atanılabileceği gibi ayrıntılar yönetmelikle ve kurumun atama planıyla belirlenir.',
      kaynaklar: [
        MevzuatKaynagi(
          baslik: '657 sayılı Devlet Memurları Kanunu, md. 72 (Yer değiştirme)',
          alinti:
              'Kurumlarda yer değiştirme suretiyle atanmalar; hizmetlerin gereklerine, özelliklerine, Türkiyenin ekonomik, sosyal, kültürel ve ulaşım şartları yönünden benzerlik ve yakınlık gösteren iller gruplandırılarak tespit edilen bölgeler arasında adil ve dengeli bir sistem içinde yapılır.',
        ),
        MevzuatKaynagi(
          baslik: '657 sayılı Devlet Memurları Kanunu, md. 72 (Eş durumu)',
          alinti:
              'Yeniden veya yer değiştirme suretiyle yapılacak atamalarda; aile birimini muhafaza etmek bakımından kurumlar arasında gerekli koordinasyon sağlanarak memur olan diğer eşin de isteği halinde ataması, atamaya tabi tutulan memurun atandığı yere 74 ve 76 ncı maddelerde belirtilen esaslar çerçevesinde yapılır.',
        ),
        MevzuatKaynagi(
          baslik: '657 sayılı Devlet Memurları Kanunu, md. 74 (Kurumlar arası nakil)',
          alinti:
              'Memurların bu Kanuna tabi kurumlar arasında, kurumların muvafakatı ile kazanılmış hak dereceleri üzerinden veya 68 inci maddedeki esaslar çerçevesinde derece yükselmesi suretiyle, bulundukları sınıftan veya öğrenim durumları itibariyle girebilecekleri sınıftan, bir kadroya nakilleri mümkündür.',
        ),
        MevzuatKaynagi(
          baslik: '657 sayılı Devlet Memurları Kanunu, md. 76 (Kurum içi atama)',
          alinti:
              'Kurumlar, görev ve unvan eşitliği gözetmeden kazanılmış hak aylık dereceleriyle memurları bulundukları kadro derecelerine eşit veya 68 inci maddedeki esaslar çerçevesinde daha üst, kurum içinde aynı veya başka yerlerdeki diğer kadrolara naklen atayabilirler.',
        ),
        MevzuatKaynagi(
          baslik: '657 sayılı Devlet Memurları Kanunu, md. 76 (İstek üzerine atama)',
          alinti:
              'Memurlar istekleri ile, kurumlarında kazanılmış hak derecelerinin en çok üç derece altında aynı veya başka yerlerdeki kadrolara atanabilirler.',
        ),
      ],
      uyari:
          'Tayin talebinin kabulü kurumun atama yönetmeliğine, boş kadroya ve puan/hizmet süresi gibi kurum kriterlerine bağlıdır; kendi durumun için kurumunun personel birimine danış.',
    ),
    BilgiKonusu(
      id: 'disiplin',
      baslik: 'Disiplin cezaları ve savunma hakkı',
      etiket: 'Disiplin',
      ornekSoru: 'Disiplin cezaları nelerdir?',
      anahtarlar: [
        'disiplin',
        'ceza',
        'cezalar',
        'uyarma',
        'kinama',
        'ayliktan kesme',
        'kademe ilerlemesinin durdurulma',
        'durdurulma',
        'savunma',
        'memuriyetten cikar',
        'devlet memurlugundan cikar',
        'ihrac',
        'sorusturma',
        'ozluk dosya'
      ],
      cevap:
          'Disiplin cezaları 125. maddede sayılır: uyarma (memura görevinde ve davranışlarında daha dikkatli olması gerektiğinin yazıyla bildirilmesi), kınama (kusurlu olduğunun yazıyla bildirilmesi), aylıktan kesme (brüt aylıktan 1/30 ile 1/8 arasında kesinti), kademe ilerlemesinin durdurulması (bulunduğu kademede ilerlemenin fiilin ağırlığına göre 1-3 yıl durdurulması) ve Devlet memurluğundan çıkarma (bir daha atanmamak üzere memurluktan çıkarma). Savunması alınmadan hakkında disiplin cezası verilemez; savunma için verilen süre 7 günden az olamaz ve bu süre içinde savunma yapmayan savunma hakkından vazgeçmiş sayılır. Disiplin cezaları özlük dosyasına işlenir; memurluktan çıkarma dışındaki bir ceza alan memur, uyarma ve kınamada 5, diğer cezalarda 10 yıl sonra atamaya yetkili amire başvurarak cezanın özlük dosyasından silinmesini isteyebilir (davranışları isteği haklı kılıyorsa).',
      kaynaklar: [
        MevzuatKaynagi(
            baslik: '657 sayılı Devlet Memurları Kanunu, md. 125/A (Uyarma)',
            alinti:
                'A - Uyarma : Memura, görevinde ve davranışlarında daha dikkatli olması gerektiğinin yazı ile bildirilmesidir.'),
        MevzuatKaynagi(
            baslik: '657 sayılı Devlet Memurları Kanunu, md. 125/B (Kınama)',
            alinti: 'B - Kınama : Memura, görevinde ve davranışlarında kusurlu olduğunun yazı ile bildirilmesidir.'),
        MevzuatKaynagi(
            baslik: '657 sayılı Devlet Memurları Kanunu, md. 125/C (Aylıktan kesme)',
            alinti: 'C - Aylıktan kesme : Memurun, brüt aylığından 1/30 - 1/8 arasında kesinti yapılmasıdır.'),
        MevzuatKaynagi(
            baslik: '657 sayılı Devlet Memurları Kanunu, md. 125/D (Kademe ilerlemesinin durdurulması)',
            alinti:
                'D - Kademe ilerlemesinin durdurulması : Fiilin ağırlık derecesine göre memurun, bulunduğu kademede ilerlemesinin 1 - 3 yıl durdurulmasıdır.'),
        MevzuatKaynagi(
            baslik: '657 sayılı Devlet Memurları Kanunu, md. 125/E (Devlet memurluğundan çıkarma)',
            alinti:
                'E - Devlet memurluğundan çıkarma : Bir daha Devlet memurluğuna atanmamak üzere memurluktan çıkarmaktır.'),
        MevzuatKaynagi(
            baslik: '657 sayılı Devlet Memurları Kanunu, md. 130 (Savunma hakkı)',
            alinti:
                'Devlet memuru hakkında savunması alınmadan disiplin cezası verilemez. Soruşturmayı yapanın veya yetkili disiplin kurulunun 7 günden az olmamak üzere verdiği süre içinde veya belirtilen bir tarihte savunmasını yapmıyan memur, savunma hakkından vazgeçmiş sayılır.'),
        MevzuatKaynagi(
            baslik: '657 sayılı Devlet Memurları Kanunu, md. 133 (Özlük dosyasından silme)',
            alinti:
                'Disiplin cezaları memurun özlük dosyasına işlenir. Devlet memurluğundan çıkarma cezasından başka bir disiplin cezasına çarptırılmış olan memur uyarma ve kınama cezalarının uygulanmasından 5 sene, diğer cezaların uygulanmasından 10 sene sonra atamaya yetkili amire başvurarak, verilmiş olan cezalarının özlük dosyasından silinmesini isteyebilir.'),
      ],
      uyari:
          'Hangi fiile hangi cezanın verileceği 125. maddede ayrıntılı sayılır; itiraz yolları ve süreleri için kurumunun disiplin kuruluna ya da personel birimine danış.',
    ),
    BilgiKonusu(
      id: 'adaylik',
      baslik: 'Adaylık (aday memurluk)',
      etiket: 'Adaylık',
      ornekSoru: 'Adaylık süresi ne kadar?',
      anahtarlar: [
        'aday',
        'adaylik',
        'aday memur',
        'asli memur',
        'asalet',
        'staj',
        'temel egitim',
        'hazirlayici egitim'
      ],
      cevap:
          'Sınavı kazanıp Devlet memurluğuna girenler önce memur adayı olarak atanır. Adaylık süresi en az bir yıl, en çok iki yıldır ve bu süre içinde aday memurun başka kurumlara nakli yapılamaz (md. 54). Adaylar önce temel eğitime, sonra sınıflarına ilişkin hazırlayıcı eğitime ve staja tabi tutulur; Devlet memuru olarak atanabilmeleri için bunlarda başarılı olmaları şarttır (md. 55). Adaylık süresi içinde eğitim ya da stajın herhangi birinde başarısız olanların, birden fazla uyarma ve/veya kınama cezası alanların ile aylıktan kesme ya da kademe ilerlemesinin durdurulması cezası alanların ilişiği kesilir; ilişiği kesilenler (sağlık nedenleri hariç) üç yıl süreyle Devlet memurluğuna alınmaz (md. 56, Ocak 2026\'da değiştirildi). Eğitimde başarılı olan adaylar asli memurluğa atanır (md. 58).',
      kaynaklar: [
        MevzuatKaynagi(
            baslik: '657 sayılı Devlet Memurları Kanunu, md. 54 (Aday olarak atanma)',
            alinti:
                'Aday olarak atanmış Devlet memurunun adaylık süresi bir yıldan az iki yıldan çok olamaz ve bu süre içinde aday memurun başka kurumlara nakli yapılamaz.'),
        MevzuatKaynagi(
            baslik: '657 sayılı Devlet Memurları Kanunu, md. 55 (Adayların yetiştirilmesi)',
            alinti:
                'Aday olarak atanan memurların önce bütün memurların ortak vasıfları ile ilgili temel eğitime, bilahara sınıfları ile ilgili hazırlayıcı eğitime ve staja tabi tutulmaları ve Devlet memuru olarak atanabilmeleri için başarılı olmaları şarttır.'),
        MevzuatKaynagi(
            baslik: '657 sayılı Devlet Memurları Kanunu, md. 56 (Adaylık devresinde göreve son verme)',
            alinti:
                'Adaylık süresi içinde; temel ve hazırlayıcı eğitim ve staj devrelerinin herhangi birinde başarısız olanlar, birden fazla uyarma ve/veya kınama cezası almış olanlar ile aylıktan kesme ya da kademe ilerlemesinin durdurulması cezası almış olanların disiplin amirlerinin teklifi ve atamaya yetkili amirin onayı ile ilişikleri kesilir. İlişikleri kesilenler ilgili kurumlarca derhal Kamu Personel Bilgi Sisteminin bulunduğu kuruma bildirilir. Bu madde hükümlerine göre ilişikleri kesilenler (sağlık nedenleri hariç) üç yıl süre ile Devlet memurluğuna alınmazlar.'),
        MevzuatKaynagi(
            baslik: '657 sayılı Devlet Memurları Kanunu, md. 58 (Asli memurluğa atanma)',
            alinti:
                'Adaylık devresi içinde eğitimde başarılı olan adaylar disiplin amirlerinin teklifi ve atamaya yetkili amirin onayı ile onay tarihinden geçerli olmak üzere asli memurluğa atanırlar.'),
      ],
      uyari:
          'Eğitim süreleri, programları ve değerlendirme esasları yönetmelikle belirlenir (md. 55). Aynı kurum içinde karşılıklı yer değiştirme (becayiş) için 73. madde aday memurlardan ayrıca söz etmez; uygulamada yönetmelik ve kurum kuralları belirleyicidir.',
    ),
    BilgiKonusu(
      id: 'calisma_saati',
      baslik: 'Çalışma süresi ve saatleri',
      etiket: 'Çalışma saatleri',
      ornekSoru: 'Haftalık çalışma süresi kaç saat?',
      anahtarlar: [
        'calisma saat',
        'calisma suresi',
        'calisma gun',
        'mesai',
        'haftalik',
        '40 saat',
        'hafta tatili',
        'cumartesi',
        'pazar',
        'ogle',
        'giris cikis saat',
        'kacta'
      ],
      cevap:
          'Memurların haftalık çalışma süresi genel olarak 40 saattir; bu süre Cumartesi ve Pazar günleri tatil olmak üzere düzenlenir (md. 99). Ancak kanun, özel kanunlar, Cumhurbaşkanlığı kararnameleri veya bunlara dayanan yönetmeliklerle kurumların ve hizmetlerin özellikleri dikkate alınarak farklı çalışma süreleri belirlenebilir. Günlük çalışmanın başlama ve bitme saatleri ile öğle dinlenme süresi, bölgelerin ve hizmetin özelliklerine göre merkezde Cumhurbaşkanınca, illerde valiler tarafından belirlenir (md. 100).',
      kaynaklar: [
        MevzuatKaynagi(
            baslik: '657 sayılı Devlet Memurları Kanunu, md. 99 (Haftalık çalışma süresi)',
            alinti:
                'Memurların haftalık çalışma süresi genel olarak 40 saattir. Bu süre Cumartesi ve Pazar günleri tatil olmak üzere düzenlenir.'),
        MevzuatKaynagi(
            baslik: '657 sayılı Devlet Memurları Kanunu, md. 99 (Farklı çalışma süreleri)',
            alinti:
                'Ancak bu kanuna, özel kanunlara, Cumhurbaşkanlığı kararnamelerine veya bunlara dayanılarak çıkarılacak yönetmeliklerle, kurumların ve hizmetlerin özellikleri dikkate alınmak suretiyle farklı çalışma süreleri tespit olunabilir.'),
        MevzuatKaynagi(
            baslik: '657 sayılı Devlet Memurları Kanunu, md. 100 (Günlük çalışma saatleri)',
            alinti:
                'Günlük çalışmanın başlama ve bitme saatleri ile öğle dinlenme süresi, bölgelerin ve hizmetin özelliklerine göre merkezde Cumhurbaşkanınca, illerde valiler tarafından tesbit olunur.'),
      ],
      uyari:
          'Fazla çalışma, nöbet ve vardiya gibi konular ayrı maddelerde ve yönetmeliklerde düzenlenir; bu cevap yalnızca normal çalışma süresini kapsar.',
    ),
    BilgiKonusu(
      id: 'emeklilik',
      baslik: 'Emeklilik (yaşlılık aylığı)',
      etiket: 'Emeklilik',
      ornekSoru: 'Emeklilik için ne kadar süre gerekir?',
      anahtarlar: ['emekli', 'emeklilik', 'emekli aylig', 'yaslilik aylig', 'prim gun', 'yas sarti', 'sgk'],
      cevap:
          '5510 sayılı Kanuna göre, 2008\'de yürürlüğe giren düzenlemeden sonra ilk kez sigortalı olanlara kadın 58, erkek 60 yaşını doldurmak ve en az 9000 gün prim bildirilmiş olmak şartıyla yaşlılık aylığı bağlanır (yaş şartı 2036\'dan itibaren kademeli olarak artar). 4/1-(c) kapsamındaki sigortalılar (memurlar gibi) için ayrıca istek üzerine yetkili makamdan emekliye sevk onayı alınması ve ilişiğin kesilmesi gerekir.',
      kaynaklar: [
        MevzuatKaynagi(
          baslik: '5510 sayılı Kanun, md. 28 (Yaşlılık sigortasından sağlanan haklar ve yararlanma şartları)',
          alinti:
              'İlk defa bu Kanuna göre sigortalı sayılanlara; a) Kadın ise 58, erkek ise 60 yaşını doldurmuş olmaları ve en az 9000 gün malûllük, yaşlılık ve ölüm sigortaları primi bildirilmiş olması şartıyla yaşlılık aylığı bağlanır. Ancak, 4 üncü maddenin birinci fıkrasının (a) bendi kapsamında sigortalı sayılanlar için prim gün sayısı şartı 7200 gün olarak uygulanır. b) (a) bendinde belirtilen yaş şartı; 1) 1/1/2036 ilâ 31/12/2037 tarihleri arasında kadın için 59, erkek için 61, 2) 1/1/2038 ilâ 31/12/2039 tarihleri arasında kadın için 60, erkek için 62, 3) 1/1/2040 ilâ 31/12/2041 tarihleri arasında kadın için 61, erkek için 63, 4) 1/1/2042 ilâ 31/12/2043 tarihleri arasında kadın için 62, erkek için 64, 5) 1/1/2044 ilâ 31/12/2045 tarihleri arasında kadın için 63, erkek için 65, 6) 1/1/2046 ilâ 31/12/2047 tarihleri arasında kadın için 64, erkek için 65, 7) 1/1/2048 tarihinden itibaren ise kadın ve erkek için 65, olarak uygulanır.',
        ),
        MevzuatKaynagi(
          baslik: '5510 sayılı Kanun, md. 28 (emekliye sevk onayı)',
          alinti:
              '4 üncü maddenin birinci fıkrasının (c) bendinde belirtilen sigortalıların ise istekleri üzerine yetkili makamdan emekliye sevk onayı alındıktan sonra ilişiklerinin kesilmesi şarttır.',
        ),
        MevzuatKaynagi(
          baslik: '5510 sayılı Kanun, geçici md. 4 (eski 5434 sayılı Kanun kapsamındakiler)',
          alinti:
              'Bu madde kapsamına girenlerin aylıklarının bağlanması, artırılması, azaltılması, kesilmesi, yeniden bağlanması, toptan ödemeleri, ilgi devamı, ihya ve borçlanmaları, diğer ödemeler ve yardımlar ile emeklilik ikramiyeleri hakkında bu Kanunla yürürlükten kaldırılan hükümleri de dahil 5434 sayılı Kanun hükümlerine göre işlem yapılır',
        ),
      ],
      uyari:
          '2008 öncesinde memuriyete başlayanlar (eski 5434 sayılı Kanuna tabi olanlar) için şartlar farklıdır ve geçici madde 4 uyarınca mülga 5434 sayılı Kanun hükümlerine göre belirlenir. Bu kanunun metni asistanda yok; kendi durumun için SGK\'dan veya e-Devlet\'teki hizmet dökümünden bilgi al.',
      surum: BilgiBankasi.surum5510,
    ),
  ];
}
