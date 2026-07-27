import re, os

def symbols(path):
    src = open(path).read()
    return {m.group(1): (m.group(2), m.group(3).strip())
            for m in re.finditer(r'<symbol id="([^"]+)" viewBox="([^"]+)"[^>]*>(.*?)</symbol>', src, re.S)}

DISH = symbols('sprite.svg')

# slot -> drawing, matching the 8-step category tint ramp in AppColors
SLOTS = ['i-curry','i-salad','i-egg','i-drink','i-cake','i-grain','i-snack','i-soup']

# main tone = AppColors.categoryGlyphs / categoryGlyphsDark
LIGHT = ['#B3323C','#12735A','#8A5A05','#3A4C8F','#6B3E86','#44652F','#9A4A1E','#1F5C77']
DARK  = ['#FF9AA1','#5FE0BC','#EFC069','#9FB0EC','#C79BDD','#A8C88E','#E8A87C','#83C2DC']
# second tone, lighter in light mode and muted in dark
LIGHT2 = ['#FF9BA4','#4FD3AE','#F0B84E','#8CA0E4','#B98BD6','#8FBA6E','#E8A075','#77BAD8']
DARK2  = ['#C25661','#2E8F73','#9C7C33','#5C6EA8','#8058A0','#69864F','#9E6742','#417F9C']

OUT = 'assets/dish'
os.makedirs(OUT, exist_ok=True)
n = 0
for i, sym in enumerate(SLOTS):
    vb, body = DISH[sym]
    for suffix, main, second in (('l', LIGHT[i], LIGHT2[i]), ('d', DARK[i], DARK2[i])):
        b = re.sub(r'var\(--ill2,[^)]*\)', second, body)
        b = b.replace('currentColor', main)
        open(f'{OUT}/d{i}_{suffix}.svg','w').write(
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}">{b}</svg>')
        n += 1
print("dish assets:", n, "| bytes:", sum(os.path.getsize(f'{OUT}/{f}') for f in os.listdir(OUT)))
