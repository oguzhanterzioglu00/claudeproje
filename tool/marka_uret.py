#!/usr/bin/env python3
"""Kullanıcının hazırladığı tam logodan (yazılı) uygulama içi görseli üretir.

  python3 tool/marka_uret.py     (Pillow gerekir: pip install pillow)

Kaynak: tool/kaynak/kamu_pusulasi_logo.webp (1254x1254, köşeleri beyaz zeminli yuvarlak kare).
Çıktı: assets/marka/logo_tam.png — beyaz köşeler kırpılıp saydamlaştırılmış 640x640 PNG.
Uygulama simgeleri (yazısız pusula) ise `flutter test tool/simge_uret_test.dart` ile çizilir.
"""
from PIL import Image, ImageDraw

KAYNAK = 'tool/kaynak/kamu_pusulasi_logo.webp'
CIKTI = 'assets/marka/logo_tam.png'

# Kaynaktaki yuvarlak karenin sınırları (beyaz zemin dışı) ve köşe yarıçapı, elle ölçüldü.
SOL, SAG, UST, ALT = 82, 1168, 68, 1186
im = Image.open(KAYNAK).convert('RGB')
g = SAG - SOL + 1
# Kare olsun diye dikeyde ortadan kırp.
ust = UST + ((ALT - UST + 1) - g) // 2
kare = im.crop((SOL, ust, SOL + g, ust + g))

# Köşeleri saydam yap: 4x büyük maske çizip küçülterek kenarı yumuşat.
kat = 4
r = int(g * 0.235)  # gerçek köşeden biraz büyük: beyaz kenar kalmasın
maske = Image.new('L', (g * kat, g * kat), 0)
ImageDraw.Draw(maske).rounded_rectangle((0, 0, g * kat - 1, g * kat - 1), radius=r * kat, fill=255)
maske = maske.resize((g, g), Image.LANCZOS)
cikti = kare.convert('RGBA')
cikti.putalpha(maske)
cikti = cikti.resize((640, 640), Image.LANCZOS)
cikti.save(CIKTI, optimize=True)
print(CIKTI, cikti.size)
