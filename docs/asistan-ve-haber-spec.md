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

## 3. Haberler (sonraki modül)

Aynı ilkeler: resmî kaynak (Resmî Gazete, kurum duyuruları, Hazine ve Maliye Bakanlığı genelgeleri) öncelikli; üçüncü taraf haberde yalnızca başlık ve bağlantı; her haber kaynak ve zaman damgası taşır. Otomatik özet kullanılırsa "otomatik özet" etiketi ve kaynağa bağlantı zorunludur. Maaş katsayısı gibi sayısal duyurular (bkz. `docs/maas-spec.md` §4) haber akışından **değil**, doğrulanmış parametre güncellemesiyle uygulamaya girer.

## 4. Profil ve statü

Modüllerin çoğu kullanıcının statüsüne (`Statu`: 657 memuru, 4/B sözleşmeli, işçi, akademik, diğer) göre değişir: Becayiş yalnızca 657 memurlarına açıktır, maaş hesabı şu an yalnızca memurlar içindir, ilan süzgeçleri ve uyum skoru statüye bağlıdır. Profil ekranı (statü, kurum, hizmet sınıfı, unvan, il, derece/kademe, hizmet yılı, ek gösterge vb.) henüz yoktur; uygulama örnek bir profille çalışır. Profil verisi KVKK kapsamındadır: açık rıza, minimum veri, silme hakkı.

## 5. Açık işler

1. Profil ekranı ve kalıcı depolama; statüye göre sekme/özellik açma-kapama.
2. Gerçek `MevzuatAsistani` ve `IlanKaynagi` uygulamaları (HTTP istemcisi) ve arka uç.
3. Ana sayfa özetinin (net maaş, yol haritası) profil ve maaş motoruna bağlanması.
4. Haber modülü tasarımı ve ekranı.
5. Uygulama içi "Kaynağı aç" için `url_launcher` bağlantısı.
