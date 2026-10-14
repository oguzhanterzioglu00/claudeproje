# Apple 4.3 / 4.2.6 reddi: Resolution Center cevabı (taslak, 6 Ekim 2026)

Apple'ın mesajı: "önemli değişiklik yapmadan tekrar göndermeyin; uygulamanın şartlara uyduğuna inanıyorsanız bu mesaja
**9 soruyu eksiksiz yanıtlayarak** cevap verin". Aşağıdaki metin App Store Connect → Resolution Center → "Reply to App
Review" alanına yapıştırılır.

Her rakam ve iddia depodan **doğrulandı**: 23.043 satır uygulama kodu, 7.764 satır test, 458 test; Kamu Akademi, Ayas
Yazılım ve Ayas AI Sınav Asistanı ile birebir aynı tek bir `.dart` dosyası ya da görsel yok (SHA-1 karşılaştırması).

## Gönderilecek metin (İngilizce)

Hello App Review Team,

Thank you for the detailed message. We believe Kamu Pusulası meets guidelines 4.3(a), 4.3(b) and 4.2.6. Our answers:

**1. What the app does and the problem it solves.**
Kamu Pusulası is a free, independent utility for people who work in Turkish public service (civil servants, contract
staff and workers). Public-sector employees today have to combine the Official Gazette, a legislation portal, a
recruitment portal and personal spreadsheets just to know what they earn and what they are entitled to. The app brings
this into one personalised place:
- A net-salary engine for civil servants. From the user's own grade, step and years of service it computes the statutory
  components (base salary, additional indicator, seniority pay, allowances, social-security and income/stamp tax
  deductions) and shows the full line-by-line breakdown, pay-raise scenarios and the grade table.
- "What are my rights?": answers questions about leave, sick leave, maternity and paternity leave, appointment and
  transfer from a curated, verified knowledge base of articles of Turkish laws 657, 4857, 1475 and 5510 and the
  contract-staff decree. Every answer shows the exact article and links to the official text. It does not use a
  generative AI model.
- Public job postings from the government's Kariyer Kapısı portal with user-defined alarms (keywords, province, type) and
  local notifications, plus saved postings.
- A daily feed of items relevant to public employees compiled from the Official Gazette.
- Petition drafts (leave, appointment, transfer) pre-filled from the user's profile and citing verified articles.
- Backup and restore of profile, saved postings and alarms between devices.
A neighbouring "place exchange" feature is not part of this release and is shown as "coming soon".
The app is free and contains no ads or purchases in this version. In the future we may add direct sponsorship placements
(agreed directly with advertisers, clearly labelled as ads) and possibly in-app purchases; any such change will follow
the App Store guidelines.
The app states clearly that it is independent and not an official government application, and lists its official
sources at https://oguzhanterzioglu00.github.io/claudeproje/kaynaklar.html

**2. Intended user.**
Adults (18+) employed in Turkish public service under civil-servant (Law 657), contract (4/B) or worker status, and people
who follow public-sector recruitment. The app is in Turkish and relevant only to the Turkish public sector.

**3. Need or gap addressed.**
To our knowledge, existing salary calculators are single-purpose, are not tied to the legal articles behind a result, and
do not connect pay, rights and job postings. The official portals publish the raw sources but are not personalised: they
do not compute a user's net pay, tell them which article applies to their situation, or alert them to a matching job
posting. Kamu Pusulası combines these on the user's own profile and always points back to the official source.

**4. Beta testing before submission.**
We did not run a public beta. The developer tested the app personally on physical devices: Android phones during
development (side-loaded builds), and the iOS build through TestFlight on a physical iPhone belonging to a family
member, where no problems were found. Testing on a physical Android phone found and led us to fix four usability and
layout issues before release. The Android version has since been reviewed and approved on Google Play. The codebase also
has an automated suite of 458 tests (unit and widget).

**5. Standalone product or part of a suite?**
Standalone. The other apps currently published on this developer account serve different purposes and audiences: Kamu
Akademi (exam preparation for public-service promotion and KPSS), Ayas AI – Sınav Asistanı (exam helper), and member-
portal apps for specific trade unions and associations (each one is the portal of one particular organisation, for its
own members). Kamu Pusulası is not one of a series: it has its own brand, backend and audience.

**6. Could this be an in-app purchase or feature of another of our apps?**
No. Kamu Pusulası answers questions about a public employee's pay, legal rights and job postings. None of our other apps
offers these functions (salary engine, rights assistant, job alarms), so there is nothing to consolidate: they are
different products for different audiences. Adding them to an unrelated app (an exam-preparation app, a union member
portal, a game) would mix unrelated functions and audiences and make both products worse.

**7. Shared code, frameworks or assets with other apps on our account.**
No. Apart from standard third-party Flutter packages (for example supabase_flutter, shared_preferences, url_launcher,
flutter_local_notifications), nothing is shared. We compared the source files and assets of this app with our other
Flutter apps (Kamu Akademi, Ayas AI – Sınav Asistanı and our company-profile app): there is not a single identical
source file or asset. The member-portal apps for unions and associations are separate products on a different technology
stack and share no code or assets with this app.

**8. Shared codebase, SDK or content library with any third-party app.**
No. It uses only standard open-source packages. The content (legal-article knowledge base, salary rules, petition
templates, illustrations) was written or drawn specifically for this app. Public feeds (Kariyer Kapısı postings, Official
Gazette items) are fetched from public official sources and attributed.

**9. Created for a client or third party?**
No. It is the developer's own product, designed and built by the developer (Oğuzhan Terzioğlu, trading as Ayas Yazılım,
a registered sole proprietorship in Türkiye with its own D-U-N-S number) in hand-written Flutter/Dart code, not from a
template or app-generation service. It is submitted by its own author, who also owns the concept and branding. No
government body or client provided content, concept or branding.

We would be glad to provide a walkthrough video, a demo account (already supplied in App Review Information) or further
detail if helpful. If you feel anything still falls under 4.3, please tell us which part so we can address it.

Thank you,
Oğuzhan Terzioğlu — Ayas Yazılım

## Göndermeden önce kullanıcıdan teyit edilecekler
1. **Soru 4 (beta testi):** metindeki "developer on physical devices… four issues" doğru mu? Dışarıdan test eden kimse (arkadaş,
   TestFlight davetlisi) varsa eklenmeli, yoksa olduğu gibi kalmalı. **Olmayan test uydurulmaz.**
2. **Soru 1:** uygulama bu build'de tamamen ücretsiz, reklam ve satın alma yok ("Becâyiş Yakında" gösterir). Doğru mu?
3. **Soru 9:** üçüncü kişi/müşteri için yapılmadı. Doğru mu?
4. İstenirse kısa bir **ekran kaydı videosu** eklenir (Apple soruyu somutlaştırmak için sever).
