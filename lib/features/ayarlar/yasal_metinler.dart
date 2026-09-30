/// Yasal metinler (aydınlatma metni, kullanım koşulları). Veri sorumlusu bilgileri
/// https://www.ayasyazilim.com.tr adresindeki KVKK sayfalarından alınmıştır. Uygulamanın veri akışı
/// değiştiğinde (sunucu, ödeme, analitik) bu metinler de güncellenmelidir.
class YasalBolum {
  const YasalBolum(this.baslik, this.metin);

  final String baslik;
  final String metin;
}

class YasalMetin {
  const YasalMetin({required this.baslik, required this.bolumler, required this.guncelleme});

  final String baslik;
  final List<YasalBolum> bolumler;

  /// Son güncelleme tarihi (gösterilir).
  final String guncelleme;

  /// Doldurulmamış köşeli parantezli yer tutucuların sayısı (yayında sıfır olmalıdır).
  int get doldurulacakYerSayisi => RegExp(r'\[[^\]]+\]').allMatches(bolumler.map((b) => b.metin).join(' ')).length;
}

abstract final class YasalMetinler {
  /// Yalnızca yer tutucu içeren bir metin gösterilirse ([YasalSayfasi.taslak]) kullanılan uyarı.
  static const taslakUyarisi =
      'TASLAK — Bu metin hukuk onayından geçmemiştir ve köşeli parantezli yerler doldurulmamıştır. '
      'Uygulama yayınlanmadan önce bir avukat tarafından gözden geçirilmelidir.';

  /// Veri sorumlusu / hizmet sağlayıcı bilgisi (iki metinde ortak).
  static const sirketBilgisi =
      'Oğuzhan Terzioğlu (Ayas Yazılım), Ünye Vergi Dairesi, VKN 8400627830; '
      'Saraçlı Mah. Akkuş-Niksar Cad. 8. Sk. Kapı No:28 Daire No:6 Ünye/Ordu.';

  static const _iletisim =
      'E-posta: bilgi@ayasyazilim.com.tr (konu: "KVKK İlgili Kişi Başvurusu"); '
      'KEP: oguzhan.terzioglu.0@hs01.kep.tr; ya da yukarıdaki adrese yazılı olarak.';

  static const aydinlatma = YasalMetin(
    baslik: 'Aydınlatma Metni (KVKK md. 10)',
    guncelleme: 'Yürürlük tarihi: 29 Eylül 2026',
    bolumler: [
      YasalBolum(
        'Veri sorumlusu',
        '6698 sayılı Kişisel Verilerin Korunması Kanunu kapsamında veri sorumlusu: $sirketBilgisi '
            'İletişim: bilgi@ayasyazilim.com.tr, destek@ayasyazilim.com.tr. Bu metin, Kamu Pusulası uygulamasının '
            'kullanımı sırasında işlenen kişisel verilere ilişkindir.',
      ),
      YasalBolum(
        'İşlenen veriler',
        'Kamu Pusulası\'nı kullanırken şu bilgiler işlenebilir: hesap bilgileri (e-posta adresi, giriş yöntemi; şifren '
            'düz metin olarak değil, tuzlu özet olarak saklanır); profil bilgileri (ad, statü, kurum, hizmet sınıfı, unvan, il); '
            'isteğe bağlı bilgiler (sicil numarası, kurumsal e-posta, derece/kademe/hizmet yılı ve bordro kalemleri, kademeye geliş tarihi, profil fotoğrafı). '
            'Uygulama sağlık, sendika üyeliği gibi özel nitelikli kişisel verileri talep etmez ve bunları girmemeni öneririz. '
            'Kamu görevlisi olduğunu gösteren bilgiler dikkatle korunur.',
      ),
      YasalBolum(
        'İşleme amaçları',
        'Maaş ve izin hesapları, becayiş eşleştirme ve dilekçe hazırlama, size uygun ilan ve haberlerin gösterilmesi, '
            'kademe hatırlatıcıları, hesabınızın yönetimi, uygulamanın güvenliği ve hukuki yükümlülüklerin yerine getirilmesi.',
      ),
      YasalBolum(
        'Verilerin saklandığı yer ve aktarım',
        'Bu sürümde profil, hesap ve fotoğraf bilgileriniz yalnızca cihazınızda saklanır; sunucuya gönderilmez, yurt '
            'dışına aktarılmaz ve üçüncü kişilerle paylaşılmaz. Kademe hatırlatıcıları da yalnızca cihazınızda kurulur. '
            'İlan ve haber akışı, herkese açık bir GitHub deposundan (raw.githubusercontent.com) indirilir; bu isteğe '
            'kişisel bilginiz eklenmez, ancak her internet isteğinde olduğu gibi IP adresiniz GitHub tarafından görülür. '
            'Sunucu tabanlı özellikler (hesap eşitleme, becayiş eşleştirme, ödeme doğrulama) eklendiğinde bu metin '
            'güncellenecek ve önceden uygulama içinde duyurulacaktır; verileriniz ancak burada belirtilen amaçlarla, hukuka uygun '
            'sebeplerle ve gerektiğinde açık rızanızla aktarılacaktır. Kanunen yetkili kurum ve kuruluşlara yasal '
            'yükümlülük gereği aktarım yapılabilir.',
      ),
      YasalBolum(
        'Hukuki sebep ve toplama yöntemi',
        'Veriler, uygulamaya sizin girdiğiniz bilgilerle elektronik ortamda toplanır. Hukuki sebepler (KVKK md. 5/2): '
            'hesap ve profil bilgileri için sözleşmenin kurulması ve ifası (uygulama hizmetinin sunulması); güvenlik ve '
            'kötüye kullanımın önlenmesi için veri sorumlusunun meşru menfaati; kanundan doğan yükümlülükler. Cihaz dışına '
            'aktarım ya da pazarlama iletisi gibi işlemler yalnızca açık rızanızla yapılır.',
      ),
      YasalBolum(
        'Saklama süresi',
        'Cihazınızdaki veriler siz silene ya da uygulamayı kaldırana kadar saklanır. Uygulama içinden profil bilgilerinizi, '
            'fotoğrafınızı ve hesabınızı istediğiniz zaman silebilirsiniz. İleride sunucuda tutulacak veriler, işleme amacı ve '
            'mevzuattaki saklama yükümlülükleri sona erene kadar saklanır, ardından silinir, yok edilir veya anonim hale getirilir.',
      ),
      YasalBolum(
        'Haklarınız (KVKK md. 11)',
        'Verilerinizin işlenip işlenmediğini öğrenme, bilgi talep etme, amacına uygun kullanılıp kullanılmadığını öğrenme, '
            'aktarıldığı kişileri bilme, düzeltme ve silme/yok etme talep etme, itiraz etme ve zararın giderilmesini isteme '
            'haklarına sahipsiniz. Uygulama içinden verilerinizi kopyalayabilir, profil bilgilerinizi ya da hesabınızı silebilirsiniz. '
            'Başvuru: $_iletisim Başvurular talebin niteliğine göre en kısa sürede ve en geç otuz gün içinde sonuçlandırılır.',
      ),
    ],
  );

  static const kosullar = YasalMetin(
    baslik: 'Kullanım Koşulları',
    guncelleme: 'Yürürlük tarihi: 29 Eylül 2026',
    bolumler: [
      YasalBolum(
        'Bağımsız uygulama',
        'Kamu Pusulası bağımsız bir uygulamadır; hiçbir kamu kurumunun, sendikanın ya da resmî kuruluşun uygulaması '
            'değildir ve onlarla bağlantılı değildir. Kurumların adları yalnızca bilgilendirme amacıyla anılır.',
      ),
      YasalBolum(
        'Hizmetin tanımı',
        'Kamu Pusulası, kamu çalışanlarına maaş ve izin hesaplama araçları, mevzuat bilgisi, becayiş eşleştirme, ilan ve haber '
            'derleme hizmeti sunar. Hizmeti sunan: $sirketBilgisi Destek: destek@ayasyazilim.com.tr.',
      ),
      YasalBolum(
        'Bilgilendirme amaçlıdır',
        'Uygulamadaki hesaplamalar tahminidir; kesin tutar ve haklar için bordronuz, kurumunuzun personel birimi ve ilgili '
            'mevzuat esas alınmalıdır. "Hakkım ne?" bölümü kanun metinlerinden alıntı yapar, hukuki tavsiye vermez. '
            'İlan ve haberler üçüncü kaynaklardan derlenir; başvuru ve işlem yapmadan önce kaynağı doğrulamanız gerekir.',
      ),
      YasalBolum(
        'Becayiş ve ödeme',
        'Becayiş eşleşmesi, kurumun atamaya yetkili amirinin uygun bulmasına bağlıdır (657 sayılı Kanun md. 73); '
            'becayiş eşleştirmesi açıldığında uygulama eşleşme ve iletişim kolaylığı sağlar, atamayı garanti etmez. Ücretli özellikler sunulduğunda mağaza '
            '(App Store / Google Play) üzerinden satın alınır; ücret satın alma öncesinde mağazada gösterilir. Ödeme, iade ve '
            'iptal işlemleri mağazanın kurallarına ve 6502 sayılı Tüketicinin Korunması Hakkında Kanun\'a tabidir.',
      ),
      YasalBolum(
        'Kullanıcı yükümlülükleri',
        'Verdiğiniz bilgilerin doğru olmasından siz sorumlusunuz; başkası adına ya da yanıltıcı ilan vermemeyi, uygulamayı '
            'kötüye kullanmamayı kabul edersiniz.',
      ),
      YasalBolum(
        'Sorumluluğun sınırı',
        'Uygulama bilgilendirme amaçlıdır. Hizmet sağlayıcı, uygulamadaki hesaplama, mevzuat özeti, ilan ve haberlerin '
            'eksiksiz, hatasız ve güncel olacağını garanti etmez; bu içeriklere dayanılarak yapılan işlemlerden doğan '
            'dolaylı zararlardan, kanunen sınırlandırılamayan haller (kast ve ağır kusur dahil) ve tüketici mevzuatından '
            'doğan haklar saklı kalmak üzere sorumlu değildir. Hizmet bakım, güncelleme veya mücbir sebeplerle geçici olarak kesilebilir.',
      ),
      YasalBolum(
        'Değişiklikler ve uygulanacak hukuk',
        'Koşullar güncellenebilir; önemli değişiklikler uygulama içinde duyurulur. Türk hukuku uygulanır. Uyuşmazlıklarda, '
            'tüketici sıfatıyla yapılan başvurularda 6502 sayılı Kanun uyarınca yetkili tüketici hakem heyetleri ve '
            'tüketici mahkemeleri, diğer hallerde Ordu (Ünye) mahkemeleri ve icra daireleri yetkilidir.',
      ),
    ],
  );
}
