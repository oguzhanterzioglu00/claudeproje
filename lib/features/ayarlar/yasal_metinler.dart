/// Yasal metin taslakları. **Hukukçu onayından geçmeden yayınlanmamalıdır**: köşeli parantezli
/// yerler doldurulmalı, metin gerçek veri akışına göre gözden geçirilmelidir.
class YasalBolum {
  const YasalBolum(this.baslik, this.metin);

  final String baslik;
  final String metin;
}

class YasalMetin {
  const YasalMetin({required this.baslik, required this.bolumler, required this.guncelleme});

  final String baslik;
  final List<YasalBolum> bolumler;

  /// Taslağın hazırlandığı tarih (gösterilir).
  final String guncelleme;

  /// Taslakta doldurulması gereken köşeli parantezli yer tutucuların sayısı.
  int get doldurulacakYerSayisi => RegExp(r'\[[^\]]+\]').allMatches(bolumler.map((b) => b.metin).join(' ')).length;
}

abstract final class YasalMetinler {
  static const taslakUyarisi =
      'TASLAK — Bu metin hukuk onayından geçmemiştir ve köşeli parantezli yerler doldurulmamıştır. '
      'Uygulama yayınlanmadan önce bir avukat tarafından gözden geçirilmelidir.';

  static const aydinlatma = YasalMetin(
    baslik: 'Aydınlatma Metni (KVKK md. 10)',
    guncelleme: 'Taslak — 29 Eylül 2026',
    bolumler: [
      YasalBolum(
        'Veri sorumlusu',
        '6698 sayılı Kişisel Verilerin Korunması Kanunu kapsamında veri sorumlusu: [Şirket unvanı, MERSİS no, adres, '
            'iletişim e-postası — doldurulacak].',
      ),
      YasalBolum(
        'İşlenen veriler',
        'Kamu Pusulası\'nı kullanırken şu bilgiler işlenebilir: hesap bilgileri (e-posta adresi, giriş yöntemi; şifren '
            'düz metin olarak değil, tuzlu özet olarak saklanır); profil bilgileri (ad, statü, kurum, hizmet sınıfı, unvan, il); '
            'isteğe bağlı bilgiler (sicil numarası, kurumsal e-posta, derece/kademe/hizmet yılı ve bordro kalemleri, kademeye geliş tarihi, profil fotoğrafı). '
            'Kamu görevlisi olduğunu gösteren bu bilgiler dikkatle korunmalıdır.',
      ),
      YasalBolum(
        'İşleme amaçları',
        'Maaş ve izin hesapları, becayiş eşleştirme ve dilekçe hazırlama, size uygun ilan ve haberlerin gösterilmesi, '
            'hesabınızın yönetimi ve uygulamanın güvenliği.',
      ),
      YasalBolum(
        'Verilerin saklandığı yer ve aktarım',
        'Bu sürümde profil, hesap ve fotoğraf bilgileriniz yalnızca cihazınızda saklanır; sunucuya gönderilmez ve üçüncü '
            'kişilerle paylaşılmaz. Sunucu tabanlı özellikler (hesap eşitleme, becayiş eşleştirme, ödeme doğrulama) '
            'eklendiğinde bu metin güncellenecek; verileriniz ancak açık rızanızla ve burada belirtilen amaçlarla aktarılacaktır. '
            'Yurt dışına aktarım: [Sunucu ve hizmet sağlayıcıların bulunduğu ülkeler — doldurulacak].',
      ),
      YasalBolum(
        'Hukuki sebep ve toplama yöntemi',
        'Veriler, uygulamaya sizin girdiğiniz bilgilerle elektronik ortamda toplanır. Hukuki sebepler: sözleşmenin ifası '
            '(uygulama hizmetinin sunulması), meşru menfaat ve gerektiğinde açık rızanız. [Hukuki sebeplerin veri türüne göre '
            'ayrıntılandırılması — hukukçu tarafından doldurulacak].',
      ),
      YasalBolum(
        'Haklarınız (KVKK md. 11)',
        'Verilerinizin işlenip işlenmediğini öğrenme, bilgi talep etme, amacına uygun kullanılıp kullanılmadığını öğrenme, '
            'aktarıldığı kişileri bilme, düzeltme ve silme/yok etme talep etme, itiraz etme ve zararın giderilmesini isteme '
            'haklarına sahipsiniz. Uygulama içinden verilerinizi kopyalayabilir, profil bilgilerinizi ya da hesabınızı silebilirsiniz. '
            'Başvuru: [iletişim e-postası/adresi — doldurulacak].',
      ),
    ],
  );

  static const kosullar = YasalMetin(
    baslik: 'Kullanım Koşulları',
    guncelleme: 'Taslak — 29 Eylül 2026',
    bolumler: [
      YasalBolum(
        'Hizmetin tanımı',
        'Kamu Pusulası, kamu çalışanlarına maaş ve izin hesaplama araçları, mevzuat bilgisi, becayiş eşleştirme, ilan ve haber '
            'derleme hizmeti sunar. Hizmeti sunan: [Şirket unvanı — doldurulacak].',
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
            'uygulama eşleşme ve iletişim kolaylığı sağlar, atamayı garanti etmez. Ücretli özellikler mağaza (App Store / '
            'Google Play) üzerinden satın alınır; iade koşulları mağaza kurallarına tabidir. [Ücret, iade ve iptal koşulları — doldurulacak].',
      ),
      YasalBolum(
        'Kullanıcı yükümlülükleri',
        'Verdiğiniz bilgilerin doğru olmasından siz sorumlusunuz; başkası adına ya da yanıltıcı ilan vermemeyi, uygulamayı '
            'kötüye kullanmamayı kabul edersiniz.',
      ),
      YasalBolum(
        'Sorumluluğun sınırı',
        '[Sorumluluk sınırlamasına ilişkin hükümler — hukukçu tarafından doldurulacak].',
      ),
      YasalBolum(
        'Değişiklikler ve uygulanacak hukuk',
        'Koşullar güncellenebilir; önemli değişiklikler uygulama içinde duyurulur. Türk hukuku uygulanır; [yetkili mahkeme/icra '
            'daireleri — doldurulacak].',
      ),
    ],
  );
}
