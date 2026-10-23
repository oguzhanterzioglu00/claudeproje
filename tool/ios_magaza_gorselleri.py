"""App Store (iPhone) ekran görüntüleri: gerçek uygulama görüntülerinden Android sistem çubukları (durum çubuğu,
gezinme tuşları) kırpılır, yerine iOS durum çubuğu/Dynamic Island/ana ekran göstergesi konur ve başlık bandı eklenir.

Kullanım: python tool/ios_magaza_gorselleri.py <kaynak_klasor> <cikti_klasor>
Kaynak: 918x2046 gerçek uygulama ekran görüntüleri (Android durum çubuğu üstte ~97 px, gezinme çubuğu altta ~125 px).
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

KAYNAK = Path(sys.argv[1])
CIKTI = Path(sys.argv[2])
CIKTI.mkdir(parents=True, exist_ok=True)
FONT_DIR = Path(__file__).resolve().parent.parent / 'assets' / 'fonts'
ARIAL_B = r'C:\Windows\Fonts\arialbd.ttf'

NAVY = '#182350'
AMBER = '#FBB040'
BG = '#EEF0F8'
APP_BG = '#F5F4F9'
BOYUTLAR = [(1290, 2796), (1284, 2778), (2064, 2752)]  # 6.9", 6.5" ve iPad 13"

# (kaynak dosya adı sırası, başlık, alt başlık)
SAYFALAR = [
    (6, 'Bugün için pusulan', 'Maaş, haklar ve ilanlar tek ekranda'),
    (2, 'Maaşını net gör', 'Kesintileri tek ekranda hesapla'),
    (1, 'Hakkım ne?', 'Mevzuata dayalı hızlı cevaplar'),
    (3, 'İzin hakların yanında', 'Doğru maddeyi saniyeler içinde bul'),
    (4, 'Gündemi kaçırma', 'Kamu personeli için güncel haberler'),
    (5, 'Araçlar tek yerde', 'İzin, zam ve derece hesapları'),
    (7, 'İlanları kolay keşfet', 'Kariyer Kapısı ilanlarını filtrele'),
]


def kaynaklar():
    dosyalar = sorted(KAYNAK.glob('*.jpeg'))
    return dosyalar  # (1)..(6), ardından uzantısız ad = 7


def font(ad, boyut):
    return ImageFont.truetype(str(FONT_DIR / ad), boyut)


def durum_cubugu(d, x0, y0, w, h):
    """iOS durum çubuğu: saat solda, sinyal/Wi-Fi/pil sağda; ortada Dynamic Island."""
    renk = '#0B0F1E'
    f = ImageFont.truetype(ARIAL_B, int(h * 0.38))
    d.text((x0 + w * 0.11, y0 + h * 0.60), '9:41', font=f, fill=renk, anchor='lm')
    # Dynamic Island
    iw, ih = w * 0.27, h * 0.52
    d.rounded_rectangle((x0 + (w - iw) / 2, y0 + h * 0.34, x0 + (w + iw) / 2, y0 + h * 0.34 + ih), ih / 2, fill='#05070F')
    # sağ: sinyal
    bx = x0 + w * 0.70
    by = y0 + h * 0.74
    for i in range(4):
        bh = h * (0.10 + 0.06 * i)
        d.rounded_rectangle((bx + i * h * 0.12, by - bh, bx + i * h * 0.12 + h * 0.075, by), 2, fill=renk)
    # wifi (üç yay + nokta)
    cx, cy = x0 + w * 0.795, by
    for r, k in ((h * 0.30, 5), (h * 0.20, 5), (h * 0.10, 5)):
        d.arc((cx - r, cy - r, cx + r, cy + r), 225, 315, fill=renk, width=max(3, int(h * 0.055)))
    d.ellipse((cx - h * 0.035, cy - h * 0.05, cx + h * 0.035, cy + h * 0.02), fill=renk)
    # pil
    px = x0 + w * 0.85
    pw, ph = h * 0.52, h * 0.26
    py = y0 + h * 0.60 - ph / 2
    d.rounded_rectangle((px, py, px + pw, py + ph), ph * 0.32, outline=renk, width=max(3, int(h * 0.03)))
    d.rounded_rectangle((px + 5, py + 5, px + pw * 0.84, py + ph - 5), ph * 0.2, fill=renk)
    d.rounded_rectangle((px + pw + 4, py + ph * 0.33, px + pw + 9, py + ph * 0.67), 2, fill=renk)


def uret(kaynak_yol, baslik, alt, W, H, cikis):
    im = Image.open(kaynak_yol).convert('RGB')
    app = im.crop((0, 98, im.width, 1922))  # Android çubukları atıldı
    canvas = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(canvas)
    # başlık bandı
    bant_h = int(H * 0.205)
    d.rounded_rectangle((0, -80, W, bant_h), 90, fill=NAVY)
    d.ellipse((W * 0.80, -W * 0.10, W * 1.08, W * 0.18), fill='#2B4A8E')
    d.ellipse((-W * 0.08, bant_h * 0.45, W * 0.10, bant_h * 0.45 + W * 0.18), fill='#22386F')
    S = min(W, int(H * 0.4614))
    d.text((int(W * 0.06), int(bant_h * 0.30)), baslik, font=font('Sora-Bold.ttf', int(S * 0.078)), fill='white')
    d.text((int(W * 0.06), int(bant_h * 0.30 + S * 0.115)), alt, font=font('Figtree-Medium.ttf', int(S * 0.036)), fill='#DCE4FF')
    # cihaz kartı
    ky0, ky1 = int(H * 0.172), H - int(H * 0.018)
    # genişlik: telefon oranını koruyacak kadar (iPad'de kart ortalanır)
    iw_azami = int((ky1 - ky0 - 14) / 2.092)
    kw = min(int(W * 0.85), iw_azami + 28)
    kx0 = (W - kw) // 2
    kx1 = kx0 + kw
    d.rounded_rectangle((kx0, ky0, kx1, ky1 + 120), 110, fill='#0B0F1E')  # çerçeve (alt taşan kısım kırpılır)
    ic0, ic1 = kx0 + 14, kx1 - 14
    iw = ic1 - ic0
    # iç alan (uygulama + durum çubuğu), köşeler yuvarlak
    ic_y0, ic_y1 = ky0 + 14, H - int(H * 0.018)
    ic = Image.new('RGB', (iw, ic_y1 - ic_y0), APP_BG)
    idr = ImageDraw.Draw(ic)
    sb_h = int(iw * 0.105)
    idr.rectangle((0, 0, iw, sb_h), fill=APP_BG)
    durum_cubugu(idr, 0, 0, iw, sb_h)
    olcek = iw / app.width
    a = app.resize((iw, int(app.height * olcek)), Image.LANCZOS)
    ic.paste(a, (0, sb_h))
    # ana ekran göstergesi
    gw = int(iw * 0.34)
    gy = ic.height - 26
    idr.rounded_rectangle(((iw - gw) // 2, gy, (iw + gw) // 2, gy + 10), 5, fill='#0B0F1E')
    mask = Image.new('L', ic.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, ic.width, ic.height + 200), 96, fill=255)
    canvas.paste(ic, (ic0, ic_y0), mask)
    canvas.save(cikis, optimize=True)


def main():
    dosyalar = kaynaklar()
    assert len(dosyalar) == 7, f'7 kaynak görüntü bekleniyordu: {len(dosyalar)}'
    for sira, (no, baslik, alt) in enumerate(SAYFALAR, 1):
        for W, H in BOYUTLAR:
            alt_klasor = CIKTI / f'{W}x{H}'
            alt_klasor.mkdir(exist_ok=True)
            uret(dosyalar[no - 1], baslik, alt, W, H, alt_klasor / f'{'ipad' if W == 2064 else 'iphone'}_{sira:02d}.png')
    print('tamam', CIKTI)


main()
