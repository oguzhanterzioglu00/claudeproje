# Apple 4.3 / 4.2.6 reddi: Şehit Gazi-Sen Bayındır ve Vatansever-Sen Sağlık (taslak, 12 Ekim 2026)

Bu taslaklar, App Store Connect'teki **gerçek geçmiş yazışmalardan** (AHAD-SEN, MİL Enerji-Sen, Vatansever-Sen Sağlık,
Bayındır) çıkarıldı. Her iddia gerçek duruma dayanıyor; boş bırakılan yerler `[DOLDUR]` ile işaretli.

## Geçmişten çıkan tablo

| Uygulama | Gönderim | Sonuç / not |
|---|---|---|
| AHAD-SEN | 26 Ağu | 2.1 (demo hesap) + 3.2 (iş/kurum dağıtımı). Yeni hesap + 5 soruya dürüst, tutarlı cevap → **Approved** (aynı gün) |
| MİL Enerji-Sen | 7 Ağu | 4.1(b) + 3.2. **İmzalı ve kaşeli yetki mektubu** + 3.2 cevabı → **Approved** |
| Vatansever-Sen Sağlık | 23 Ağu–18 Eyl (8 mesaj) | 5.1.1(v) → 2.3.3 → **4.3(a)** → 2.1(a). 29 Ağu'da 4.3(a)'ya gerekçeli cevap + yetki belgesi verildi; Apple sonraki mesajda **4.3'ü bırakıp 2.1(a)'ya (iPad açılış hatası) geçti** |
| Şehit Gazi-Sen Bayındır | 16 Eyl | **4.3(a)**: "benzer ikili/metadata/konsept, tek uygulamada birleştirin" |
| Bayındır + Sağlık | 29 Eyl | Her ikisine **6 Ekim 05:27'de aynı** "4.3 + 4.2.6" 9 soruluk mesaj (Kamu Pusulası'na da aynı dakikada) |
| Ayas Yazılım | 23 Ağu | 5.1.1(v) (gereksiz kişisel veri), 4.3 ile ilgisiz |

**Okuma:** 4.3(a) itirazı Sağlık'ta bir kez cevapla aşıldı. 6 Ekim'deki mesaj aynı itirazın **resmî, 9 soruluk** hâli ve
hesap düzeyinde toplu gönderildi. Cevap vermeden yeniden gönderim işe yaramaz; dürüst, somut cevap yolu açık.

## Cevap taslağı (Sağlık için; Bayındır'da adları değiştir)

> Resolution Center sınırı 4.000 karakter. Aşağıdaki metin ~3.300 karakter.

```
Hello App Review Team,

Thank you for the detailed message. We respectfully ask for reconsideration under 4.3(a), 4.3(b) and 4.2.6. Our answers:

1. What the app does. Vatansever-Sen Sağlık is the official mobile app of Vatansever Kamu Görevlileri Sağlık Sendikası (VATANSEVER-SEN-SAĞLIK), an independent, legally registered labor union in Türkiye. Eligible public health employees apply for membership online; after the union verifies eligibility they use member services: digital membership card with QR verification, union announcements and notifications, documents, surveys, legal-support and member-request channels, and in-app account deletion. It replaces paper forms and phone calls between a union and its members.

2. Intended user. Public-sector health employees in Türkiye who are, or want to become, members of this specific union.

3. Gap. The member services, member records, documents and communications of this one union exist nowhere else on the App Store. Its members have no other app; this is not a generic app competing in an existing category.

4. Beta testing. [DOLDUR: TestFlight'ta kim test etti, hangi geri bildirim uygulandı. Örn: build 2 iPad Air açılış hatası düzeltmesi; sendika yetkilileri/üyeler test ettiyse yaz. Yoksa "developer tested on physical devices via TestFlight" yaz, uydurma.]

5. Standalone or suite? Each union app serves a separate legal organisation and its own membership community; they are not variants for one audience. They share a common technology platform (UI and security infrastructure) maintained by us as the technology provider. The other apps on our account (exam preparation, a public-employee guide) are unrelated.

6. Could it be consolidated into another app? No. A union's members expect their own organisation's app, with its own name, brand, member database, privacy controller and notifications. Merging different organisations would mix member data and identities, which neither the unions nor their members want.

7. Shared code/assets. Common interface and infrastructure components are shared for accessibility, security and maintenance. Each app has its own bundle ID, branding, content, backend, member database, documents, notification channel and privacy policy.

8. Third-party SDKs. Only standard components (for example OneSignal for push notifications). No third-party content library.

9. Created for a client? Yes. We develop and maintain the app as technology provider for the union, which is the owner of the brand and the content provider. The union has authorised us in writing to submit and manage the app (signed and stamped letter attached). If Apple requires the union to be the account holder under 4.2.6, please tell us and the union will submit it under its own account; we want to comply.

We can provide the union's registration documents, a valid review account, screenshots and a screen recording of the organisation-specific functions. If a specific binary, metadata or function looks duplicative, please tell us which one.

Thank you,
Oğuzhan Terzioğlu — Ayas Yazılım
```

## Eklenecek belgeler (her sendika için)
1. **Yetkilendirme mektubu v2**, **imzalı ve kaşeli** (Genel Başkan). Mevcut mektuba şunlar eklenmeli: sendikanın içerik sağlayıcı
   olduğu; Ayas Yazılım'ın teknik hizmet sağlayıcı olarak gönderim ve yazışma yetkisi; gerekirse hesabın sendikaya devrine
   itiraz edilmediği; sendikanın doğrulama telefonu/e-postası.
2. Sendikanın kuruluş/tescil belgesi (tüzel kişilik kanıtı).
3. Geçerli inceleme hesabı (SMS/2FA gerektirmeyen).
4. 30–60 saniyelik ekran kaydı: üyelik başvurusu, giriş, dijital kart, duyurular.

## Tutarlılık kuralları
- AHAD-SEN/MİL'de "herkese açık, ülke çapında sendika, davetsiz üyelik başvurusu" denildi → burada da aynı.
  **"Kapalı üye uygulaması" ya da "unlisted" dili kullanma** (çelişki yaratır).
- Üç uygulamanın (Kamu Pusulası, Bayındır, Sağlık) cevaplarında diğer uygulamalar **aynı listeyle** anılsın.
- Kamu Pusulası cevabıyla çelişen hiçbir şey yazma: orada "member portals are separate products" denildi.
