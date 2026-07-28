# Ingredient recognition model

The scan screen works today with manual entry. This adds the camera path.

## Scope, and why it is narrow

**Fresh produce only** — 30 dataset classes mapping to 28 ingredients.

Staples like salt, oil, turmeric and garam masala are typed once during
onboarding and marked as pantry staples, so they never need detecting. Asking a
camera to tell turmeric from chilli powder in a jar is a genuinely hard problem
that buys nothing: the user already told us they own both.

Fresh produce is where a camera actually beats typing — you open the fridge,
point, and it fills in six things.

## 1. Get a dataset

Folder-per-class:

```
dataset/
  train/  apple/*.jpg  banana/*.jpg  carrot/*.jpg  ...
  val/    apple/*.jpg  ...
```

Kaggle **"Fruit and Vegetable Image Recognition"** (36 classes) matches this
layout and covers most of `classes.json`. An 80/20 train/val split is fine.

**Target 100+ images per class.** The script warns below 50 and you should
drop those classes rather than ship a confident wrong answer — a scan that
says "banana" for a potato is worse than one that says nothing.

If you photograph your own, shoot in a real kitchen: bad light, cluttered
counters, odd angles. That is what the app will actually receive.

## 2. Train

Google Colab, GPU runtime, 15–25 minutes:

```python
!pip install -q tensorflow scikit-learn matplotlib
!python train_ingredient_classifier.py
```

## 3. What comes out

| File | Goes to |
|---|---|
| `out/model.tflite` | `assets/ml/model.tflite` |
| `out/labels.txt` | `assets/ml/labels.txt` |
| `out/report.txt` | your report — per-class precision and recall |
| `out/confusion.png` | your report — shows which pairs it confuses |

The confusion matrix is worth reading before shipping. Onion/garlic and
lemon/orange confusion is normal and tolerable; potato/apple confusion means
something is wrong with the data.

## 4. Wire it into the app

```yaml
# pubspec.yaml
dependencies:
  tflite_flutter: ^0.11.0

flutter:
  assets:
    - assets/ml/
```

Then in `lib/services/scan_service.dart`:

- flip `isModelAvailable` to `true`
- implement `_runModel` — decode to 224×224, normalise with the same
  `preprocess_input` scaling the training used, run the interpreter, and keep
  predictions above the confidence floor

**Two things that will bite you if missed:**

*Preprocessing must match training exactly.* MobileNetV2 expects inputs scaled
to [-1, 1], not [0, 1]. Get this wrong and the model returns confident nonsense
rather than failing loudly.

*Set a confidence floor.* Around 0.6 is a reasonable start. Everything the
model returns gets added to the user's pantry, and a wrong ingredient silently
changes which recipes match. A low-confidence guess is worse than no guess —
the user can always type it.

## 5. Labels are canonical names

`labels.txt` contains ingredient names exactly as they appear in
`public.ingredients`, not dataset folder names. The app feeds detection results
into the same matcher manual entry uses, so `capsicum` would find nothing —
`classes.json` maps it to `bell pepper` before export.

If you add classes, add them to `classes.json` too, and check the right-hand
side exists in the table.
