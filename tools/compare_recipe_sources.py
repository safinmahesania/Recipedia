"""Pulls two real recipes from each candidate source and prints them the same way.

I could not run this from my sandbox — outbound network is restricted — so
rather than describe what these APIs return, this fetches it. Run it and judge
the actual data.

    python tools/compare_recipe_sources.py                    # TheMealDB only
    SPOONACULAR_KEY=... EDAMAM_ID=... EDAMAM_KEY=... python tools/compare_recipe_sources.py

Everything is normalised into the same shape, so the comparison is about the
data and not about whose JSON is prettier.
"""

import json
import os
import textwrap
import urllib.parse
import urllib.request

W = 78


def get(url, headers=None):
    req = urllib.request.Request(url, headers=headers or {})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode())


def show(source, r):
    print("=" * W)
    print(f"  SOURCE      {source}")
    print(f"  TITLE       {r['title']}")
    print(f"  CUISINE     {r.get('cuisine') or '(none supplied)'}")
    print(f"  IMAGE       {'yes -> ' + r['image'][:52] if r.get('image') else 'NO IMAGE'}")
    print(f"  INGREDIENTS {len(r['ingredients'])} "
          f"({'structured' if r['structured'] else 'free text, needs parsing'})")
    for line in r["ingredients"][:6]:
        print(f"                - {line}")
    if len(r["ingredients"]) > 6:
        print(f"                  ... {len(r['ingredients']) - 6} more")
    steps = r.get("steps") or []
    print(f"  STEPS       {len(steps) if steps else 'one blob, needs splitting'}")
    if steps:
        print(textwrap.fill(steps[0], W - 16,
                            initial_indent="                1. ",
                            subsequent_indent="                   "))
    print(f"  LICENCE     {r['licence']}")
    print()


# ----------------------------------------------------------------- TheMealDB
def themealdb():
    out = []
    for area in ("American", "French"):
        listing = get("https://www.themealdb.com/api/json/v1/1/filter.php?a="
                      + urllib.parse.quote(area))
        meal_id = listing["meals"][0]["idMeal"]
        m = get(f"https://www.themealdb.com/api/json/v1/1/lookup.php?i={meal_id}")["meals"][0]
        ings = []
        for i in range(1, 21):
            n = (m.get(f"strIngredient{i}") or "").strip()
            q = (m.get(f"strMeasure{i}") or "").strip()
            if n:
                ings.append(f"{q} {n}".strip())
        blob = (m.get("strInstructions") or "").strip()
        steps = [s.strip() for s in blob.split("\n") if s.strip()]
        out.append({
            "title": m["strMeal"], "cuisine": m.get("strArea"),
            "image": m.get("strMealThumb"), "ingredients": ings,
            "structured": True, "steps": steps if len(steps) > 1 else [],
            "licence": "free to use; attribution requested, supporter key for commercial",
        })
    return out


# ---------------------------------------------------------------- Spoonacular
def spoonacular(key):
    out = []
    for cuisine in ("American", "French"):
        res = get("https://api.spoonacular.com/recipes/complexSearch"
                  f"?cuisine={cuisine}&number=1&addRecipeInformation=true"
                  f"&fillIngredients=true&apiKey={key}")
        for r in res.get("results", []):
            ings = [f"{i.get('amount','')} {i.get('unit','')} {i.get('name','')}".strip()
                    for i in r.get("extendedIngredients", [])]
            steps = []
            for block in r.get("analyzedInstructions", []):
                steps += [s["step"] for s in block.get("steps", [])]
            out.append({
                "title": r["title"], "cuisine": ", ".join(r.get("cuisines") or []),
                "image": r.get("image"), "ingredients": ings,
                "structured": True, "steps": steps,
                "licence": "free dev tier; PAID licence required for production",
            })
    return out


# --------------------------------------------------------------------- Edamam
def edamam(app_id, app_key):
    out = []
    for cuisine in ("american", "french"):
        res = get("https://api.edamam.com/api/recipes/v2?type=public"
                  f"&cuisineType={cuisine}&app_id={app_id}&app_key={app_key}",
                  headers={"Edamam-Account-User": app_id})
        for hit in res.get("hits", [])[:1]:
            r = hit["recipe"]
            out.append({
                "title": r["label"],
                "cuisine": ", ".join(r.get("cuisineType") or []),
                "image": r.get("image"),
                "ingredients": r.get("ingredientLines", []),
                "structured": False,
                "steps": [],
                "licence": "attribution + link back to publisher REQUIRED; "
                           "no instructions returned",
            })
    return out


def main():
    print("\nFetching two recipes per source. Same shape, so compare the data.\n")

    try:
        for r in themealdb():
            show("TheMealDB", r)
    except Exception as e:
        print(f"  TheMealDB failed: {e}\n")

    key = os.environ.get("SPOONACULAR_KEY")
    if key:
        try:
            for r in spoonacular(key):
                show("Spoonacular", r)
        except Exception as e:
            print(f"  Spoonacular failed: {e}\n")
    else:
        print("  Spoonacular skipped — set SPOONACULAR_KEY (free key at "
              "spoonacular.com/food-api)\n")

    eid, ekey = os.environ.get("EDAMAM_ID"), os.environ.get("EDAMAM_KEY")
    if eid and ekey:
        try:
            for r in edamam(eid, ekey):
                show("Edamam", r)
        except Exception as e:
            print(f"  Edamam failed: {e}\n")
    else:
        print("  Edamam skipped — set EDAMAM_ID and EDAMAM_KEY (free dev tier at "
              "developer.edamam.com)\n")

    print("=" * W)
    print("""
  WHAT TO LOOK FOR

  Instructions      Edamam returns none at all — it links to the publisher
                    instead. That rules it out on its own: a recipe app that
                    cannot show you how to cook is not a recipe app.

  Ingredient shape  "structured" drops into recipe_ingredients directly.
                    "free text" means parsing "2 large onions, finely sliced"
                    into name + quantity, which is its own project.

  Image licence     You already have an unresolved photography question. Read
                    what each licence actually permits before importing.
""")


if __name__ == "__main__":
    main()
