# Becayiş ve reklam alanı canlıya alma notları

Bu çalışma mevcut `1.0.1+2` mağaza sürümüne gönderilmez. Özellikler derleme bayraklarının arkasında kapalı tutulur.

## Hazır olanlar

- Supabase üzerinde gerçek becayiş ilanı oluşturma, düzenleme, kapatma ve listeleme istemcisi
- Aynı kurum ve hizmet sınıfı içinde ikili/üçlü eşleştirme
- Yalnızca maskeli ad ve görev bilgilerinin yayımlanması; sicil, telefon ve e-posta ilan tablosuna yazılmaz
- RLS politikaları ve kullanıcı başına tek ilan
- 81 ilin tamamı
- Sponsor banner bileşeni ve boş durumda WhatsApp reklam başvurusu
- Apple/Google ortak `in_app_purchase` istemcisi ve sunucu makbuz doğrulama arayüzü

## Açma sırası

1. `supabase/migrations/202610030001_becayis_ilanlari.sql` Supabase projesine uygulanır.
2. Google Play Console ve App Store Connect'te `becayis_iletisim_ilan` tüketilebilir ürünü oluşturulur.
3. `becayis-odeme-dogrula` Edge Function içinde Apple App Store Server API ve Google Play Developer API doğrulaması tamamlanır. Başarılı makbuz için sunucuda kalıcı yetki kaydı tutulmadan ödeme bayrağı açılmaz.
4. İlk test derlemesi şu bayrakla alınır: `--dart-define=BECAYIS_ACIK=true`.
5. Makbuz doğrulama ve geri ödeme testleri geçince `--dart-define=BECAYIS_ODEME_ACIK=true` eklenir.
6. Reklam alanı için `--dart-define=REKLAM_ALANI_ACIK=true` eklenir.

## Mağaza beyanları

- Ücretli iletişim açma yayımlanacak sürümde uygulama içi satın alma olarak beyan edilir.
- Sponsor bannerları yayınlanacağı zaman Google Play'deki “Reklam içeriyor” beyanı güncellenir.
- Sponsorlu içerik banner üzerinde açıkça `REKLAM` olarak etiketlenir.
- WhatsApp düğmesi yalnızca mesajı hazırlar; kullanıcı göndermeden mesaj iletilmez.

## Reklam iletişimi

Varsayılan başvuru bağlantısı `+90 552 931 69 03` numarasına gider. Banner bileşeni daha sonra Supabase'den dönen firma adı, metin, görsel ve hedef bağlantı ile beslenebilir.
