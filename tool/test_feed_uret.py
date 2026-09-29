import datetime as dt
import json
import os
import unittest

import feed_uret as f

DIZIN = os.path.join(os.path.dirname(__file__), "testdata")


def oku(ad):
    with open(os.path.join(DIZIN, ad), encoding="utf-8") as x:
        return x.read()


class KariyerKapisiTest(unittest.TestCase):
    def setUp(self):
        self.ilanlar = f.kariyer_kapisi_rss_ayristir(oku("kariyer_kapisi_rss.xml"))

    def test_gercek_rss_ayristirilir(self):
        self.assertEqual(len(self.ilanlar), 8)
        i = self.ilanlar[0]
        self.assertEqual(i["id"], "f4915f84-3749-4c5d-9272-bb194f2b938b")
        self.assertTrue(i["baglanti"].startswith("https://kariyerkapisi.gov.tr/IlanDetay?i="))
        self.assertEqual(i["kurum"], "YÜKSEK SEÇİM KURULU BAŞKANLIĞI")
        self.assertEqual(i["yayin"], "2026-09-18T10:00:00+03:00")
        self.assertTrue(i["gorsel"].startswith("https://kariyerkapisi.gov.tr/UPS/"))
        self.assertIsNone(i["sonBasvuru"])

    def test_tur_kategoriden_cikarilir(self):
        self.assertEqual(f.ilan_turu("Sözleşmeli Personel İlanları"), "sozlesmeli")
        self.assertEqual(f.ilan_turu("B Grubu Memur"), "memur")
        self.assertEqual(f.ilan_turu("A Grubu Memur (Kariyer Meslek)"), "memur")
        self.assertEqual(f.ilan_turu("Sürekli İşçi İlanları"), "isci")
        self.assertEqual(f.ilan_turu("Yurt Dışı Eğitim İlanları"), "diger")
        self.assertEqual(f.ilan_turu("", "X ÜNİVERSİTESİ - Sözleşmeli Personel (657-4/B) Alım İlanı"), "sozlesmeli")

    def test_kurum_ayrimi(self):
        self.assertEqual(f.kurum_ve_baslik("ABC BAKANLIĞI - Memur Alımı"), ("ABC BAKANLIĞI", "Memur Alımı"))
        self.assertEqual(f.kurum_ve_baslik("Kurumsuz başlık"), ("", "Kurumsuz başlık"))

    def test_api_cikti_ve_birlestirme(self):
        api = f.kariyer_kapisi_api_ayristir(json.dumps([
            {"guid": "F4915F84-3749-4C5D-9272-BB194F2B938B", "kurumAdi": "YÜKSEK SEÇİM KURULU BAŞKANLIĞI",
             "birimAdi": "Bilgi İşlem", "ilanBaslik": "Sözleşmeli Bilişim Personeli", "bitTarih": "2026-10-05T00:00:00",
             "ilanTipi": 1},
            {"guid": "00000000-0000-0000-0000-000000000001", "kurumAdi": "Y KURUMU", "ilanBaslik": "Sürekli İşçi Alımı",
             "bitTarih": "2026-10-20T00:00:00", "ilanTipi": 2, "basvuruLinki": "https://ornek.gov.tr/basvuru"},
            {"guid": "", "ilanBaslik": "geçersiz"},
            "bozuk",
        ]))
        self.assertEqual(len(api), 2)
        birlesik = f.ilanlari_birlestir(self.ilanlar, api)
        self.assertEqual(len(birlesik), 9)
        ilk = next(i for i in birlesik if i["id"] == "f4915f84-3749-4c5d-9272-bb194f2b938b")
        self.assertEqual(ilk["sonBasvuru"], "2026-10-05")
        api_only = next(i for i in birlesik if i["id"].endswith("0001"))
        self.assertEqual(api_only["baglanti"], "https://ornek.gov.tr/basvuru")
        self.assertEqual(api_only["tur"], "isci")
        self.assertEqual(birlesik[-1]["id"], api_only["id"], "yayın tarihi olmayan ilan sona gider")

    def test_bozuk_veya_bos_rss_dusurmez(self):
        self.assertEqual(f.kariyer_kapisi_rss_ayristir("<rss><channel></channel></rss>"), [])
        with self.assertRaises(Exception):
            f.kariyer_kapisi_rss_ayristir("<rss>")


class ResmiGazeteTest(unittest.TestCase):
    def test_gercek_gun_personel_maddesi_yoksa_yalniz_gunluk_ozet(self):
        gun = dt.date(2026, 9, 29)
        h = f.resmi_gazete_haberleri(gun, oku("resmi_gazete_gun.html"))
        self.assertEqual(len(h), 1)
        self.assertEqual(h[0]["id"], "rg-20260929")
        self.assertIn("33385", h[0]["baslik"])
        self.assertIn("doğrudan ilgili madde bulunamadı", h[0]["ozet"])
        self.assertEqual(h[0]["baglanti"], "https://www.resmigazete.gov.tr/29.09.2026")
        self.assertTrue(h[0]["resmi"])

    def test_personel_maddeleri_secilir_yargi_ve_ilan_bolumu_haric(self):
        gun = dt.date(2026, 9, 15)
        h = f.resmi_gazete_haberleri(gun, oku("resmi_gazete_personel.html"))
        basliklar = [x["baslik"] for x in h]
        self.assertIn("Kamu Görevlilerinin Ek Ödeme Oranlarına İlişkin Karar", basliklar)
        self.assertIn("Sözleşmeli Personel Çalıştırılmasına İlişkin Esaslarda Değişiklik Yapılmasına Dair Karar", basliklar)
        self.assertIn("Bir Bakanlığın Personel Alım Sınavı ve Kadro Yönetmeliği", basliklar)
        self.assertNotIn("Bir Üniversitenin Spor Salonu Yönetmeliği", basliklar)
        self.assertFalse([b for b in basliklar if "Anayasa Mahkemesi" in b], "yargı bölümü alınmaz")
        self.assertFalse([b for b in basliklar if "Çeşitli" in b], "ilan bölümü alınmaz")
        turler = {x["baslik"]: x["tur"] for x in h}
        self.assertEqual(turler["Kamu Görevlilerinin Ek Ödeme Oranlarına İlişkin Karar"], "maas")
        self.assertEqual(turler["Bir Bakanlığın Personel Alım Sınavı ve Kadro Yönetmeliği"], "atama")
        ozet = next(x for x in h if x["id"] == "rg-20260915")
        self.assertIn("3 madde", ozet["ozet"])

    def test_kimlikler_kararli_ve_benzersiz(self):
        gun = dt.date(2026, 9, 15)
        a = f.resmi_gazete_haberleri(gun, oku("resmi_gazete_personel.html"))
        b = f.resmi_gazete_haberleri(gun, oku("resmi_gazete_personel.html"))
        self.assertEqual([x["id"] for x in a], [x["id"] for x in b])
        self.assertEqual(len({x["id"] for x in a}), len(a))

    def test_tarih_uyusmazligi(self):
        self.assertTrue(f._tarih_uyusuyor("29 Eylül 2026 Tarihli ve 33385 Sayılı Resmî Gazete", dt.date(2026, 9, 29)))
        self.assertFalse(f._tarih_uyusuyor("28 Eylül 2026 Tarihli ve 33384 Sayılı Resmî Gazete", dt.date(2026, 9, 29)))
        self.assertTrue(f._tarih_uyusuyor("tanınmayan başlık", dt.date(2026, 9, 29)))


class YardimciTest(unittest.TestCase):
    def test_sade(self):
        self.assertEqual(f.sade("İŞÇİ Öğretmen ŞÜĞ"), "isci ogretmen sug")

    def test_haber_turu(self):
        self.assertIsNone(f.haber_turu("Bir Ilçenin İmar Planı"))
        self.assertEqual(f.haber_turu("Asgari Ücret Tespit Komisyonu Kararı"), "maas")
        # Gerçek Resmî Gazete başlıklarından yanlış pozitif olmaması gerekenler
        for b in [
            "2026 Yılı Ağustos Ayına Ait Dahilde İşleme İzin Belgelerinin (D1) Listesi",
            "Kilis 7 Aralık Üniversitesi Yaşlı Sağlığı Çalışmaları Uygulama ve Araştırma Merkezi Yönetmeliği",
        ]:
            self.assertIsNone(f.haber_turu(b), b)
        self.assertEqual(f.haber_turu("Ticaret Bakanlığı Disiplin Amirleri Yönetmeliği"), "mevzuat")
        self.assertEqual(f.haber_turu("Kamu Personeli Yıllık İzin Yönetmeliği"), "mevzuat")


if __name__ == "__main__":
    unittest.main()
