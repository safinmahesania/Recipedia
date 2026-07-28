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

# The cuisine categories exist but are nearly empty — "American recipes" holds
# two pages. The actual corpus is Category:Recipes, thousands of entries with no
# cuisine label. So: take everything, then infer cuisine from each page's own
# categories, and leave it null when there is no signal rather than guessing.
ROOT_CATEGORY = "Category:Recipes"

# Substring -> cuisine. Matched against every category a page belongs to.
CUISINE_SIGNALS = [
    ("american", "American"), ("united states", "American"),
    ("canadian", "Canadian"),
    ("french", "French"),
    ("indian", "Indian"), ("india", "Indian"),
    ("pakistani", "Pakistani"),
    ("bangladeshi", "Bangladeshi"),
    ("sri lankan", "Sri Lankan"),
    ("british", "British"), ("english", "British"),
    ("italian", "Italian"), ("mexican", "Mexican"), ("chinese", "Chinese"),
    ("japanese", "Japanese"), ("thai", "Thai"), ("greek", "Greek"),
    ("spanish", "Spanish"), ("german", "German"),
]

INGREDIENT_HEADINGS = ("ingredients", "ingredient")
METHOD_HEADINGS = ("procedure", "directions", "method", "preparation",
                   "instructions", "steps")

MIN_INGREDIENTS = 3
MIN_STEPS = 2


def api(params, tries=4):
    """One call, with backoff that actually waits.

    Wikimedia returns 429 and expects you to slow down. The previous version
    made one request per page and got blocked; this one batches 50 titles per
    request, which is a 50x reduction and the difference between working and
    being rate limited.
    """
    params = {**params, "format": "json", "formatversion": "2"}
    url = f"{API}?{urllib.parse.urlencode(params)}"
    for attempt in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=45) as r:
                return json.loads(r.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < tries - 1:
                wait = 10 * (attempt + 1)
                print(f"    429 — waiting {wait}s")
                time.sleep(wait)
                continue
            raise
        except Exception:
            if attempt == tries - 1:
                raise
            time.sleep(3 * (attempt + 1))
    return {}


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
    r"\b(finely|roughly|freshly|thinly|coarsely|lightly|well|very|extra|"
    r"chopped|sliced|diced|minced|grated|ground|crushed|peeled|washed|"
    r"drained|rinsed|beaten|melted|softened|cooled|warmed|toasted|roasted|"
    r"boiled|cooked|uncooked|raw|frozen|canned|tinned|bottled|packed|"
    r"optional|to taste|for garnish|for serving|as needed|plus more|divided|"
    r"large|small|medium|jumbo|ripe|unripe|fresh|dried|whole|halved|quartered|"
    r"boneless|skinless|trimmed|deveined|shelled|unsalted|salted|low.fat|"
    r"reduced.fat|full.fat|semi.skimmed|skimmed|plain|pure|good.quality|"
    r"organic|free.range|room temperature|at room temperature|thawed|"
    r"approximately|about|roughly|preferably|ideally|store.bought|homemade|"
    r"squeezed|sifted|shredded|julienned|cubed|quartered|mashed|pureed|"
    r"strained|separated|whisked|stiff|firm|soft|hot|cold|warm|"
    r"good|best|quality|any|some)\b",
    re.I)

# Everything after one of these is a note, not part of the name.
TRAILING_NOTE = re.compile(
    r"\s*(?:,|;|\bor\b|\bplus\b|\bfor\b|\bto\b\s+(?:taste|serve|garnish)|"
    r"\bsuch as\b|\bpreferably\b|\bif\b|\bcut into\b|\bbroken into\b).*$",
    re.I)

# Wikibooks writes "a can of X", "juice of 2 lemons", "handful of Y".
OF_PHRASE = re.compile(
    r"^(?:a |an |the )?(?:can|tin|jar|packet|pack|bottle|box|bag|bunch|"
    r"handful|pinch|dash|splash|sprig|clove|stick|piece|slice|head|"
    r"juice|zest|rind|peel)s?\s+of\s+", re.I)

IRREGULAR = {
    "leaves": "leaf", "loaves": "loaf", "knives": "knife",
    "potatoes": "potato", "tomatoes": "tomato", "mangoes": "mango",
    "chillies": "chilli", "berries": "berry", "cherries": "cherry",
    "anchovies": "anchovy", "peas": "peas", "molasses": "molasses",
}


def singular(word):
    if word in IRREGULAR:
        return IRREGULAR[word]
    # Words that end in s but are not plural.
    if word.endswith(("ss", "us", "is", "os")) or len(word) < 4:
        return word
    if word.endswith("ies"):
        return word[:-3] + "y"
    if word.endswith("es") and word[-3:-2] in "sxzo":
        return word[:-2]
    if word.endswith("s"):
        return word[:-1]
    return word


def singularise(name):
    return " ".join(singular(w) for w in name.split())


# "a pinch of saffron", "a handful of coriander" — no digits, still a quantity.
WORD_QUANTITY = re.compile(
    r"^\s*(a |an )?(pinch|handful|dash|splash|few|couple|sprig|bunch)"
    r"(?:es|s)?\s+(?:of\s+)?(.*)$", re.I)


class Canonicaliser:
    """Maps a cleaned phrase onto an ingredient you already have.

    Cleaning alone is not enough. "coriander leaf" is a perfectly good
    normalisation and still wrong, because the catalogue calls it "coriander
    leaves" — a new row would be created for something that already exists.

    So: normalise both sides for comparison, but always emit YOUR name. Falls
    back to the longest known name appearing as a whole word, which folds
    "boneless chicken breast" onto "chicken" rather than minting a third
    variation of it.
    """

    def __init__(self, known):
        self.exact = {}
        for name in known:
            self.exact.setdefault(name, name)
            self.exact.setdefault(singularise(name), name)
        # longest first, so "chicken breast" beats "chicken" when both exist
        self.by_length = sorted(self.exact, key=len, reverse=True)

    def resolve(self, name):
        if not name:
            return None
        if name in self.exact:
            return self.exact[name]
        sing = singularise(name)
        if sing in self.exact:
            return self.exact[sing]
        for known in self.by_length:
            if len(known) < 4:
                continue
            if re.search(rf"\b{re.escape(known)}\b", name):
                return self.exact[known]
        return name          # genuinely new


def clean_name(rest):
    """Reduce an ingredient phrase to a name that will collapse with others.

    The previous version produced 3664 distinct names from 1151 recipes —
    roughly one unique string per line, which defeats the point. Most of that
    was preparation notes and plurals surviving: "finely chopped tomatoes",
    "tomatoes, chopped" and "ripe tomato" were three ingredients.
    """
    n = rest.lower()
    n = re.sub(r"\(.*?\)", " ", n)          # parentheticals
    n = OF_PHRASE.sub("", n)                 # "a can of tomatoes"
    n = re.sub(r"^of\s+", "", n)              # QUANTITY already ate "1 can"
    n = TRAILING_NOTE.sub("", n)             # ", finely chopped"
    n = DESCRIPTORS.sub(" ", n)
    n = re.sub(r"[^a-z\s-]", " ", n)         # digits, symbols, fractions
    n = re.sub(r"\s+", " ", n).strip(" -")
    n = singularise(n)
    return n.strip()


def split_ingredient(line):
    wq = WORD_QUANTITY.match(line)
    if wq:
        return f"a {wq.group(2).lower()}", clean_name(wq.group(3))

    m = QUANTITY.match(line)
    qty, rest = (m.group(1).strip(), m.group(2).strip()) if m else ("", line)
    return qty or None, clean_name(rest)


def fetch_pages(category, cap):
    """Page titles in a category, following continuation."""
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
        time.sleep(1)
    return pages[:cap]


def fetch_subcategories(category):
    data = api({"action": "query", "list": "categorymembers",
                "cmtitle": category, "cmlimit": "500", "cmtype": "subcat"})
    return [m["title"] for m in data.get("query", {}).get("categorymembers", [])]


def cuisine_from_categories(cats):
    joined = " | ".join(c.lower() for c in cats)
    for needle, cuisine in CUISINE_SIGNALS:
        if needle in joined:
            return cuisine
    return None


def fetch_batch(titles):
    """Content AND categories for up to 50 pages in a single request.

    The old version made one call per page. That is what triggered the 429s,
    and it is also just slow: 2000 pages went from 2000 requests to 40.
    """
    data = api({
        "action": "query",
        "titles": "|".join(titles),
        "prop": "revisions|categories",
        "rvprop": "content",
        "rvslots": "main",
        "cllimit": "max",
    })
    out = {}
    for page in data.get("query", {}).get("pages", []):
        if page.get("missing"):
            continue
        revs = page.get("revisions") or []
        content = ""
        if revs:
            content = revs[0].get("slots", {}).get("main", {}).get("content", "")
        cats = [c["title"] for c in (page.get("categories") or [])]
        out[page["title"]] = (content, cats)
    return out


def parse_page(title, wikitext, categories, canon=None):
    raw_ings = bullets(section(wikitext, INGREDIENT_HEADINGS))
    steps = bullets(section(wikitext, METHOD_HEADINGS))
    if len(raw_ings) < MIN_INGREDIENTS:
        return None, f"{len(raw_ings)} ingredients"
    if len(steps) < MIN_STEPS:
        return None, f"{len(steps)} steps"

    parsed = []
    for line in raw_ings:
        qty, name = split_ingredient(line)
        if canon:
            name = canon.resolve(name)
        if name and len(name) > 1:
            parsed.append((name, qty))
    if not parsed:
        return None, "no parseable ingredients"

    return {
        "title": re.sub(r"^Cookbook:", "", title),
        "cuisine": cuisine_from_categories(categories),
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
    ap.add_argument("--limit", type=int, default=1500,
                    help="max recipe pages to fetch in total")
    ap.add_argument("--emit-sql", action="store_true")
    ap.add_argument("--existing", default="out/existing_ingredients.txt")
    ap.add_argument("--resume", action="store_true",
                    help="reuse out/wikibooks_raw.json instead of refetching")
    args = ap.parse_args()
    OUT.mkdir(exist_ok=True)

    raw_path = OUT / "wikibooks_raw.json"

    if args.resume and raw_path.exists():
        raw = json.loads(raw_path.read_text(encoding="utf-8"))
        print(f"  resumed {len(raw)} pages from {raw_path}")
    else:
        print(f"  listing {ROOT_CATEGORY} ...")
        titles = fetch_pages(ROOT_CATEGORY, args.limit)
        # The root holds recipes directly and also groups them by course.
        for sub in fetch_subcategories(ROOT_CATEGORY):
            if len(titles) >= args.limit:
                break
            titles += fetch_pages(sub, args.limit - len(titles))
            time.sleep(1)
        titles = list(dict.fromkeys(titles))[:args.limit]
        print(f"  {len(titles)} recipe pages found\n")

        raw = {}
        for i in range(0, len(titles), 50):
            chunk = titles[i:i + 50]
            try:
                raw.update(fetch_batch(chunk))
            except Exception as e:
                print(f"    batch {i//50 + 1} failed: {e}")
            done = min(i + 50, len(titles))
            print(f"    fetched {done}/{len(titles)}")
            # Fetching is the expensive part and 429s cost ten seconds each.
            # Saving as we go means a failure never means starting over.
            raw_path.write_text(json.dumps(raw), encoding="utf-8")
            time.sleep(1.2)
        print()

    known = set()
    ep = pathlib.Path(args.existing)
    if ep.exists():
        known = {l.strip().lower() for l in
                 ep.read_text(encoding="utf-8").splitlines() if l.strip()}
        print(f"  resolving against {len(known)} known ingredient names\n")
    else:
        print(f"  WARNING: {args.existing} missing — every ingredient will look")
        print("  new. Run tools/export_ingredients.py first.\n")
    canon = Canonicaliser(known)

    kept, rejected = [], []
    for title, (wikitext, cats) in raw.items():
        recipe, why = parse_page(title, wikitext, cats, canon)
        (kept if recipe else rejected).append(recipe or (title, why))

    by_cuisine = {}
    for r in kept:
        by_cuisine[r["cuisine"] or "(unlabelled)"] = \
            by_cuisine.get(r["cuisine"] or "(unlabelled)", 0) + 1

    print(f"  kept {len(kept)} / rejected {len(rejected)}\n")
    for c, n in sorted(by_cuisine.items(), key=lambda x: -x[1]):
        print(f"    {c:16s} {n:4d}")
    unlabelled = by_cuisine.get("(unlabelled)", 0)
    if unlabelled:
        print(f"\n  {unlabelled} have no cuisine signal in their categories.")
        print("  They still import — cuisine is nullable — and this is exactly")
        print("  what the auto-tagging classifier (backlog #4) is for.")
    print()

    with open(OUT / "wikibooks_rejected.csv", "w", newline="", encoding="utf-8") as f:
        csv.writer(f).writerows([("title", "reason"), *rejected])

    new = {}
    for r in kept:
        for name, _ in r["ingredients"]:
            if name not in known:
                new[name] = new.get(name, 0) + 1

    with open(OUT / "new_ingredients.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["name", "uses", "action"])
        for name, n in sorted(new.items(), key=lambda x: -x[1]):
            w.writerow([name, n, "create" if n >= 3 else "skip"])
    total_mentions = sum(len(r["ingredients"]) for r in kept)
    kept_names = {n for n, _ in ((n, q) for r in kept for n, q in r["ingredients"])}
    will_create = {n for n, c in new.items() if c >= 3}
    resolvable = known | will_create
    covered = sum(1 for r in kept for n, _ in r["ingredients"] if n in resolvable)
    avg_before = total_mentions / max(len(kept), 1)
    avg_after = covered / max(len(kept), 1)

    print(f"  new ingredients: {len(new)} -> out/new_ingredients.csv")
    print(f"    of which used 3+ times (default create): {len(will_create)}")
    print()
    print("  COVERAGE — this is the number that decides whether scan works")
    print(f"    distinct ingredient names used : {len(kept_names)}")
    print(f"    ingredient mentions            : {total_mentions}")
    print(f"    mentions that will survive     : {covered} "
          f"({100*covered/max(total_mentions,1):.1f}%)")
    print(f"    avg ingredients per recipe     : {avg_before:.1f} parsed, "
          f"{avg_after:.1f} after skips")
    if avg_after < 4:
        print()
        print("    WARNING: under 4 ingredients per recipe after filtering.")
        print("    Recipes that thin will not match anything useful in scan.")
        print("    Lower the skip threshold or improve normalisation before")
        print("    importing.")
    print()

    with open(OUT / "wikibooks_review.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["title", "cuisine", "ingredients", "steps", "url"])
        for r in kept:
            w.writerow([r["title"], r["cuisine"] or "", len(r["ingredients"]),
                        len(r["steps"]), r["source_url"]])
    (OUT / "wikibooks_recipes.json").write_text(json.dumps(kept, indent=2), encoding="utf-8")
    print(f"  review -> out/wikibooks_review.csv")

    if not args.emit_sql:
        print("\n  Dry run. Re-run with --emit-sql --resume once the CSVs look right")
        print("  (--resume avoids refetching everything).")
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
        pairs = [(n, q) for n, q in r["ingredients"] if n in keep_ing or n in known]
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
    from datetime import datetime
    stamp = datetime.now().strftime("%Y%m%d%H%M%S")
    (OUT / f"{stamp}_import_wikibooks.sql").write_text(sql, encoding="utf-8")
    print(f"\n  SQL -> out/import_wikibooks.sql  ({len(kept)} recipes)")


if __name__ == "__main__":
    main()
