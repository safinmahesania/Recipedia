"""Downloads and prepares the training set.

DATASET CHOICE
--------------
kritikseth/fruit-and-vegetable-image-recognition — 36 classes of images scraped
from Bing: real kitchens, market stalls, hands holding things, mixed lighting,
cluttered backgrounds.

Deliberately NOT Fruits-360. That set is a turntable against a white background,
and a model trained on it reaches 99.9% validation accuracy and then fails on
the first real photo it sees, because it has learned "object on white" rather
than "onion". A high number from controlled data is a worse outcome than a
lower number from real data — it tells you nothing and it breaks in the demo.

WHAT THIS SCRIPT DOES
---------------------
1. Downloads the dataset.
2. Merges folders that are the same ingredient to you: capsicum + paprika +
   bell pepper all become 'bell pepper'. Fewer, better-separated classes with
   more images each — this raises accuracy rather than lowering it, and stops
   the model wasting capacity on a distinction the app does not care about.
3. Folds the six classes you do not stock (kiwi, lettuce, pear, turnip, soy
   beans, watermelon) into a single 'unknown' class. Without a negative class
   the model must map every photo onto something it knows, so a kiwi becomes a
   confident 'apple'. With one, it can say "not something I handle".
4. Writes a clean train/val split.
"""

import json
import pathlib
import random
import shutil

SEED = 1337
VAL_FRACTION = 0.2
OUT = pathlib.Path("dataset")

# dataset folder -> canonical ingredient in public.ingredients
MAP = {
    "apple": "apple",
    "banana": "banana",
    "beetroot": "beetroot",
    "bell pepper": "bell pepper",
    "capsicum": "bell pepper",
    "paprika": "bell pepper",
    "cabbage": "cabbage",
    "carrot": "carrot",
    "cauliflower": "cauliflower",
    "chilli pepper": "green chilli",
    "jalepeno": "green chilli",
    "corn": "corn",
    "sweetcorn": "corn",
    "cucumber": "cucumber",
    "eggplant": "brinjal",
    "garlic": "garlic",
    "ginger": "ginger",
    "grapes": "grapes",
    "lemon": "lemon",
    "mango": "mango",
    "onion": "onion",
    "orange": "orange",
    "peas": "peas",
    "pineapple": "pineapple",
    "pomegranate": "pomegranate",
    "potato": "potato",
    "raddish": "radish",
    "spinach": "spinach",
    "sweetpotato": "sweet potato",
    "tomato": "tomato",
}

# Real produce the app does not stock. Kept as a negative class so the model
# has somewhere to put things it should not name.
NEGATIVE = ["kiwi", "lettuce", "pear", "turnip", "soy beans", "watermelon"]
UNKNOWN = "unknown"


def download():
    try:
        import kagglehub
    except ImportError:
        raise SystemExit(
            "pip install kagglehub, or download the dataset manually from\n"
            "  https://www.kaggle.com/datasets/kritikseth/"
            "fruit-and-vegetable-image-recognition\n"
            "and pass its path to build(src)")
    path = kagglehub.dataset_download(
        "kritikseth/fruit-and-vegetable-image-recognition")
    print(f"  downloaded to {path}")
    return pathlib.Path(path)


def collect(src):
    """All images per source folder, across whatever split dirs exist."""
    found = {}
    for folder in src.rglob("*"):
        if not folder.is_dir():
            continue
        name = folder.name.lower().strip()
        if name not in MAP and name not in NEGATIVE:
            continue
        images = [p for p in folder.iterdir()
                  if p.suffix.lower() in {".jpg", ".jpeg", ".png", ".webp"}]
        if images:
            found.setdefault(name, []).extend(images)
    return found


def build(src):
    random.seed(SEED)
    found = collect(src)
    missing = [k for k in list(MAP) + NEGATIVE if k not in found]
    if missing:
        print(f"  note: folders not found in the download: {missing}")

    # group by destination class
    grouped = {}
    for folder, images in found.items():
        target = MAP.get(folder, UNKNOWN)
        grouped.setdefault(target, []).extend(images)

    if OUT.exists():
        shutil.rmtree(OUT)

    print(f"\n  {'class':18s} {'train':>6s} {'val':>5s}")
    print("  " + "-" * 32)
    total_t = total_v = 0
    for cls in sorted(grouped):
        images = grouped[cls]
        random.shuffle(images)
        cut = max(1, int(len(images) * VAL_FRACTION))
        for split, subset in (("val", images[:cut]), ("train", images[cut:])):
            dest = OUT / split / cls
            dest.mkdir(parents=True, exist_ok=True)
            for i, p in enumerate(subset):
                shutil.copy(p, dest / f"{cls.replace(' ', '_')}_{i}{p.suffix.lower()}")
        t, v = len(images) - cut, cut
        total_t += t
        total_v += v
        flag = "  <- thin" if t < 60 else ""
        print(f"  {cls:18s} {t:6d} {v:5d}{flag}")

    print("  " + "-" * 32)
    print(f"  {'TOTAL':18s} {total_t:6d} {total_v:5d}")
    print(f"  classes: {len(grouped)}")

    labels = sorted(k for k in grouped if k != UNKNOWN)
    pathlib.Path("classes.json").write_text(json.dumps({
        "_comment": "Generated by prepare_dataset.py. Right side must match "
                    "public.ingredients. 'unknown' is a negative class and is "
                    "never surfaced to the user.",
        "ingredients": labels,
        "negative_class": UNKNOWN,
        "source_folder_map": MAP,
    }, indent=2), encoding="utf-8")
    print(f"\n  classes.json written: {len(labels)} ingredients + '{UNKNOWN}'")


if __name__ == "__main__":
    build(download())
