"""Evaluates the Food.com Kaggle dataset against Recipedia's actual needs.

    shuyangli94/food-com-recipes-and-user-interactions
    RAW_recipes.csv        ~231k recipes
    RAW_interactions.csv   ~1.1M ratings

Run this before importing anything. It answers the only questions that matter:
how many usable recipes exist per target cuisine, and what is missing from them.

    pip install pandas
    python tools/evaluate_foodcom.py --dir path/to/dataset
"""

import argparse
import ast
import pathlib
import re

import pandas as pd

# Food.com tags carry cuisine, buried among a hundred other tags per recipe.
CUISINE_TAGS = {
    "american": "American",
    "north-american": "American",
    "canadian": "Canadian",
    "french": "French",
    "indian": "Indian",
    "pakistani": "Pakistani",
    "south-west-pacific": None,          # noise, listed so it is not matched
    "asian": None,
}
TARGET = {"American", "Canadian", "French", "Indian", "Pakistani"}

# A recipe with two steps and three ingredients is usually junk on Food.com —
# "combine and serve" style entries. These floors cut most of it.
MIN_STEPS = 3
MIN_INGREDIENTS = 4
MIN_RATINGS = 3


def parse_list(v):
    try:
        out = ast.literal_eval(v)
        return out if isinstance(out, list) else []
    except Exception:
        return []


def cuisine_of(tags):
    for t in tags:
        mapped = CUISINE_TAGS.get(t)
        if mapped:
            return mapped
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", required=True)
    ap.add_argument("--top", type=int, default=25,
                    help="how many best-rated per cuisine to export")
    args = ap.parse_args()

    d = pathlib.Path(args.dir)
    recipes = pd.read_csv(d / "RAW_recipes.csv")
    print(f"  loaded {len(recipes):,} recipes")

    recipes["tags_l"] = recipes["tags"].fillna("[]").map(parse_list)
    recipes["ingredients_l"] = recipes["ingredients"].fillna("[]").map(parse_list)
    recipes["steps_l"] = recipes["steps"].fillna("[]").map(parse_list)
    recipes["cuisine"] = recipes["tags_l"].map(cuisine_of)

    hit = recipes[recipes["cuisine"].isin(TARGET)].copy()
    print(f"  tagged with a target cuisine: {len(hit):,}\n")

    print(f"  {'cuisine':12s} {'tagged':>8s} {'usable':>8s}   (usable = "
          f">={MIN_STEPS} steps, >={MIN_INGREDIENTS} ingredients)")
    print("  " + "-" * 52)
    hit["usable"] = (hit["steps_l"].str.len() >= MIN_STEPS) & \
                    (hit["ingredients_l"].str.len() >= MIN_INGREDIENTS)
    for c in sorted(TARGET):
        sub = hit[hit["cuisine"] == c]
        print(f"  {c:12s} {len(sub):8,d} {int(sub['usable'].sum()):8,d}")
    print("  " + "-" * 52)
    print(f"  {'TOTAL':12s} {len(hit):8,d} {int(hit['usable'].sum()):8,d}\n")

    # ---- what is missing, stated plainly ----
    sample = hit.iloc[0] if len(hit) else None
    print("  WHAT THIS DATA DOES NOT HAVE")
    print("    images        : no column at all")
    print("    quantities    : ingredients are names only, no amounts")
    if sample is not None:
        print(f"                    e.g. {sample['ingredients_l'][:5]}")
        print(f"                    your recipe_ingredients.quantity would be NULL")
    print("    cook time     : present as `minutes` (numeric) — better than your"
          " free-text cook_time")
    print("    steps         : present as a real list — no parsing needed\n")

    # ---- ratings, if the interactions file is there ----
    inter_path = d / "RAW_interactions.csv"
    if inter_path.exists():
        inter = pd.read_csv(inter_path, usecols=["recipe_id", "rating"])
        agg = inter.groupby("recipe_id")["rating"].agg(["mean", "count"])
        hit = hit.join(agg, on="id")
        rated = hit[(hit["usable"]) & (hit["count"] >= MIN_RATINGS)]
        print(f"  with >={MIN_RATINGS} ratings: {len(rated):,}")
        print(f"  interactions file also gives you {len(inter):,} ratings — enough")
        print(f"  to bootstrap item-item similarity without your own users.\n")

        out = pathlib.Path("out"); out.mkdir(exist_ok=True)
        best = (rated.sort_values(["cuisine", "mean", "count"],
                                  ascending=[True, False, False])
                     .groupby("cuisine").head(args.top))
        cols = ["id", "name", "cuisine", "minutes", "mean", "count",
                "n_steps", "n_ingredients"]
        best[cols].to_csv(out / "foodcom_shortlist.csv", index=False)
        print(f"  best {args.top} per cuisine -> out/foodcom_shortlist.csv")
        print("  Read it. Food.com is user-submitted since 1999 and the tail is"
              " rough.\n")

        for c in sorted(TARGET):
            top = best[best["cuisine"] == c].head(3)
            if len(top):
                print(f"  {c}:")
                for _, r in top.iterrows():
                    print(f"    {r['mean']:.2f} ({int(r['count'])} ratings)  "
                          f"{r['name'][:52]}")
        print()
    else:
        print("  RAW_interactions.csv not found — ratings unavailable, so there"
              " is no quality signal to filter on.\n")

    print("""  VERDICT

    Good for:  training data. 231k recipes with cuisine tags is a strong
               corpus for the auto-tagging classifier, and 1.1M ratings
               bootstrap recipe-to-recipe similarity without needing your
               own user base.

    Bad for:   your shipping catalogue. No images and no quantities. An app
               whose entire premise is "what can I cook with what I have"
               showing an ingredient list with no amounts is a downgrade on
               what you already have.

    Licence:   Kaggle marks it public domain, but that is the uploader's
               claim about a scrape of Food.com's user content — it does not
               transfer the original rights. Standard and defensible for
               academic work if cited. Not safe for a commercial launch.
""")


if __name__ == "__main__":
    main()
