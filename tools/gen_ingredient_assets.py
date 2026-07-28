import re, os, json

# ---- pull the drawings out of the sprite files ----
def symbols(path):
    src = open(path, encoding="utf-8").read()
    out = {}
    for m in re.finditer(r'<symbol id="([^"]+)" viewBox="([^"]+)"[^>]*>(.*?)</symbol>', src, re.S):
        out[m.group(1)] = (m.group(2), m.group(3).strip())
    return out

ING = symbols('ing.svg')
DISH = symbols('sprite.svg')
print("source drawings:", len(ING), "ingredient +", len(DISH), "dish")

# ---- shape families: one drawing, many tints ----
# This is what makes ~140 icon_keys tractable. p1 is the light tone, p2 the dark.
FAMILY = {
 'g-powder': {
   'powder_turmeric': ('#F0B84E', '#D08A1E'), 'powder_chilli': ('#E06A5A', '#B8362A'),
   'powder_coriander': ('#C4B37A', '#8E7C42'), 'powder_cumin': ('#C09A6E', '#8E6534'),
   'powder_garam': ('#96684A', '#5E3A24'), 'powder_amchur': ('#E3D8A8', '#B0A268'),
   'powder_pepper': ('#8A8478', '#565046'), 'powder_sambar': ('#D9713F', '#A34718'),
   'powder_rasam': ('#C9553E', '#8E3220'), 'powder_chaat': ('#BFA46B', '#8A7136'),
   'powder_pavbhaji': ('#D45B3A', '#9C3218'), 'salt_black': ('#8E8790', '#57525C'),
 },
 'g-seeds': {
   'seeds_cumin': ('#B98B5A', '#8E6534'), 'seeds_mustard': ('#7A6A3A', '#4E4222'),
   'seeds_coriander': ('#D6C79A', '#A89463'), 'seeds_fennel': ('#A8BE7E', '#75904E'),
   'seeds_methi': ('#C9A94E', '#95781F'), 'seeds_ajwain': ('#9A8F5E', '#665D33'),
   'seeds_poppy': ('#9AA0A8', '#5E646C'), 'seeds_pepper': ('#6E6660', '#3E3833'),
   'seeds_sesame': ('#EADFC4', '#B9AC8A'),
 },
 'g-sprig': {
   'leaves_curry': ('#3E7A44', '#2A5C30'), 'leaves_coriander': ('#6FBF6C', '#47954C'),
   'leaves_mint': ('#5FC29A', '#3A8E70'), 'leaves_methi': ('#7FAF5C', '#557A38'),
   'sprouts': ('#A8CE8E', '#6E9450'), 'cat_leafy': ('#57A85F', '#3E7A44'),
 },
 'g-oil': {
   'oil': ('#E8C56A', '#B08E2F'), 'oil_mustard': ('#D9A93F', '#9C7413'),
   'oil_coconut': ('#F2EADA', '#C6BCA4'), 'oil_sesame': ('#C99A5B', '#8E6534'),
   'oil_olive': ('#B7C46A', '#7E8C33'), 'oil_sunflower': ('#F2CB4B', '#BF9814'),
   'cat_oil': ('#E8C56A', '#B08E2F'),
 },
 'g-dal': {
   'dal': ('#F0D68F', '#D9A93F'), 'dal_urad': ('#C9C3B4', '#8E877A'),
   'dal_chana': ('#E0B45C', '#A8801F'), 'dal_arhar': ('#F0C05A', '#C08E1E'),
   'dal_moong': ('#E8DE9A', '#B2A552'), 'dal_masoor': ('#EBA06A', '#B96A32'),
   'horsegram': ('#A9825A', '#6F4F2C'), 'rajma': ('#B4544A', '#7C2E26'),
   'chickpea': ('#E6CE94', '#B39A57'), 'chickpea_black': ('#8E7A5E', '#584730'),
   'cat_legume': ('#F0D68F', '#D9A93F'),
 },
}

# ---- one drawing, one key ----
DIRECT = {
 'salt':'g-salt', 'water':'g-water', 'sugar':'g-besan', 'jaggery':'g-jaggery',
 'tamarind':'g-tamarind', 'ghee':'g-ghee', 'cinnamon':'g-cinnamon',
 'cardamom':'g-cardamom', 'cardamom_black':'g-cardamom', 'bayleaf':'g-bayleaf',
 'powder_hing':'g-hing', 'ginger':'g-ginger', 'garlic':'g-garlic',
 'paste_gg':'g-garlic', 'paste_garlic':'g-garlic', 'paste_ginger':'g-ginger',
 'onion':'g-onion', 'springonion':'g-onion', 'tomato':'g-tomato',
 'chilli_green':'g-chilli', 'chilli_red':'g-chilli', 'paste_chilli':'g-chilli',
 'potato':'g-potato', 'sweetpotato':'g-potato', 'colocasia':'g-potato', 'yam':'g-potato',
 'carrot':'g-carrot', 'radish':'g-carrot', 'drumstick':'g-carrot',
 'spinach':'g-spinach', 'coconut':'g-coconut', 'coconut_milk':'g-lassi',
 'lemon':'g-lemon', 'lime':'g-lemon', 'mango':'g-mango', 'banana':'g-banana',
 'banana_raw':'g-banana', 'apple':'g-apple', 'orange':'g-orange',
 'curd':'g-curd', 'buttermilk':'g-lassi', 'milk':'g-cream', 'cream':'g-cream',
 'paneer':'g-paneer', 'tofu':'g-paneer', 'khoya':'g-paneer',
 'cheese':'g-cheese', 'butter':'g-butter', 'egg':'g-egg2',
 'rice':'g-rice', 'rice_basmati':'g-rice', 'quinoa':'g-rice', 'poha':'g-rice',
 'flour':'g-besan', 'flour_rice':'g-besan', 'flour_corn':'g-besan',
 'besan':'g-besan', 'sooji':'g-besan', 'oats':'g-besan', 'bakingsoda':'g-besan',
 'cauliflower':'g-cauliflower', 'broccoli':'g-cauliflower', 'cabbage':'g-cauliflower',
 'mushroom':'g-mushroom', 'honey':'g-ghee', 'vinegar':'g-oil', 'soysauce':'g-oil',
 'cat_vegetable':'g-carrot', 'cat_fruit':'g-apple', 'cat_dairy':'g-cream',
 'cat_spice':'g-powder', 'cat_grain':'g-rice', 'cat_nut':'g-besan',
 'cat_liquid':'g-water', 'cat_sweetener':'g-jaggery', 'cat_herb':'g-sprig',
 'cat_meat':'i-curry', 'cat_seafood':'i-soup', 'cat_other':'i-curry',
}

OUT = 'assets/ing'
os.makedirs(OUT, exist_ok=True)
written = set()

def emit(key, vb, body):
    open(f'{OUT}/{key}.svg', 'w', encoding='utf-8').write(
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}">{body}</svg>')
    written.add(key)

for sym, variants in FAMILY.items():
    vb, body = ING[sym]
    for key, (p1, p2) in variants.items():
        b = re.sub(r'var\(--p1,[^)]*\)', p1, body)
        b = re.sub(r'var\(--p2,[^)]*\)', p2, b)
        emit(key, vb, b)

for key, sym in DIRECT.items():
    src = ING.get(sym) or DISH.get(sym)
    if not src:
        print("  !! missing drawing for", sym); continue
    vb, body = src
    body = re.sub(r'var\(--p1,([^)]*)\)', r'\1', body)
    body = re.sub(r'var\(--p2,([^)]*)\)', r'\1', body)
    body = re.sub(r'var\(--ill2,([^)]*)\)', r'\1', body)
    body = body.replace('currentColor', '#8E867E')
    emit(key, vb, body)

print("assets written:", len(written))
json.dump(sorted(written), open('written_keys.json','w',encoding='utf-8'))
