"""Imports recipes from TheMealDB into Recipedia's schema.

WHY THIS SOURCE
---------------
A public API meant to be consumed, not a site being scraped. That matters for
three reasons beyond ethics: the ingredient lists are already structured
(strIngredient1..20 with matching measures), every meal carries an `area` that
maps to cuisine, and the images come with a licence you can actually use — which
is the one blocker photography has been stuck behind.

Scraping Allrecipes or Food Network would give more rows and a copyright problem
attached to every one of them.

WHAT IT DOES NOT DO
-------------------
Insert anything. It writes SQL for review. New cuisines drag in a few hundred
unfamiliar ingredients (parmesan, thyme, maple syrup) and blind-inserting them
would wreck the ingredient table that took five migrations to clean up. New
ingredients land in a separate file for you to check first.

USAGE
-----
    python tools/import_themealdb.py
    # review out/new_ingredients.csv, edit categories if needed
    python tools/import_themealdb.py --emit-sql
    psql "$DATABASE_URL" -f out/import_themealdb.sql
"""

import argparse
import csv
import json
import pathlib
import re
import time
import urllib.parse
import urllib.request

API = "https://www.themealdb.com/api/json/v1/1"

# TheMealDB area -> the cuisine string stored on recipes.cuisine
AREAS = {
    "American": "American",
    "Canadian": "Canadian",
    "French": "French",
    "Indian": "Indian",
    "Pakistani": "Pakistani",
}

OUT = pathlib.Path("out")

# Anything here makes a recipe non-vegetarian. Deliberately generous: calling a
# meat dish vegetarian is a real harm, calling a veg dish non-veg is an
# inconvenience, so the check errs toward non-veg.
MEAT = {
    "beef", "chicken", "pork", "lamb", "mutton", "bacon", "ham", "sausage",
    "turkey", "duck", "veal", "venison", "goat", "prawn", "shrimp", "fish",
    "salmon", "tuna", "cod", "haddock", "anchovy", "crab", "lobster", "squid",
    "mussels", "oyster", "gelatin", "lard", "clams", "scallops", "chorizo",
    "pepperoni", "salami", "pancetta", "prosciutto", "meat", "stock cube",
}
EGG = {"egg", "eggs", "egg yolk", "egg white", "mayonnaise"}

# Rough category guess for ingredients we have never seen. Reviewed by hand
# before insert — this only saves typing, it is not authoritative.
CATEGORY_HINTS = [
    (r"\b(chicken|beef|pork|lamb|mutton|bacon|ham|sausage|turkey|duck|veal)\b", "meat"),
    (r"\b(fish|salmon|tuna|cod|prawn|shrimp|crab|lobster|squid|mussel|oyster|anchov)\b", "seafood"),
    (r"\b(milk|cream|butter|cheese|yoghurt|yogurt|curd|paneer|ghee|mascarpone|parmesan|cheddar|mozzarella)\b", "dairy"),
    (r"\b(flour|rice|pasta|bread|oats|noodle|semolina|couscous|quinoa|barley|cornmeal)\b", "grain"),
    (r"\b(oil|olive oil|vegetable oil|sesame oil|sunflower oil)\b", "oil"),
    (r"\b(sugar|honey|syrup|jaggery|molasses|treacle)\b", "sweetener"),
    (r"\b(almond|cashew|walnut|pistachio|peanut|pecan|hazelnut|nuts)\b", "nut"),
    (r"\b(lentil|bean|chickpea|dal|pea|rajma|gram)\b", "legume"),
    (r"\b(basil|thyme|oregano|rosemary|parsley|coriander leaves|mint|sage|dill|chives)\b", "herb"),
    (r"\b(pepper|cumin|turmeric|paprika|cinnamon|clove|cardamom|nutmeg|masala|chilli powder|saffron)\b", "spice"),
    (r"\b(apple|banana|orange|lemon|lime|mango|berry|berries|grape|peach|pear|pineapple|cherry)\b", "fruit"),
    (r"\b(water|wine|stock|broth|vinegar|juice|beer|rum|brandy)\b", "liquid"),
]


def get(url, tries=3):
    """Retries with a growing pause.

    The free key throttles, and it does so by returning {"meals": null} with a
    200 rather than an error — so a rate limit is indistinguishable from "no
    results" unless you retry. Four of five areas came back empty on the first
    run for exactly this reason.
    """
    last = None
    for attempt in range(tries):
        try:
            req = urllib.request.Request(
                url, headers={"User-Agent": "Recipedia-Importer/1.0"})
            with urllib.request.urlopen(req, timeout=30) as r:
                data = json.loads(r.read().decode("utf-8"))
            if data.get("meals") is not None or "list.php" not in url:
                return data
        except Exception as e:
            last = e
        time.sleep(1.5 * (attempt + 1))
    if last:
        raise last
    return {"meals": None}


def normalise(raw):
    """TheMealDB names are already fairly clean; strip the noise that remains."""
    n = raw.lower().strip()
    n = re.sub(r"\(.*?\)", "", n)                       # "flour (plain)"
    n = re.sub(r"^(fresh|dried|ground|chopped|sliced|minced|whole|large|small)\s+", "", n)
    n = re.sub(r"\s+", " ", n).strip(" ,.")
    return n


def guess_category(name):
    for pattern, cat in CATEGORY_HINTS:
        if re.search(pattern, name):
            return cat
    return "other"


def parse_meal(meal, cuisine):
    ingredients = []
    for i in range(1, 21):
        name = (meal.get(f"strIngredient{i}") or "").strip()
        measure = (meal.get(f"strMeasure{i}") or "").strip()
        if not name:
            continue
        ingredients.append((normalise(name), measure))

    names = {n for n, _ in ingredients}
    blob = " ".join(names)
    if any(m in blob for m in MEAT):
        diet = "Non Vegetarian"
    elif any(e in names for e in EGG):
        diet = "Eggetarian"
    else:
        diet = "Vegetarian"

    # Instructions arrive as one blob. Splitting here means the app never has to
    # parse at render time, and the steps column stays authoritative.
    raw = (meal.get("strInstructions") or "").strip()
    steps = [s.strip() for s in re.split(r"\r?\n+", raw) if s.strip()]
    if len(steps) < 2:
        steps = [s.strip() for s in re.split(r"(?<=[.!?])\s+(?=[A-Z])", raw)
                 if len(s.strip()) > 3]
    steps = [re.sub(r"^(STEP\s*)?\d+[.):]?\s*", "", s, flags=re.I) for s in steps]

    return {
        "source_id": meal["idMeal"],
        "title": meal["strMeal"].strip(),
        "cuisine": cuisine,
        "category": (meal.get("strCategory") or "").strip(),
        "image_url": (meal.get("strMealThumb") or "").strip(),
        "diet": diet,
        "steps": steps,
        "ingredients": ingredients,
        "source_url": (meal.get("strSource") or "").strip(),
    }


def list_areas():
    """What the API actually offers. Run this when an area returns nothing —
    the free key does not serve every area, and the names must match exactly."""
    data = get(f"{API}/list.php?a=list")
    areas = [a["strArea"] for a in (data.get("meals") or [])]
    print(f"  API reports {len(areas)} areas:")
    print("   ", ", ".join(areas))
    missing = [a for a in AREAS if a not in areas]
    if missing:
        print(f"\n  requested but NOT offered: {missing}")
    return areas


def fetch_all():
    meals = []
    available = set(list_areas())
    print()
    for area, cuisine in AREAS.items():
        if area not in available:
            print(f"  {area:12s} skipped — not offered by this key")
            continue
        listing = get(f"{API}/filter.php?a={urllib.parse.quote(area)}")
        ids = [m["idMeal"] for m in (listing.get("meals") or [])]
        if not ids:
            # An empty list from an area the API claims to have usually means
            # throttling, not absence. Say so rather than reporting zero.
            print(f"  {area:12s}   0 meals  <- area exists but returned nothing"
                  f" after {3} tries. Re-run; the free key throttles hard.")
            continue
        print(f"  {area:12s} {len(ids):3d} meals")
        for mid in ids:
            detail = get(f"{API}/lookup.php?i={mid}")
            for meal in (detail.get("meals") or []):
                meals.append(parse_meal(meal, cuisine))
            time.sleep(0.6)           # the free key throttles; pace it
    return meals


def sql_str(v):
    return "NULL" if v is None or v == "" else "'" + str(v).replace("'", "''") + "'"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--emit-sql", action="store_true",
                    help="write the insert script; without it, only the review files")
    ap.add_argument("--existing", default="out/existing_ingredients.txt",
                    help="one canonical ingredient name per line, exported from your DB")
    args = ap.parse_args()

    OUT.mkdir(exist_ok=True)
    meals = fetch_all()
    print(f"\n  fetched {len(meals)} recipes")

    known = set()
    p = pathlib.Path(args.existing)
    if p.exists():
        known = {l.strip().lower() for l in p.read_text(encoding="utf-8").splitlines() if l.strip()}
        print(f"  known ingredients: {len(known)}")
    else:
        print(f"  no {args.existing} — every ingredient will be treated as new.\n"
              f"  Export first:  select name from ingredients order by name;")

    used, new = {}, {}
    for m in meals:
        for name, measure in m["ingredients"]:
            used.setdefault(name, 0)
            used[name] += 1
            if name not in known:
                new[name] = new.get(name, 0) + 1

    with open(OUT / "new_ingredients.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["name", "guessed_category", "uses", "action"])
        for name, count in sorted(new.items(), key=lambda x: -x[1]):
            w.writerow([name, guess_category(name), count, "create"])
    print(f"  new ingredients: {len(new)}  -> out/new_ingredients.csv")
    print("    review that file before importing. Set action=skip for anything")
    print("    that is a duplicate of an existing name under another spelling.")

    (OUT / "recipes.json").write_text(json.dumps(meals, indent=2), encoding="utf-8")
    print(f"  recipes -> out/recipes.json")

    if not args.emit_sql:
        print("\n  Dry run. Re-run with --emit-sql once the CSV looks right.")
        return

    keep = {}
    with open(OUT / "new_ingredients.csv", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            if row["action"].strip().lower() != "skip":
                keep[row["name"]] = row["guessed_category"]

    lines = [
        "-- Generated by tools/import_themealdb.py. Review before running.",
        "-- Wrapped in a transaction: a bad row rolls the whole import back",
        "-- rather than leaving the catalogue half-imported.",
        "begin;",
        "",
        "-- 1. ingredients that do not exist yet",
    ]
    for name, cat in sorted(keep.items()):
        lines.append(
            f"insert into public.ingredients (name, category, is_pantry) "
            f"values ({sql_str(name)}, {sql_str(cat)}, false) "
            f"on conflict (name) do nothing;")

    lines += ["", "-- 2. recipes, skipping any title already present"]
    for m in meals:
        instructions = "\n".join(m["steps"])
        lines.append(f"""
with ins as (
  insert into public.recipes (title, instructions, image_url, cuisine, diet, status, author_id)
  select {sql_str(m['title'])}, {sql_str(instructions)}, {sql_str(m['image_url'])},
         {sql_str(m['cuisine'])}, {sql_str(m['diet'])}, 'approved',
         (select id from public.profiles where role = 'admin' order by created_at limit 1)
  where not exists (select 1 from public.recipes where lower(title) = lower({sql_str(m['title'])}))
  returning id
)
insert into public.recipe_ingredients (recipe_id, ingredient_id, role, quantity)
select ins.id, i.id, 'core', v.measure
from ins
join (values
{chr(10).join(f"  ({sql_str(n)}, {sql_str(q)})," for n, q in m['ingredients'])[:-1]}
) as v(name, measure) on true
join public.ingredients i on lower(i.name) = v.name
on conflict (recipe_id, ingredient_id) do nothing;""")

    lines += ["", "commit;"]
    sql = "\n".join(lines)
    (OUT / "import_themealdb.sql").write_text(sql, encoding="utf-8")

    # Also written as a migration, because psql is not installed on Windows by
    # default and `supabase db push` already works. Move this file into
    # supabase/migrations/ and push it.
    from datetime import datetime
    stamp = datetime.now().strftime("%Y%m%d%H%M%S")
    (OUT / f"{stamp}_import_themealdb.sql").write_text(sql, encoding="utf-8")
    print(f"\n  SQL -> out/import_themealdb.sql")
    print("  Run it against a COPY of the database first.")


if __name__ == "__main__":
    main()
