# Kadro · Becayiş modülü: ürün ve arka uç şartnamesi

Bu belge, "Memur Uygulaması İlk Tasarım" tasarımındaki Becayiş ekranlarının (Tayin sekmesi, İlanlar, İlan ver, Eşleşme, Dilekçe) Flutter uygulamasına ve arka uca nasıl çevrileceğini tanımlar. Modül Kadro'nun kendi özelliğidir; harici bir siteye veya servise bağlı çalışmaz.

## 1. Ürün mantığı

Becayiş, 657 sayılı Kanun'un 73. maddesi kapsamında iki (veya üç) memurun görev yerlerini karşılıklı değiştirmesidir. Kadro yalnızca doğru kişileri buluşturur ve dilekçeyi hazırlar; yer değişikliği kurumun onayına bağlıdır. Uygulama içinde bu açıkça belirtilir.

Kullanıcı akışı:

1. **İlan ver:** Kurum, hizmet sınıfı, unvan ve mevcut il Kadro profilinden gelir. Kullanıcı hedef illeri seçer ve 3'lü zincir tercihini belirler. İlan ücretsizdir.
2. **Mavi tik (isteğe bağlı):** Kurumsal e-postaya 6 haneli kod gider. Doğrulanan ilan öne çıkar.
3. **Eşleşme:** Sistem ikili ve 3'lü zincir eşleşmeleri arar, bulunca bildirim gönderir.
4. **İlgileniyorum:** Taraflar sırayla onay verir. Ödeme yalnızca **tüm taraflar onayladıktan sonra** istenir.
5. **İletişimi aç:** Uygulama içi mağaza ödemesi (tek seferlik). İlana bağlı tüm eşleşmelerin iletişimi açılır.
6. **Dilekçe:** Taraf bilgileriyle otomatik doldurulur, PDF olarak indirilir.

## 1.1 Hukuki dayanak ve kapsam

Araştırma tarihi: 29 Eylül 2026. **Birincil metin (mevzuat.gov.tr) sunucu tarafından okunamadı**; aşağıdaki bulgular aynı ifadeyi aktaran üç bağımsız ikincil kaynaktan derlendi. Yayın öncesi metin, mevzuat.gov.tr'den ve bir idare hukuku uzmanından teyit edilmelidir.

**Doğrulanan çekirdek kural.** 657 sayılı Devlet Memurları Kanunu md. 73: *"Aynı Kurumun başka başka yerlerde bulunan aynı sınıftaki memurları, karşılıklı olarak yer değiştirme suretiyle atanmalarını isteyebilirler. Bu isteğin yerine getirilmesi atamaya yetkili amirlerince uygun bulunmasına bağlıdır."*

Buradan çıkan ürün kuralları:

| Kural | Mevzuattaki durum | Üründe |
|---|---|---|
| Aynı kurum | Yasal şart | Eşleşme yalnızca aynı kurum içinde |
| Aynı sınıf | Yasal şart | Profilde hizmet sınıfı zorunlu alan; eşleşme yalnızca aynı sınıfta |
| Farklı yer | Yasal şart | Aynı ildeki ilanlar eşleşmez |
| Aynı unvan | Yasada yok; kurum uygulaması | Zorunlu değil, skoru artırır; farklı unvanda uyarı gösterilir |
| Kadro derecesi | Kanun metninde şart olarak geçmiyor; kurumlar aranabilir | Zorunlu tutulmaz; kurum kuralı olarak eklenebilir |
| Atamaya yetkili amirin uygun bulması | Yasal şart, takdir yetkisi | Uygulama bunu garanti etmez; ekranlarda açıkça yazar |
| Ret halinde yargı yolu | İdare mahkemesi, genel iptal davası süresi (60 gün) | Bilgi metninde, hukuki tavsiye olmadan |

**Kurum bazlı ek kurallar** (ör. Sağlık Bakanlığı hizmet grupları ve branş uyumu, MEB'de alan ve norm kadro) kurum yönetmelikleri ve uygulamalarından gelir ve zamanla değişir. Bunlar motorda `KurumKurali` olarak eklenir; tek bir genel kural gibi kodlanmaz. İlk sürümde yalnızca yasal asgari uygulanır ve arayüzde "Kurum ek şart arayabilir" uyarısı gösterilir.

**Karıştırılmaması gereken düzenleme.** *Devlet Memurlarının Yer Değiştirme Suretiyle Atanmalarına İlişkin Yönetmelik* (R.G. 25/6/1983, S. 18088) olağan yer değiştirmeyi (tayin: hizmet bölgeleri, zorunlu çalışma süresi, Haziran–Eylül dönemi, mazeret atamaları) düzenler. Becayişi düzenleyen ayrı bir genel yönetmelik bulunamadı; bu yönetmeliğin dönem ve süre kuralları becayişe uygulanmaz.

**Başvuru usulü.** Memurlar taleplerini disiplin amirleri kanalıyla atamaya yetkili amire iletir; iki taraf da dilekçe verir. Dilekçe ekranı bu yüzden "aynı gün, disiplin amiri kanalıyla, iki taraf da" uyarısını gösterir.

**Doğrulanamayan veya belirsiz noktalar** (hukuk teyidi gerekir):
- Aday memurların becayişi: yönetmelik kapsamı aday memurları dışarıda bırakıyor; becayiş için ayrı ve açık bir düzenleme bulunamadı. Ürün, aday memurları ilan vermekten şimdilik dışlar.
- Sözleşmeli personel (4/B): ayrı mevzuata tabi olduğu belirtiliyor. Ürün yalnızca 657 kapsamındaki memurlara açık.
- Asgari hizmet süresi, disiplin kaydı gibi koşullar kurumdan kuruma değişiyor; kanun metninde yok.
- İkincil kaynaklardan birinde "derece kaldırıldı" tablosu, diğerlerinde "sınıf ve derece" ifadesi geçiyor. Kanun metninin kendisi teyit edilene kadar derece şart sayılmaz.
- Kişisel iletişim bilgisinin ücret karşılığı açılması ve KVKK açısından işlenmesi mevzuat dışı bir konudur; ayrıca hukuk ve KVKK görüşü alınmalıdır.

## 2. Veri modeli

| Varlık | Alanlar |
|---|---|
| `Ilan` | `id`, `kullanici_id`, `kurum_id`, `sinif`, `unvan`, `mevcut_il`, `hedef_iller[]`, `zincir_izni`, `durum` (taslak/yayında/kapalı), `mavi_tik`, `olusturma`, `guncelleme` |
| `Eslesme` | `id`, `tip` (ikili/zincir), `ilan_idleri[2..3]`, `skor`, `durum` (yeni/onay_bekliyor/hazir/acik/iptal), `olusturma` |
| `EslesmeOnayi` | `eslesme_id`, `ilan_id`, `onay` (bekliyor/evet/hayir), `zaman` |
| `Yetki` | `ilan_id`, `urun_kodu`, `magaza` (apple/google), `islem_id`, `dogrulandi_zaman` — bir ilan için iletişimin açıldığını kanıtlar |
| `KurumsalDogrulama` | `kullanici_id`, `eposta`, `kod_hash`, `son_kullanma`, `deneme_sayisi`, `dogrulandi` |

İletişim bilgisi (telefon, e-posta) `Ilan` içinde değil, kullanıcı profilinde tutulur ve yalnızca `Yetki` varken ve eşleşme `hazir`/`acik` durumundayken sunucudan döner. İstemciye hiçbir zaman önceden gönderilmez.

## 3. Eşleştirme

- **Aday grubu:** Aynı kurum ve aynı hizmet sınıfı (bkz. §1.1). Unvan ve derece yasal şart değildir; kurum kuralları `KurumKurali` olarak eklenir.
- **İkili:** A ve B için `A.mevcut_il ∈ B.hedef_iller` ve `B.mevcut_il ∈ A.hedef_iller`.
- **3'lü zincir:** Yönlü graf kurulur; `A → B`, "B'nin ilinde A gitmek istiyor" demektir. Uzunluğu 3 olan çevrimler (A → B → C → A) bulunur. Yalnızca `zincir_izni = true` olan ilanlar dahil edilir.
- **Skor (ürün kararı, ayarlanabilir; uygulaması `lib/features/becayis/domain/eslestirici.dart`):** kurum + sınıf 50 puan, aynı unvan +20, hedef tercih sırası en çok +20, tüm taraflar mavi tikliyse +10, zincirde −10; 0–100 aralığında. İkili eşleşmeler zincirlerden önce sıralanır.
- **Çalışma zamanı:** İlan yayınlanınca veya değişince artımlı çalışır (yalnızca aynı kurum + unvan grubu yeniden taranır). Ek olarak gece toplu yeniden tarama yapılır.
- **Gizlilik:** Eşleşme listesinde yalnızca baş harf + soyad, il ve mavi tik bilgisi görünür.

## 4. Ödeme (uygulama içi satın alma)

Kişi iletişimini açmak dijital bir hizmettir. iOS ve Android mağaza politikaları bu tür açmaları uygulama içi satın alma üzerinden yapmayı gerektirir; bu nedenle site tabanlı kart akışı kullanılmaz. Güncel politika ve komisyon oranları yayın öncesinde mağaza belgelerinden doğrulanmalıdır.

- **Ürün:** `becayis_iletisim_ilan` (tüketilebilir), tek seferlik; fiyat ₺249,99 (mağaza fiyat basamağına göre, sonradan değiştirilebilir).
- **Flutter:** `in_app_purchase` paketi. Onay, sistemin kendi ödeme ve biyometrik ekranı ile yapılır.
- **Sunucu doğrulaması (zorunlu):** İstemci satın alma makbuzunu `POST /ilanlar/{id}/odeme` ile gönderir. Sunucu makbuzu Apple App Store Server API veya Google Play Developer API ile doğrular, `Yetki` kaydı oluşturur. İstemci durumu tek başına belirleyici değildir.
- **Çift ödeme koruması:** `islem_id` benzersizdir; aynı işlem ikinci kez yetki üretmez.
- **İade / iptal:** Mağaza iade bildirimleri (Apple Server Notifications, Google RTDN) `Yetki` kaydını iptal eder.
- **Ön koşul:** `POST /ilanlar/{id}/odeme`, ilgili eşleşmenin `hazir` (tüm taraflar onaylı) olmasını şart koşar.

## 5. Doğrulama (mavi tik)

- `POST /dogrulama/eposta` yalnızca `.gov.tr` ve `.edu.tr` alan adlarını kabul eder ve 6 haneli kodu gönderir.
- Kod 10 dakika geçerlidir, en fazla 5 deneme yapılır, kod yalnızca özet (hash) olarak saklanır. Gönderim hız sınırlıdır.
- `POST /dogrulama/kod` başarılıysa `Ilan.mavi_tik = true` olur.
- Alan adı kontrolü kimlik kanıtı değildir; bu yüzden ürün metni "doğrulanmış kurumsal e-posta" der, "resmi görevli" demez.

## 6. API özeti

| Uç | İşlev |
|---|---|
| `GET /ilanlar?il=` | İlan listesi, il filtresi ve sayfalama |
| `POST /ilanlar`, `PATCH /ilanlar/{id}` | İlan oluştur / hedef illeri ve zincir iznini değiştir |
| `GET /ilanlarim/eslesmeler` | Kullanıcının eşleşmeleri (ikili + zincir), skor ve durum |
| `POST /eslesmeler/{id}/ilgileniyorum` | Kullanıcının onayı; karşı taraf(lar)a bildirim |
| `POST /ilanlar/{id}/odeme` | Makbuz doğrulama ve yetki oluşturma |
| `GET /eslesmeler/{id}/iletisim` | Yalnızca `Yetki` varsa iletişim bilgisi |
| `GET /eslesmeler/{id}/dilekce.pdf` | Taraf bilgileriyle doldurulmuş dilekçe |
| `POST /dogrulama/eposta`, `POST /dogrulama/kod` | Mavi tik akışı |

Kimlik doğrulama Kadro hesabı ile yapılır. Tüm uçlar oturum ister; iletişim ve dilekçe uçları ayrıca yetki kontrolü yapar.

## 7. Bildirim, gizlilik, kalite

- **Push bildirimleri:** yeni eşleşme, karşı taraf ilgileniyor, eşleşme hazır (iki taraf onayladı). Kullanıcı bildirimleri kapatabilir.
- **KVKK:** Aydınlatma metni ve açık rıza (iletişim bilgisinin eşleşme onayı sonrası paylaşımı), ilan kapatılınca kişisel verinin silinmesi veya anonimleştirilmesi, erişim kayıtlarının tutulması.
- **Kötüye kullanım:** İlan başına hız sınırı, sahte ilan bildirme, tekrarlayan ilanların birleştirilmesi.
- **Dilekçe:** Şablon metin hukuki gözden geçirmeden sonra sabitlenir. Ekranda "örnek taslak" ibaresi yayın öncesi kaldırılır.
- **Erişilebilirlik:** Tasarımdaki dokunma hedefleri en az 44 dp'dir; hareket azaltma tercihi animasyonları kapatır.

## 8. Açık kararlar (yayın öncesi)

1. Mevzuat teyidi: md. 73 metni mevzuat.gov.tr'den, aday memur ve sözleşmeli durumu ile kurum ek şartları bir idare hukuku uzmanından (bkz. §1.1).
2. Fiyat ve mağaza fiyat basamağı.
3. Aynı ilana ikinci eşleşme geldiğinde ek ödeme istenmeyeceği (bu şartnamede: istenmez) ürün olarak onaylanacak.
4. Bildirimler için Kadro'nun mevcut push altyapısı mı, ayrı servis mi.
5. Eşleşme sıralama ağırlıklarının gerçek veriyle ayarlanması.

## 9. Flutter iskeleti (öneri)

```
lib/features/becayis/
  data/        # API istemcisi, IAP servisi
  domain/      # Ilan, Eslesme, Yetki modelleri
  presentation/
    becayis_panel_page.dart      # Tayin sekmesi
    ilanlar_page.dart
    ilan_ver_page.dart           # doğrulama sheet'i dahil
    eslesme_page.dart            # ikili/zincir, ilgileniyorum, ödeme sheet'i
    dilekce_page.dart
```

Tasarım renkleri Ayas Software logosundan, ikonlar Lucide'dan, yazı tipleri Sora ve Figtree'dir. Bu değerler tema dosyasında tek yerde tanımlanmalıdır.
