#!/usr/bin/env python3
"""Kamu Pusulası veri akışı üreticisi.

Yalnızca resmî ve yeniden yayına açık kaynaklardan derler (bkz. docs/asistan-ve-haber-spec.md):

* Kariyer Kapısı (T.C. Cumhurbaşkanlığı) kamu işe alım ilanları — RSS: https://kariyerkapisi.gov.tr/RSS
  (üçüncü tarafların ilanları kendi sitesinde/uygulamasında yayımlaması için sunulan resmî besleme;
  "RSS Tasarım Kılavuzu" gereği uygulamada kaynak, logo ve "Kamu İşe Alım İlanları" ibaresi gösterilir).
* Resmî Gazete günlük fihristi — https://www.resmigazete.gov.tr/ (kamu personelini ilgilendiren maddeler).

Haber ajansı içerikleri (TRT, AA, DHA, İHA, memur sitelerinin haberleri...) telif ve kullanım koşulları
nedeniyle bilinçli olarak KULLANILMAZ.

Çıktı: `ilanlar.json` ve `haberler.json` (bir GitHub Actions işi bunları `feed-data` dalına yayımlar; uygulama
oradan okur). Yalnızca Python standart kütüphanesi gerekir.
"""
from __future__ import annotations

import argparse
import datetime as dt
import email.utils
import html
import json
import re
import sys
import unicodedata
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET

KARIYER_KAPISI_RSS = "https://kariyerkapisi.gov.tr/RSS"
KARIYER_KAPISI_API = "https://api.kariyerkapisi.gov.tr/api/ilan/SearchIlanPublic"
KARIYER_KAPISI_ILAN = "https://kariyerkapisi.gov.tr/IlanDetay?i="
RESMI_GAZETE = "https://www.resmigazete.gov.tr/"
TR = dt.timezone(dt.timedelta(hours=3))  # Türkiye tüm yıl UTC+3
UA = "Mozilla/5.0 (KamuPusulasi; +https://github.com/oguzhanterzioglu00/claudeproje)"


def indir(url: str, veri: bytes | None = None, baslik: dict | None = None, zaman: int = 40) -> str | None:
    """URL'yi metin olarak indirir; ulaşılamazsa None döner (üretici tek kaynağın hatasıyla durmaz)."""
    istek = urllib.request.Request(url, data=veri, headers={"User-Agent": UA, **(baslik or {})})
    try:
        with urllib.request.urlopen(istek, timeout=zaman) as r:
            return r.read().decode("utf-8-sig", errors="replace")
    except (urllib.error.URLError, TimeoutError, OSError) as e:
        print(f"UYARI: {url} alınamadı: {e}", file=sys.stderr)
        return None


def sade(s: str) -> str:
    """Küçük harf + Türkçe harfsiz: eşleştirme için."""
    s = s.replace("İ", "i").replace("I", "ı").lower()
    tablo = str.maketrans("ığüşöç", "igusoc")
    s = s.translate(tablo)
    return "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn")


# --------------------------------------------------------------------------- Kariyer Kapısı


def ilan_turu(kategori: str, baslik: str = "") -> str:
    """Kariyer Kapısı kategorisinden uygulamanın ilan türünü (memur/sozlesmeli/isci/diger) çıkarır."""
    k = sade(f"{kategori} {baslik}")
    if "sozlesmeli" in k or "4/b" in k:
        return "sozlesmeli"
    if "isci" in k:
        return "isci"
    if "memur" in k or "kpss" in k:
        return "memur"
    return "diger"


def kurum_ve_baslik(baslik: str) -> tuple[str, str]:
    """"KURUM - İlan başlığı" biçimindeki başlığı kurum ve başlık olarak ayırır; ayrılamazsa kurum boş kalır."""
    parca = re.split(r"\s+[-–—]\s+", baslik, maxsplit=1)
    if len(parca) == 2 and parca[0].strip() and parca[1].strip():
        return parca[0].strip(), parca[1].strip()
    return "", baslik.strip()


def tarih_rss(metin: str | None) -> dt.datetime | None:
    if not metin:
        return None
    try:
        return email.utils.parsedate_to_datetime(metin.strip())
    except (TypeError, ValueError):
        return None


def kariyer_kapisi_rss_ayristir(xml_metin: str) -> list[dict]:
    kok = ET.fromstring(xml_metin.lstrip("﻿"))
    sonuc = []
    for it in kok.iter("item"):
        def al(ad: str) -> str:
            e = it.find(ad)
            return (e.text or "").strip() if e is not None and e.text else ""

        baglanti = al("link") or al("guid")
        m = re.search(r"[?&]i=([0-9a-fA-F-]{36})", baglanti)
        kimlik = m.group(1).lower() if m else baglanti
        if not kimlik:
            continue
        baslik = html.unescape(al("title"))
        kurum, kisa = kurum_ve_baslik(baslik)
        kategori = al("category")
        yayin = tarih_rss(al("pubDate"))
        enc = it.find("enclosure")
        sonuc.append({
            "id": kimlik,
            "baslik": baslik,
            "kurum": kurum,
            "kategori": kategori,
            "tur": ilan_turu(kategori, baslik),
            "yayin": yayin.astimezone(TR).isoformat() if yayin else None,
            "sonBasvuru": None,
            "baglanti": baglanti,
            "gorsel": enc.get("url") if enc is not None else None,
        })
    return sonuc


def kariyer_kapisi_api_ayristir(json_metin: str) -> list[dict]:
    """Kariyer Kapısı web sitesinin kullandığı herkese açık liste uç noktasının çıktısı (alan adları sitenin
    kendi arayüz kodundan): guid, kurumAdi, birimAdi, ilanBaslik, bitTarih, ilanTipi, basvuruLinki."""
    veri = json.loads(json_metin)
    if isinstance(veri, dict):
        veri = veri.get("searchIlan") or veri.get("data") or []
    sonuc = []
    for o in veri:
        if not isinstance(o, dict):
            continue
        kimlik = str(o.get("guid") or "").lower()
        baslik = str(o.get("ilanBaslik") or "").strip()
        if not kimlik or not baslik:
            continue
        kurum = str(o.get("kurumAdi") or "").strip()
        bit = None
        if o.get("bitTarih"):
            try:
                bit = dt.datetime.fromisoformat(str(o["bitTarih"]).replace("Z", "+00:00")).date().isoformat()
            except ValueError:
                bit = None
        baglanti = KARIYER_KAPISI_ILAN + kimlik if (o.get("ilanTipi") in (None, 1, "1") or not o.get("basvuruLinki")) else o["basvuruLinki"]
        sonuc.append({
            "id": kimlik,
            "baslik": f"{kurum} - {baslik}" if kurum and not baslik.upper().startswith(kurum.upper()) else baslik,
            "kurum": kurum,
            "kategori": str(o.get("ilanTuruAdi") or ""),
            "tur": ilan_turu(str(o.get("ilanTuruAdi") or ""), baslik),
            "yayin": None,
            "sonBasvuru": bit,
            "baglanti": baglanti,
            "gorsel": None,
        })
    return sonuc


def ilanlari_birlestir(rss: list[dict], api: list[dict]) -> list[dict]:
    """RSS (resmî, yayın tarihli) esas alınır; API'den gelen bitiş tarihi/kurum bilgisi eşleşen ilana işlenir,
    RSS'te olmayan API ilanları da eklenir. En yeni başta."""
    api_by = {a["id"]: a for a in api}
    sonuc = []
    for r in rss:
        a = api_by.pop(r["id"], None)
        if a:
            r = {**r, "sonBasvuru": a["sonBasvuru"] or r["sonBasvuru"], "kurum": a["kurum"] or r["kurum"]}
        sonuc.append(r)
    sonuc.extend(api_by.values())
    sonuc.sort(key=lambda x: x["yayin"] or "", reverse=True)
    return sonuc


# --------------------------------------------------------------------------- Resmî Gazete

# Kamu personelini ilgilendiren başlıklar için (sadeleştirilmiş) anahtar sözcükler.
ANAHTARLAR = {
    "maas": ["maas", "ek odeme", "asgari ucret", "katsayi", "yan odeme", "tazminat", "zam "],
    "atama": ["atama", "ise alim", "personel alim", "kadro", "gorevde yukselme", "unvan degisikligi", "memur alim"],
    "mevzuat": [
        "memur", "personel", "kamu gorevlileri", "sozlesmeli", "disiplin", "toplu sozlesme", "emekli",
        "sosyal guvenlik", "isci", "yillik izin", "ucretli izin", "mazeret izni", "dogum izni", "ayliksiz izin",
        "ozluk", "istihdam", "calisma saatleri", "uzaktan calisma", "mesai", "kidem tazminati",
    ],
}


def haber_turu(baslik: str) -> str | None:
    """Başlıkta (sözcük başında) anahtar sözcük geçiyorsa türü döner: "izin" sözcüğü "denizin" içinde sayılmaz."""
    s = sade(baslik)
    for tur in ("maas", "atama", "mevzuat"):
        if any(re.search(r"(?<![a-z])" + re.escape(a.strip()), s) for a in ANAHTARLAR[tur]):
            return tur
    return None


def rg_fihrist_ayristir(html_metin: str, gun: dt.date) -> list[dict]:
    """Resmî Gazete günlük fihristinden (bölüm > alt başlık > madde) maddeleri çıkarır."""
    sonuc = []
    bolum = alt = ""
    ogeler = re.finditer(
        r'<div class="(?:card-title html-title|html-subtitle|fihrist-item)[^"]*"[^>]*>(.*?)</div>',
        html_metin,
        flags=re.S,
    )
    for m in ogeler:
        ic = m.group(1)
        sinif = m.group(0)[: m.group(0).index(">")]
        if "card-title" in sinif:
            bolum = _metin(ic)
            alt = ""
        elif "html-subtitle" in sinif:
            alt = _metin(ic)
        else:
            a = re.search(r'<a[^>]*href="([^"]+)"[^>]*>(.*?)</a>', ic, flags=re.S)
            if not a:
                continue
            baslik = re.sub(r"^[–—-]+\s*", "", _metin(a.group(2)))
            if baslik:
                sonuc.append({"bolum": bolum, "alt": alt, "baslik": baslik, "baglanti": html.unescape(a.group(1))})
    return sonuc


def _metin(s: str) -> str:
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", s))).strip()


def rg_gazete_bilgisi(html_metin: str) -> tuple[str, str] | None:
    m = re.search(r'id="spanGazeteTarih">([^<]*)<', html_metin)
    if not m:
        return None
    baslik = html.unescape(m.group(1)).strip()
    sayi = re.search(r"(\d+)\s+Say", baslik)
    return baslik, sayi.group(1) if sayi else ""


def resmi_gazete_haberleri(gun: dt.date, html_metin: str) -> list[dict]:
    """Bir günün Resmî Gazete'si için haberler: günün sayısı + kamu personeliyle ilgili maddeler."""
    bilgi = rg_gazete_bilgisi(html_metin)
    yayin = dt.datetime.combine(gun, dt.time(0, 0), tzinfo=TR).isoformat()
    ymd = gun.strftime("%Y%m%d")
    haberler = []
    maddeler = rg_fihrist_ayristir(html_metin, gun)
    ilgili = []
    for x in maddeler:
        if "yargi" in sade(x["bolum"]) or "ilan" in sade(x["bolum"]):
            continue  # yargı kararları ve ilân bölümü kamu personeli haberi değildir
        tur = haber_turu(x["baslik"])
        if tur:
            ilgili.append({**x, "tur": tur})
    for i, x in enumerate(ilgili):
        haberler.append({
            "id": f"rg-{ymd}-{i + 1}-{abs(hash_kararli(x['baslik'])) % 100000}",
            "baslik": x["baslik"],
            "tur": x["tur"],
            "kaynak": "Resmî Gazete",
            "resmi": True,
            "yayin": yayin,
            "ozet": f"{x['bolum'].title()}{' · ' + x['alt'].title() if x['alt'] else ''}. Metin için kaynağı aç.",
            "baglanti": x["baglanti"],
        })
    if bilgi:
        baslik, sayi = bilgi
        ozet = (
            f"Bugünkü sayıda kamu personeliyle ilgili {len(ilgili)} madde bulundu."
            if ilgili
            else "Bugünkü sayıda kamu personeliyle doğrudan ilgili madde bulunamadı."
        )
        haberler.append({
            "id": f"rg-{ymd}",
            "baslik": baslik,
            "tur": "mevzuat",
            "kaynak": "Resmî Gazete",
            "resmi": True,
            "yayin": yayin,
            "ozet": ozet,
            "baglanti": f"https://www.resmigazete.gov.tr/{gun.strftime('%d.%m.%Y')}",
        })
    return haberler


def hash_kararli(s: str) -> int:
    """Süreçler arasında değişmeyen kısa özet (Python'un hash()'i her çalışmada farklıdır)."""
    d = 0
    for c in s:
        d = (d * 131 + ord(c)) % 1_000_003
    return d


def resmi_gazete_topla(bugun: dt.date, gun_sayisi: int = 5) -> list[dict]:
    haberler = []
    for fark in range(gun_sayisi):
        gun = bugun - dt.timedelta(days=fark)
        url = RESMI_GAZETE if fark == 0 else f"{RESMI_GAZETE}{gun.strftime('%d.%m.%Y')}"
        icerik = indir(url)
        if not icerik:
            continue
        bilgi = rg_gazete_bilgisi(icerik)
        # Ana sayfa en son yayımlanan sayıyı gösterir; başlıktaki tarih beklenen günle uyuşmuyorsa atla.
        if bilgi and not _tarih_uyusuyor(bilgi[0], gun):
            continue
        haberler.extend(resmi_gazete_haberleri(gun, icerik))
    haberler.sort(key=lambda h: (h["yayin"], h["id"]), reverse=True)
    return haberler


AYLAR = ["ocak", "subat", "mart", "nisan", "mayis", "haziran", "temmuz", "agustos", "eylul", "ekim", "kasim", "aralik"]


def _tarih_uyusuyor(baslik: str, gun: dt.date) -> bool:
    m = re.match(r"\s*(\d+)\s+(\S+)\s+(\d{4})", sade(baslik))
    if not m:
        return True
    return int(m.group(1)) == gun.day and m.group(2) == AYLAR[gun.month - 1] and int(m.group(3)) == gun.year


# --------------------------------------------------------------------------- Çıktı


def yaz(yol: str, veri: dict) -> None:
    with open(yol, "w", encoding="utf-8") as f:
        json.dump(veri, f, ensure_ascii=False, indent=1)
        f.write("\n")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--cikti", default=".", help="JSON dosyalarının yazılacağı klasör")
    args = ap.parse_args()
    simdi = dt.datetime.now(TR)

    rss_metin = indir(KARIYER_KAPISI_RSS)
    rss = kariyer_kapisi_rss_ayristir(rss_metin) if rss_metin else []
    api = []
    api_metin = indir(
        KARIYER_KAPISI_API,
        veri=json.dumps({"krM_ID": 0, "searchText": "", "il": "0", "ilanTuru": "0"}).encode(),
        baslik={"Content-Type": "application/json"},
    )
    if api_metin:
        try:
            api = kariyer_kapisi_api_ayristir(api_metin)
        except (ValueError, KeyError, TypeError) as e:
            print(f"UYARI: Kariyer Kapısı API çıktısı çözülemedi: {e}", file=sys.stderr)
    ilanlar = ilanlari_birlestir(rss, api)

    haberler = resmi_gazete_topla(simdi.date())

    if not ilanlar and not haberler:
        print("HATA: hiçbir kaynaktan veri alınamadı; mevcut çıktı korunuyor.", file=sys.stderr)
        return 1
    zaman = simdi.isoformat(timespec="seconds")
    if ilanlar:
        yaz(f"{args.cikti}/ilanlar.json", {
            "guncelleme": zaman,
            "kaynak": "Kariyer Kapısı (kariyerkapisi.gov.tr) — Kamu İşe Alım İlanları",
            "ilanlar": ilanlar,
        })
    if haberler:
        yaz(f"{args.cikti}/haberler.json", {
            "guncelleme": zaman,
            "kaynak": "Resmî Gazete (resmigazete.gov.tr)",
            "haberler": haberler,
        })
    print(f"{len(ilanlar)} ilan (RSS {len(rss)}, API {len(api)}), {len(haberler)} haber yazıldı.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
