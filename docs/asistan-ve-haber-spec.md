# Kamu Pusulası · Asistan, ilan ve haber modülleri: arka uç şartnamesi

Bu belge, Flutter uygulamasındaki üç modülün (Hakkım ne?, İlanlar ve ileride Haberler) arka uç sözleşmelerini tanımlar. Arayüzler ve servis arayüzleri hazırdır (`lib/features/asistan/`, `lib/features/ilanlar/`); uygulama şu an örnek servislerle çalışır. Ortak ilke: **her içerik kaynağını ve güncellenme zamanını taşır; sistem bilmediğini uydurmaz.**

## 1. Hakkım ne? (mevzuat asistanı)

**Sözleşme:** `MevzuatAsistani.sor(String) → AsistanCevabi { metin, kaynaklar[], ornek }`; her kaynak `{ baslik, alinti }`.

**Şu anki durum:** `SahteAsistan` yalnızca doğrulanmış Becayiş maddesine (657 md. 73) gerçek kanun metniyle cevap verir; diğer sorularda "örnek cevap" etiketiyle üretim yapmaz. Bu davranış korunmalı: doğrulanmamış içerik hukuki cevap gibi sunulmaz.

**Gerçek sürüm (öneri):**
1. **Mevzuat derlemi:** mevzuat.gov.tr'den kanun, KHK, yönetmelik, tebliğ metinleri sürümleriyle indekslenir (madde bazında). Yürürlük ve değişiklik tarihleri saklanır; eski sürüm cevapta kullanılmaz.
2. **Alma (retrieval):** soru, ilgili madde parçalarını getirir (anlamsal + anahtar kelime).
3. **Üretim:** model yalnızca getirilen maddelerden cevap yazar; her iddia bir maddeye bağlanır. Madde bulunamazsa "Bu konuda kaynak bulamadım" der; tahmin etmez.
4. **Doğrulama:** cevaptaki alıntılar kaynak metinle karakter düzeyinde karşılaştırılır; uyuşmayan alıntı atılır.
5. **Çıktı:** metin + kaynak listesi (madde başlığı, alıntı, yürürlük tarihi).

**Güvenlik ve sınırlar:**
- Her cevapta "Hukuki tavsiye değildir" uyarısı (arayüzde sabit).
- Dava, ceza, disiplin soruşturması gibi kişisel hukuki durumlarda cevap yerine "bir avukata/hukuk müşavirliğine danışın" yönlendirmesi.
- Kişisel veri (sicil no, TC kimlik no) sorulardan otomatik maskelenir, günlüklere yazılmaz.
- Cevap ve soru günlükleri anonim tutulur; KVKK aydınlatma metni ve saklama süresi tanımlanır.
- Değerlendirme seti: doğrulanmış soru-cevap-madde üçlüleri ile sürüm başına doğruluk ölçümü; eşik altında yayına çıkmaz.

**Şu anki kapsam (yerel bilgi bankası, `lib/features/asistan/bilgi_bankasi.dart`):** 657 sayılı Kanun'dan resmî mevzuat.gov.tr birleştirilmiş metninden birebir alıntılarla becayiş, yıllık izin, mazeret izni, rapor/hastalık izni, aylıksız izin, kademe ve derece, tayin, disiplin cezaları, adaylık ve çalışma saatleri. Emeklilik, 5510 sayılı Kanun md. 28 (2008 sonrası ilk kez sigortalı olanlar) ve geçici md. 4 alıntılarıyla yanıtlanır; 2008 öncesi memuriyete başlayanlar için mülga 5434 sayılı Kanun asistanda yoktur ve cevap bunu açıkça uyarır. Kapsam dışı ve eşleşmeyen sorularda tahmin yürütülmez.

**İşçi konuları (`Kitle.isci`):** 4857 sayılı İş Kanunu (yıllık izin md. 53, doğum/süt/mazeret izni md. 74 ve ek md. 2, çalışma süresi md. 63 ve fazla çalışma md. 41, ihbar süreleri md. 17 ve geçerli fesih md. 18) ile 1475 sayılı Kanun md. 14 (kıdem tazminatı; 4857 md. 120 ve geçici md. 6 uyarınca yürürlükte kalan tek madde). Alıntılar mevzuat.gov.tr birleştirilmiş metinlerinden (4857: 22/4/2026 tarihli 7578 sayılı Kanun'a kadar işlenmiş) birebir alınmış ve otomatik olarak kaynak metinle karşılaştırılmıştır. Asistan kullanıcının statüsüne göre (memur → 657, işçi → İş Kanunu; sözleşmeli/diğer → belirsiz) konu seçer; soruda "işçi"/"memur" geçiyorsa o esas alınır; grup belirsizse önce memur konularına bakılır. **4/B sözleşmeli konuları (`Kitle.sozlesmeli`):** "Sözleşmeli Personel Çalıştırılmasına İlişkin Esaslar"ın (Bakanlar Kurulu Kararı 6/6/1978-7/15754; 8/5/2026 tarihli ve 33247 sayılı R.G.'de yayımlanan 11307 sayılı Cumhurbaşkanı Kararına kadar işlenmiş birleştirilmiş metin) md. 9 (yıllık izin 20/30 gün, doğum izni 24 hafta, süt izni, mazeret ve refakat izinleri), md. 10 (hastalık izni) ve md. 13 (çalışma saatleri: memurlarınki uygulanır). Alıntılar kaynak metinle otomatik karşılaştırılmıştır. Sözleşmeliler 657'nin izin/disiplin maddelerine bu Esaslar üzerinden bağlı olmadığından, sözleşmeli kullanıcıya memur konusu gösterilirse cevap "bu cevap memurlar için geçerli mevzuata dayanıyor; senin için farklı olabilir" uyarısı taşır (aynı kural işçi/memur için de geçerlidir).

Kıdem tazminatı tavanı, toplu iş sözleşmesi hükümleri, sözleşmeli personelin disiplin ve aylıksız izin rejimi ve hastalık izninin gün sayısı (ilgili ibare Danıştay kararıyla iptal edilmiştir) bu metinlerde yoktur; cevaplar bunu uyarıyla belirtir.

**Açık karar:** dış bir dil modeli sağlayıcısı kullanılıp kullanılmayacağı (veri aktarımı, KVKK, maliyet) ve mevzuat derleminin hangi kurumla lisanslanacağı.

## 2. İlanlar (kamu iş ilanları)

**Sözleşme:** `IlanKaynagi.getir() → List<KamuIlani>`; her ilan `{ id, baslik, kurum, konum, tur, yayinTarihi, sonBasvuru, kaynakAdi, kaynakGuncelleme, ozet, uyum? }`.

**Kaynaklar (öncelik sırası, resmî olanlar):** kurumların kendi duyuru sayfaları, ÖSYM/KPSS tercih ve ilan duyuruları, İŞKUR kamu işçi alımları, Resmî Gazete ilan bölümü. Habere özel sitelerin içeriği **kopyalanmaz**; gerekiyorsa yalnızca başlık ve bağlantı verilir (telif).

**Boru hattı:**
1. **Toplama:** kaynak başına zamanlanmış çekim (robots.txt ve kullanım şartlarına uygun, makul aralıkla).
2. **Ayrıştırma:** başlık, kurum, konum, tür, başvuru tarihleri çıkarılır. Tarih çıkarılamazsa ilan **yayınlanmaz** (yanlış tarih, ilan olmamasından kötüdür).
3. **Tekilleştirme:** aynı ilan birden çok kaynakta çıkarsa resmî olan kaynak kazanır.
4. **Kalite denetimi:** tutarlılık (yayın < son başvuru), süresi dolan ilanların gizlenmesi, şüpheli değişikliklerin insan onayına düşmesi.
5. **Yayın:** her ilanda `kaynakAdi` ve `kaynakGuncelleme` zorunludur; uygulama "başvurmadan önce şartları kaynaktan doğrula" uyarısını gösterir.

**Uyum skoru:** kullanıcının statüsü, unvanı/mesleği, ili ve eğitim düzeyi ile ilanın gerektirdikleri karşılaştırılır (0-100). Profil eksikse skor gösterilmez (`uyum = null`); uygulama "Sana uygun" süzgecini yalnızca skor ≥ 70 olanlarla doldurur. Skorun nasıl hesaplandığı kullanıcıya açıklanabilir olmalıdır.

**Bildirim:** kaydedilen ilanların son başvuru gününe 3 gün kala ve profile yüksek uyumlu yeni ilanlarda push (kullanıcı kapatabilir).

### 2.1 Gerçek akış (2026-09-29 itibarıyla uygulamada)

`tool/feed_uret.py` + `.github/workflows/feed.yml`: GitHub Actions her 15 dakikada Kariyer Kapısı'nın (T.C. Cumhurbaşkanlığı) resmî RSS beslemesini (`https://kariyerkapisi.gov.tr/RSS`) okur ve `ilanlar.json` dosyasını `feed-data` dalına yayımlar; uygulama `raw.githubusercontent.com/.../feed-data/ilanlar.json` adresini okur (`AkisIlanKaynagi`, CORS açık, ~5 dk önbellek). Kariyer Kapısı bu beslemeyi üçüncü tarafların kendi site/uygulamalarında yayımlaması için sunar; "RSS Tasarım Kılavuzu" gereği ekranda **Kariyer Kapısı logosu ve "Kamu İşe Alım İlanları" ibaresi** gösterilir (`_KaynakKunyesi`), başlık kurum adı + ilan başlığı olarak sunulur, ilan tam metni kopyalanmaz, "Başvur/Kaynağı aç" ilan sayfasına götürür.

Bilinen sınırlar (dürüstlük): RSS'te **son başvuru tarihi yoktur** (ekranda "Son başvuru tarihi ilan sayfasında" yazar) ve `pubDate` bazı ilanlarda gelecekte bir tarihtir (başvuru başlangıcı gibi davranır; ekran "Başvurular ... tarihinde başlar" der). Sitenin kendi arayüzünün kullandığı liste uç noktası (`api.kariyerkapisi.gov.tr/api/ilan/SearchIlanPublic`, bitiş tarihi ve kurum içerir) GitHub çalıştırıcılarından ve bu geliştirme ortamından zaman aşımına uğradı; üretici erişilebilirse otomatik olarak bitiş tarihini ekler (`ilanlari_birlestir`), erişilemezse RSS ile devam eder. "Sana uygun" süzgeci gerçek akışta gizlidir (uyum puanı verisi yok).

**Yeni ilan bildirimi:** Ayarlar'dan açılır (opt-in, izin ister), tür seçimi vardır (varsayılan statüye göre). Uygulama açılırken, ön plana gelince ve açıkken 15 dakikada bir akış kontrol edilir; **Android'de uygulama kapalıyken de** `workmanager` ile periyodik (en sık 15 dakika, sistem pil kurallarına göre ertelenebilir) arka plan işi çalışır (`arka_plan.dart`: kayıtlı hesabı ve tercihi okur, ilan ve Resmî Gazete akışına bakar, yenileri bildirir). Sunucu, Firebase ya da üçüncü taraf hesabı gerekmez. iOS'ta arka plan işi yoktur (güvenilir değil); bildirim yalnızca uygulama açıkken çalışır. Açarken mevcut ilanlar "görüldü" sayılır; görülen kimlikler yalnızca cihazda saklanır. Ayarlar'daki "Test bildirimi" ve "Şimdi kontrol et" düğmeleri izin/akış sorunlarını ayıklamak içindir. Anında (dakikalar içinde) bildirim gerekirse sunucu tarafı push (FCM — kendisi ücretsizdir — ve iOS için APNs) gerekir.

**Kaydedilen ilanlar:** ilan kartındaki işaretle kaydedilir (`KayitliIlanlar`); ilanın kendisi (başlık, kurum, tarihler, bağlantı) cihazda saklanır, böylece akıştan kalksa ya da internet olmasa da "Kaydedilenler" süzgecinde görünür (en fazla 100). Hesap silinince silinir.

**Ana sayfa "Yeni ilanlar":** kullanıcının statüsüne uygun türlerden en yeni 3 açık ilan (`IlanlarBolumu`); dokununca İlanlar sekmesi açılır. Akış yüklenemezse ya da uygun ilan yoksa bölüm gizlenir.

## 3. Haberler (Gündem)

**Gerçek akış (2026-09-29 itibarıyla):** `haberler.json` — Resmî Gazete günlük fihristinden (`resmigazete.gov.tr`, son 5 sayı) kamu personelini ilgilendiren maddeler (memur, personel, kadro, sözleşmeli, ek ödeme, atama, disiplin, toplu sözleşme...) ve her sayının künyesi (`AkisHaberKaynagi`). Yargı ve ilân bölümleri alınmaz. Resmî Gazete, botlara benzeyen kullanıcı adlarını (içinde "bot" geçenleri) engelliyor; üretici `Mozilla/5.0 (KamuPusulasi; +depo adresi)` kullanır. **Haber ajansı ve haber siteleri (TRT Haber, AA, DHA, İHA, memur siteleri, Google Haberler) bilinçli olarak kullanılmaz:** TRT Haber kullanım şartları ticari amaçlı mobil uygulamalarda kullanımı ve arşiv oluşturmayı yasaklar; Google Haberler RSS'i yalnızca kişisel, ticari olmayan kullanım içindir. Ajans haberi istenirse lisans/iş ortaklığı anlaşması gerekir (ör. AA veya DHA abonelik/API).

**Resmî Gazete bildirimi:** Ayarlar'dan açılır (`YeniHaberTakibi`); personel/maaş/atama maddelerinden görülmemiş olanlar için (günlük sayı künyeleri ve 3 günden eski maddeler hariç) bildirim gösterir. İlan bildirimiyle aynı arka plan işini paylaşır; iş yalnızca iki bildirim de kapalıyken durur.



Aynı ilkeler: resmî kaynak (Resmî Gazete, kurum duyuruları, Hazine ve Maliye Bakanlığı genelgeleri) öncelikli; üçüncü taraf haberde yalnızca başlık ve bağlantı; her haber kaynak ve zaman damgası taşır. Otomatik özet kullanılırsa "otomatik özet" etiketi ve kaynağa bağlantı zorunludur. Maaş katsayısı gibi sayısal duyurular (bkz. `docs/maas-spec.md` §4) haber akışından **değil**, doğrulanmış parametre güncellemesiyle uygulamaya girer.

**Uygulama:** `lib/features/haberler/` — `Haber` (başlık, tür, kaynak adı, yayın tarihi, kısa özet, `resmiKaynak`, `otomatikOzet`, bağlantı), `HaberKaynagi` arayüzü (`getir()`, en yeni başta) ve şimdilik `OrnekHaberKaynagi`. Ana sayfada `GundemBolumu` (en yeni 3 haber; kaynak yüklenemezse sessizce gizlenir), `Tümü` ile `HaberlerSayfasi` (tür süzgeci, hata/boş durum). Ayrıntı alt sayfasında kaynak, tarih, "Resmî kaynak" rozeti ve — özet yapay zekâ ürettiyse — "Otomatik özet" etiketi + uyarı görünür. Haber metni saklanmaz; yalnızca başlık, kısa özet ve bağlantı.

**Görselli slaytlar:** Ana sayfada "Gündem" ve maaş ekranında "Maaş ve mevzuat haberleri" bölümleri yana kaydırılan görselli slaytlardır (`HaberSlaytlari`); kendiliğinden ilerler, dokununca durur, hareketi azalt ayarı ve gizli sekmede ilerlemez. `Haber.gorsel` (URL) doluysa kapak olarak yüklenir; yoksa ya da yüklenemezse türe göre çizilmiş kapak gösterilir. **Görsel telifi:** yalnızca yayın hakkı olan (kurumun kendi duyurusundaki ya da lisanslı) görseller kullanılmalı; üçüncü taraf haber sitelerinin görselleri kopyalanmaz. "Kaynağı aç" `url_launcher` ile yalnızca `https` adreslerini açar; bağlantısı olmayan içerikte düğme pasiftir.

## 4. Profil ve statü

Modüllerin çoğu kullanıcının statüsüne (`Statu`: 657 memuru, 4/B sözleşmeli, işçi, akademik, diğer) göre değişir: Becayiş yalnızca 657 memurlarına açıktır, maaş hesabı şu an yalnızca memurlar içindir, ilan süzgeçleri ve uyum skoru statüye bağlıdır. Profil ekranı (`lib/features/profil/`) hesap açıldıktan sonra 4 adımlı kurulumla doldurulur (bkz. `docs/hesap-spec.md`); ad, statü, kurum, hizmet sınıfı, unvan, il, sicil no, kurumsal e-posta, aday memur bilgisi ve maaş girdileri cihazda (`shared_preferences`) saklanır, ekrandan silinebilir. Ana sayfa, maaş ve becayiş bu profilden beslenir. Profil verisi KVKK kapsamındadır: açık rıza, minimum veri, silme hakkı.

## 5. Açık işler

1. Gerçek `MevzuatAsistani`, `IlanKaynagi` ve `HaberKaynagi` uygulamaları (HTTP istemcisi) ve arka uç.
2. Gerçek kimlik sağlayıcı, Google/Apple girişi ve hesap eşitleme (bkz. `docs/hesap-spec.md`).
3. Profilin bulutla eşitlenmesi (açık rıza + KVKK aydınlatması), statüye göre ilan uyum skoru.
4. 657 dışı statüler (4/B, işçi, akademik) için maaş hesabı.
5. Bildirimler şimdilik uygulama içi ve profilden türetilir; itme bildirimi (push) için arka uç gerekir.
