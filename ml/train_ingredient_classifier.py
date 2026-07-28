"""Trains the ingredient recognition model for Recipedia's scan feature.

Runs on Google Colab with a free GPU in roughly 15-25 minutes.

WHY THIS SHAPE
--------------
Transfer learning on MobileNetV2, not a network from scratch. With a few
thousand images a scratch model overfits immediately; MobileNetV2 already knows
edges, texture and shape from ImageNet, so we only teach it the final decision.
MobileNetV2 specifically because the model has to run on a phone — it is ~9 MB
after float16 quantisation, against ~100 MB for ResNet50.

Two phases, which matters:
  1. Freeze the base, train only the new head. The head starts random, and
     large random gradients flowing into good pretrained weights destroy them.
  2. Unfreeze the top layers and fine-tune at a much lower learning rate.

Skipping phase 1 is the most common way to get a worse model than the frozen
baseline.

DATASET
-------
Any folder-per-class layout works:

    dataset/
      train/  apple/ *.jpg   banana/ *.jpg   ...
      val/    apple/ *.jpg   ...

Kaggle "Fruit and Vegetable Image Recognition" matches this and covers most of
classes.json. Aim for 100+ images per class; below ~50 that class will be
unreliable and you are better off dropping it than shipping a confident guess.

OUTPUT
------
    out/model.tflite   -> assets/ml/model.tflite
    out/labels.txt     -> assets/ml/labels.txt
    out/report.txt     -> per-class precision/recall for the write-up
    out/confusion.png  -> confusion matrix figure
"""

import json
import os
import pathlib

import numpy as np
import tensorflow as tf
from sklearn.metrics import classification_report, confusion_matrix

DATA = pathlib.Path("dataset")
OUT = pathlib.Path("out")
IMG = 224           # MobileNetV2's native input size
BATCH = 32
SEED = 1337

# Kept small on purpose: these are the classes the app will trust.
MIN_IMAGES_PER_CLASS = 50


def load_class_map():
    """Folder name is already the canonical ingredient after prepare_dataset."""
    cfg = json.loads(pathlib.Path("classes.json").read_text())
    return {n: n for n in cfg["ingredients"]} | {cfg["negative_class"]: cfg["negative_class"]}


def build_datasets():
    """Loads train/val and reports anything too thin to be trustworthy."""
    train = tf.keras.utils.image_dataset_from_directory(
        DATA / "train", image_size=(IMG, IMG), batch_size=BATCH,
        label_mode="categorical", seed=SEED, shuffle=True)
    val = tf.keras.utils.image_dataset_from_directory(
        DATA / "val", image_size=(IMG, IMG), batch_size=BATCH,
        label_mode="categorical", seed=SEED, shuffle=False)

    names = train.class_names
    counts = {
        n: len(list((DATA / "train" / n).glob("*")))
        for n in names
    }
    thin = {n: c for n, c in counts.items() if c < MIN_IMAGES_PER_CLASS}
    if thin:
        print("\n  WARNING - too few images to be reliable:")
        for n, c in sorted(thin.items(), key=lambda x: x[1]):
            print(f"    {n:18s} {c} images")
        print("  Consider dropping these rather than shipping a confident "
              "wrong answer.\n")

    return train, val, names, counts


def class_weights(counts, names):
    """Rare classes get more weight, or the model learns to ignore them."""
    total = sum(counts.values())
    n = len(names)
    return {i: total / (n * max(counts[name], 1)) for i, name in enumerate(names)}


def build_model(num_classes):
    # Augmentation lives inside the model so it applies during training only,
    # and ships nothing extra to the phone.
    augment = tf.keras.Sequential([
        tf.keras.layers.RandomFlip("horizontal"),
        tf.keras.layers.RandomRotation(0.12),
        tf.keras.layers.RandomZoom(0.15),
        tf.keras.layers.RandomContrast(0.15),
        # Kitchen photos are lit badly and held at odd angles. Training only on
        # clean catalogue shots produces a model that fails on exactly the
        # images this app will receive.
        tf.keras.layers.RandomBrightness(0.2),
    ], name="augment")

    base = tf.keras.applications.MobileNetV2(
        input_shape=(IMG, IMG, 3), include_top=False, weights="imagenet")
    base.trainable = False

    inputs = tf.keras.Input(shape=(IMG, IMG, 3))
    x = augment(inputs)
    x = tf.keras.applications.mobilenet_v2.preprocess_input(x)
    x = base(x, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(0.3)(x)
    outputs = tf.keras.layers.Dense(num_classes, activation="softmax")(x)
    return tf.keras.Model(inputs, outputs), base


def main():
    OUT.mkdir(exist_ok=True)
    class_map = load_class_map()
    train, val, names, counts = build_datasets()

    unmapped = [n for n in names if n not in class_map]
    if unmapped:
        print(f"  WARNING - folders with no entry in classes.json: {unmapped}")
        print("  These will train but cannot be matched to an ingredient.\n")

    auto = tf.data.AUTOTUNE
    train = train.prefetch(auto)
    val = val.prefetch(auto)

    model, base = build_model(len(names))

    # ---- phase 1: head only ----
    metrics = ["accuracy",
               tf.keras.metrics.TopKCategoricalAccuracy(k=3, name="top3")]
    model.compile(optimizer=tf.keras.optimizers.Adam(1e-3),
                  loss="categorical_crossentropy", metrics=metrics)
    model.fit(train, validation_data=val, epochs=8,
              class_weight=class_weights(counts, names),
              callbacks=[tf.keras.callbacks.EarlyStopping(
                  patience=3, restore_best_weights=True)])

    # ---- phase 2: fine-tune the top of the base ----
    base.trainable = True
    for layer in base.layers[:-30]:
        layer.trainable = False
    # An order of magnitude lower: fine-tuning at 1e-3 undoes the pretraining.
    model.compile(optimizer=tf.keras.optimizers.Adam(1e-5),
                  loss="categorical_crossentropy", metrics=metrics)
    model.fit(train, validation_data=val, epochs=12,
              class_weight=class_weights(counts, names),
              callbacks=[tf.keras.callbacks.EarlyStopping(
                  patience=4, restore_best_weights=True)])

    # ---- evaluate ----
    y_true, y_pred, y_top3 = [], [], []
    for images, labels in val:
        probs = model.predict(images, verbose=0)
        y_true.extend(np.argmax(labels, axis=1))
        y_pred.extend(np.argmax(probs, axis=1))
        # The scan screen shows the three best guesses as tappable chips, so
        # top-3 is the accuracy the user actually experiences.
        y_top3.extend(np.argsort(probs, axis=1)[:, -3:].tolist())

    top1 = float(np.mean(np.array(y_true) == np.array(y_pred)))
    top3 = float(np.mean([t in p3 for t, p3 in zip(y_true, y_top3)]))
    print(f"\n  top-1 accuracy  {top1:.4f}")
    print(f"  top-3 accuracy  {top3:.4f}   <- the number that matches the UI")

    report = classification_report(y_true, y_pred, target_names=names, digits=3)
    (OUT / "report.txt").write_text(report, encoding="utf-8")
    print("\n" + report)

    try:
        import matplotlib.pyplot as plt
        cm = confusion_matrix(y_true, y_pred, normalize="true")
        fig, ax = plt.subplots(figsize=(11, 10))
        ax.imshow(cm, cmap="Blues")
        ax.set_xticks(range(len(names)), names, rotation=90, fontsize=7)
        ax.set_yticks(range(len(names)), names, fontsize=7)
        ax.set_xlabel("predicted"); ax.set_ylabel("actual")
        fig.tight_layout(); fig.savefig(OUT / "confusion.png", dpi=150)
        print(f"  confusion matrix -> {OUT/'confusion.png'}")
    except ImportError:
        pass

    # ---- export ----
    # Labels are written as the CANONICAL ingredient name, so the app never has
    # to know what the dataset called things.
    labels = [class_map.get(n, n) for n in names]
    (OUT / "labels.txt").write_text("\n".join(labels), encoding="utf-8")

    conv = tf.lite.TFLiteConverter.from_keras_model(model)
    conv.optimizations = [tf.lite.Optimize.DEFAULT]
    # float16 rather than int8: roughly half the size with no calibration set
    # required, and accuracy loss is negligible for this task.
    conv.target_spec.supported_types = [tf.float16]
    (OUT / "model.tflite").write_bytes(conv.convert())

    size_mb = (OUT / "model.tflite").stat().st_size / 1e6
    print(f"\n  model.tflite  {size_mb:.1f} MB")
    print(f"  labels.txt    {len(labels)} classes")
    print("\n  Copy both into assets/ml/ and follow ml/README.md step 4.")


if __name__ == "__main__":
    main()
