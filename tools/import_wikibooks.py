"""Imports recipes from Wikibooks Cookbook.

WHY THIS SOURCE
---------------
CC BY-SA 3.0 — genuinely redistributable, including commercially, forever. It
is the only sizeable recipe corpus that is free, legally clean AND storable in
your own database, which matters because match_recipes_for_user is a Postgres
function over local tables and cannot run against a remote API.

THE OBLIGATION
--------------
Share-alike is not "free to use". Every recipe must carry its origin and that
origin must be VISIBLE in the app — hence recipes.source_name / source_url /
license, and the attribution line on the detail screen. Importing without
displaying it is a licence breach, not a missing nicety.

THE HONEST CATCH
----------------
This is wikitext written by volunteers over twenty years. There is no schema.
Some pages are immaculate; some are a paragraph of prose; some are stubs with
a title and nothing else. The parser below rejects far more than it accepts,
which is correct — a recipe with no ingredients list is not a recipe.

Expect to keep roughly a third of what you fetch.

USAGE
-----
    python tools/import_wikibooks.py --limit 300
    # review out/wikibooks_review.csv and out/new_ingredients.csv
    python tools/import_wikibooks.py --limit 300 --emit-sql
"""

import argparse
import csv
import json
import pathlib
import re
import time
import urllib.parse
import urllib.request

API = "https://en.wikibooks.org/w/api.php"
UA = "Recipedia-Importer/1.0 (student project; contact via GitHub)"
OUT = pathlib.Path("out")

# Wikibooks category -> the cuisine string stored on recipes.cuisine
CATEGORIES = {
    "Category:American recipes": "American",
    "Category:Canadian recipes": "Canadian",
    "Category:French recipes": "French",
    "Category:Indian recipes": "Indian",
    "Category:Pakistani recipes": "Pakistani",
    "Category:Bangladeshi recipes": "Bangladeshi",
    "Category:Sri Lankan recipes": "Sri Lankan",
}

INGREDIENT_HEADINGS = ("ingredients", "ingredient")
METHOD_HEADINGS = ("procedure", "directions", "method", "preparation",
                   "instructions", "steps")

MIN_INGREDIENTS = 3
MIN_STEPS = 2


def api(params):
    params = {**params, "format": "json", "formatversion": "2"}
    url = f"{API}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode())


def strip_markup(text):
    """Wikitext to plain text. Order matters — templates first, they nest."""
    text = re.sub(r"\{\{[^{}]*\}\}", "", text)          # {{templates}}
    text = re.sub(r"\{\{[^{}]*\}\}", "", text)          # nested, second pass
    text = re.sub(r"\[\[([^\]|]*)\|([^\]]*)\]\]", r"\2", text)   # [[a|b]] -> b
    text = re.sub(r"\[\[([^\]]*)\]\]", r"\1", text)              # [[a]]   -> a
    text = re.sub(r"\[https?://\S+\s+([^\]]*)\]", r"\1", text)   # ext links
    text = re.sub(r"</?ref[^>]*>.*?</ref>", "", text, flags=re.S)
    text = re.sub(r"<[^>]+>", "", text)                          # html
    text = re.sub(r"'''?([^']*)'''?", r"\1", text)               # bold/italic
    text = re.sub(r"&nbsp;", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def section(wikitext, headings):
    """Body of the first == Heading == matching, up to the next heading."""
    for h in headings:
        m = re.search(rf"^=+\s*{h}\s*=+\s*$(.*?)(?=^=+[^=]+=+\s*$|\Z)",
                      wikitext, re.I | re.M | re.S)
        if m:
            return m.group(1)
    return ""


def bullets(block):
    out = []
    for line in block.split("\n"):
        line = line.strip()
        if not re.match(r"^[*#]+\s*", line):
            continue
        # Nested bullets are usually sub-notes, not separate items.
        if re.match(r"^[*#]{2,}", line):
            continue
        cleaned = strip_markup(re.sub(r"^[*#]+\s*", "", line))
        if len(cleaned) > 1:
            out.append(cleaned)
    return out


# "1 cup finely chopped onions" -> ("1 cup", "onions")
# The unit group needs a word boundary after it, or the single-letter units
# match inside words: "3 large eggs" was parsing as qty "3 l", name "arge eggs".
# Longer alternatives are listed first so "tablespoons" wins over "tbsp".
QUANTITY = re.compile(
    r"^\s*(\d+[\d\s/¼½¾⅓⅔⅛.-]*"
    r"(?:\s*(?:tablespoons?|teaspoons?|kilograms?|kilos?|litres?|liters?|"
    r"grams?|ounces?|pounds?|pinch(?:es)?|cloves?|pieces?|sprigs?|cans?|"
    r"packets?|slices?|bunch(?:es)?|cups?|tbsp|tsp|kg|ml|oz|lb|g|l)\b)?)"
    r"\s*(.*)$", re.I)

DESCRIPTORS = re.compile(
    r"\b(finely|roughly|freshly|thinly|coarsely|chopped|sliced|diced|minced|"
    r"grated|ground|crushed|peeled|washed|drained|rinsed|optional|to taste|"
    r"for garnish|as needed|large|small|medium|ripe|fresh|dried|whole)\b", re.I)


# "a pinch of saffron", "a handful of coriander" — no digits, still a quantity.
WORD_QUANTITY = re.compile(
    r"^\s*(a |an )?(pinch|handful|dash|splash|few|couple|sprig|bunch)"
    r"(?:es|s)?\s+(?:of\s+)?(.*)$", re.I)


def split_ingredient(line):
    wq = WORD_QUANTITY.match(line)
    if wq:
        qty = f"a {wq.group(2).lower()}"
        rest = wq.group(3)
        name = DESCRIPTORS.sub("", rest)
        name = re.sub(r"\(.*?\)", "", name)
        name = re.sub(r"[,;].*$", "", name)
        name = re.sub(r"\s+", " ", name).strip(" ,.-").lower()
        return qty, name

    m = QUANTITY.match(line)
    qty, rest = (m.group(1).strip(), m.group(2).strip()) if m else ("", line)
    name = DESCRIPTORS.sub("", rest)
    name = re.sub(r"\(.*?\)", "", name)
    name = re.sub(r"[,;].*$", "", name)          # drop trailing notes
    name = re.sub(r"\s+", " ", name).strip(" ,.-").lower()
    return qty or None, name


def fetch_pages(category, cap):
    pages, cont = [], None
    while len(pages) < cap:
        params = {"action": "query", "list": "categorymembers",
                  "cmtitle": category, "cmlimit": "500", "cmtype": "page"}
        if cont:
            params["cmcontinue"] = cont
        data = api(params)
        pages += [m["title"] for m in data.get("query", {}).get("categorymembers", [])]
        cont = data.get("continue", {}).get("cmcontinue")
        if not cont:
            break
    return pages[:cap]


def fetch_recipe(title, cuisine):
    data = api({"action": "parse", "page": title, "prop": "wikitext"})
    wt = data.get("parse", {}).get("wikitext", "")
    if not wt:
        return None, "no wikitext"

    raw_ings = bullets(section(wt, INGREDIENT_HEADINGS))
    steps = bullets(section(wt, METHOD_HEADINGS))
    if len(raw_ings) < MIN_INGREDIENTS:
        return None, f"only {len(raw_ings)} ingredients"
    if len(steps) < MIN_STEPS:
        return None, f"only {len(steps)} steps"

    parsed = []
    for line in raw_ings:
        qty, name = split_ingredient(line)
        if name:
            parsed.append((name, qty))

    display = re.sub(r"^Cookbook:", "", title)
    return {
        "title": display,
        "cuisine": cuisine,
        "ingredients": parsed,
        "steps": steps,
        "source_name": "Wikibooks Cookbook",
        "source_url": "https://en.wikibooks.org/wiki/" +
                      urllib.parse.quote(title.replace(" ", "_")),
        "license": "CC BY-SA 3.0",
    }, None


def sql_str(v):
    return "NULL" if not v else "'" + str(v).replace("'", "''") + "'"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=200,
                    help="max pages to try PER CUISINE")
    ap.add_argument("--emit-sql", action="store_true")
    ap.add_argument("--existing", default="out/existing_ingredients.txt")
    args = ap.parse_args()
    OUT.mkdir(exist_ok=True)

    kept, rejected = [], []
    for category, cuisine in CATEGORIES.items():
        try:
            titles = fetch_pages(category, args.limit)
        except Exception as e:
            print(f"  {cuisine:12s} category unavailable ({e})")
            continue
        ok = 0
        for t in titles:
            try:
                recipe, why = fetch_recipe(t, cuisine)
            except Exception as e:
                recipe, why = None, str(e)[:40]
            if recipe:
                kept.append(recipe); ok += 1
            else:
                rejected.append((t, cuisine, why))
            time.sleep(0.12)          # Wikimedia asks for courteous rates
        print(f"  {cuisine:12s} {ok:3d} kept / {len(titles):3d} pages")

    print(f"\n  kept {len(kept)}, rejected {len(rejected)}")
    print("  Rejections are mostly stubs and prose pages with no ingredient")
    print("  list. That filter is doing its job.\n")

    with open(OUT / "wikibooks_rejected.csv", "w", newline="", encoding="utf-8") as f:
        csv.writer(f).writerows([("title", "cuisine", "reason"), *rejected])

    known = set()
    p = pathlib.Path(args.existing)
    if p.exists():
        known = {l.strip().lower() for l in p.read_text(encoding="utf-8").splitlines() if l.strip()}

    new = {}
    for r in kept:
        for name, _ in r["ingredients"]:
            if name not in known:
                new[name] = new.get(name, 0) + 1

    with open(OUT / "new_ingredients.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["name", "uses", "action"])
        for name, n in sorted(new.items(), key=lambda x: -x[1]):
            w.writerow([name, n, "create" if n >= 2 else "skip"])
    print(f"  new ingredients: {len(new)} -> out/new_ingredients.csv")
    print("    single-use names default to skip — they are usually parser noise")
    print("    ('and', 'to serve') rather than real ingredients.\n")

    with open(OUT / "wikibooks_review.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["title", "cuisine", "ingredients", "steps", "url"])
        for r in kept:
            w.writerow([r["title"], r["cuisine"], len(r["ingredients"]),
                        len(r["steps"]), r["source_url"]])
    (OUT / "wikibooks_recipes.json").write_text(json.dumps(kept, indent=2), encoding="utf-8")
    print(f"  review -> out/wikibooks_review.csv")

    if not args.emit_sql:
        print("\n  Dry run. Re-run with --emit-sql once the CSVs look right.")
        return

    keep_ing = set()
    with open(OUT / "new_ingredients.csv", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            if row["action"].strip().lower() != "skip":
                keep_ing.add(row["name"])

    lines = ["-- Generated by tools/import_wikibooks.py. Review before running.",
             "begin;", "", "-- 1. new ingredients"]
    for n in sorted(keep_ing):
        lines.append(f"insert into public.ingredients (name, is_pantry) "
                     f"values ({sql_str(n)}, false) on conflict (name) do nothing;")

    lines += ["", "-- 2. recipes, with attribution as CC BY-SA requires"]
    for r in kept:
        pairs = [(n, q) for n, q in r["ingredients"]]
        if not pairs:
            continue
        values = ",\n".join(f"  ({sql_str(n)}, {sql_str(q)})" for n, q in pairs)
        lines.append(f"""
with ins as (
  insert into public.recipes
    (title, instructions, cuisine, status, author_id,
     source_name, source_url, license)
  select {sql_str(r['title'])}, {sql_str(chr(10).join(r['steps']))},
         {sql_str(r['cuisine'])}, 'approved',
         (select id from public.profiles where role = 'admin'
          order by created_at limit 1),
         {sql_str(r['source_name'])}, {sql_str(r['source_url'])},
         {sql_str(r['license'])}
  where not exists (
    select 1 from public.recipes where lower(title) = lower({sql_str(r['title'])}))
  returning id
)
insert into public.recipe_ingredients (recipe_id, ingredient_id, role, quantity)
select ins.id, i.id, 'core', v.qty
from ins
join (values
{values}
) as v(name, qty) on true
join public.ingredients i on lower(i.name) = v.name
on conflict (recipe_id, ingredient_id) do nothing;""")

    lines += ["", "commit;"]
    sql = "\n".join(lines)
    (OUT / "import_wikibooks.sql").write_text(sql, encoding="utf-8")

    # Also written as a migration, because psql is not installed on Windows by
    # default and `supabase db push` already works. Move this file into
    # supabase/migrations/ and push it.
    from datetime import datetime
    stamp = datetime.now().strftime("%Y%m%d%H%M%S")
    (OUT / f"{stamp}_import_wikibooks.sql").write_text(sql, encoding="utf-8")
    print(f"\n  SQL -> out/import_wikibooks.sql  ({len(kept)} recipes)")


if __name__ == "__main__":
    main()
