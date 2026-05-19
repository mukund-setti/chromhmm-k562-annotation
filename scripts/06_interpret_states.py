#!/usr/bin/env python3
"""
Interpret ChromHMM emission probabilities and annotate states.

Loads models/K562_15state/emissions_15.txt (adjust NUM_STATES if needed),
prints top marks per state, suggests biological labels, writes
results/state_annotations.tsv, and saves an emissions heatmap to results/.

Usage:
    python scripts/06_interpret_states.py
"""

from __future__ import annotations

import sys
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns

PROJECT_ROOT = Path(r"C:\Users\mukun\chromhmm-project")
NUM_STATES = 15
MODEL_DIR = PROJECT_ROOT / "models" / f"K562_{NUM_STATES}state"
EMISSIONS_FILE = MODEL_DIR / f"emissions_{NUM_STATES}.txt"
RESULTS_DIR = PROJECT_ROOT / "results"
ANNOTATIONS_TSV = RESULTS_DIR / "state_annotations.tsv"
HEATMAP_PNG = RESULTS_DIR / f"emissions_heatmap_{NUM_STATES}state.png"

# (label, predicate on row dict of mark -> emission probability)
LABEL_RULES: list[tuple[str, callable]] = [
    (
        "Active TSS",
        lambda r: r.get("H3K4me3", 0) >= 0.8
        and r.get("H3K27ac", 0) < 0.5
        and r.get("H3K4me1", 0) < 0.5,
    ),
    (
        "Active Promoter",
        lambda r: r.get("H3K4me3", 0) >= 0.5 and r.get("H3K27ac", 0) >= 0.5,
    ),
    (
        "Active Enhancer",
        lambda r: r.get("H3K4me1", 0) >= 0.5
        and r.get("H3K27ac", 0) >= 0.5
        and r.get("H3K4me3", 0) < 0.3,
    ),
    (
        "Poised/Primed Enhancer",
        lambda r: r.get("H3K4me1", 0) >= 0.5
        and r.get("H3K27ac", 0) < 0.3
        and r.get("H3K4me3", 0) < 0.3,
    ),
    (
        "Transcribed",
        lambda r: r.get("H3K36me3", 0) >= 0.5,
    ),
    (
        "Polycomb Repressed",
        lambda r: r.get("H3K27me3", 0) >= 0.5,
    ),
    (
        "Heterochromatin",
        lambda r: r.get("H3K9me3", 0) >= 0.5,
    ),
    (
        "Quiescent",
        lambda r: all(r.get(m, 0) < 0.2 for m in ("H3K4me3", "H3K4me1", "H3K27ac", "H3K36me3", "H3K27me3", "H3K9me3")),
    ),
]


def load_emissions(path: Path) -> pd.DataFrame:
    """Parse ChromHMM emissions file (state x mark probabilities)."""
    if not path.is_file():
        sys.exit(f"ERROR: emissions file not found: {path}\nRun LearnModel first (scripts/03_learn_model.ps1).")

    df = pd.read_csv(path, sep="\t", index_col=0)
    df.index = df.index.astype(int)
    df.index.name = "State"
    return df


def suggest_label(row: pd.Series) -> str:
    values = row.to_dict()
    for label, rule in LABEL_RULES:
        if rule(values):
            return label
    top = row.idxmax()
    return f"Mixed/Other (top: {top})"


def top_marks(row: pd.Series, n: int = 3) -> str:
    ordered = row.sort_values(ascending=False)
    parts = [f"{m}={ordered[m]:.3f}" for m in ordered.head(n).index]
    return ", ".join(parts)


def main() -> None:
    print("=== State interpretation (06_interpret_states.py) ===")
    print(f"Loading: {EMISSIONS_FILE}")

    emissions = load_emissions(EMISSIONS_FILE)
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)

    rows = []
    print("\nPer-state summary:")
    print("-" * 72)
    for state in sorted(emissions.index):
        row = emissions.loc[state]
        label = suggest_label(row)
        tops = top_marks(row)
        print(f"State {state:2d}  |  {label:28s}  |  {tops}")
        rows.append(
            {
                "state": state,
                "suggested_label": label,
                "top_marks": tops,
                **{f"emission_{m}": row[m] for m in emissions.columns},
            }
        )

    annot = pd.DataFrame(rows)
    annot.to_csv(ANNOTATIONS_TSV, sep="\t", index=False)
    print(f"\nWrote: {ANNOTATIONS_TSV}")

    plt.figure(figsize=(10, max(6, NUM_STATES * 0.35)))
    sns.heatmap(
        emissions,
        annot=True,
        fmt=".2f",
        cmap="YlOrRd",
        vmin=0,
        vmax=1,
        cbar_kws={"label": "Emission probability"},
    )
    plt.title(f"K562 ChromHMM emissions ({NUM_STATES} states)")
    plt.xlabel("Histone mark")
    plt.ylabel("State")
    plt.tight_layout()
    plt.savefig(HEATMAP_PNG, dpi=150)
    plt.close()
    print(f"Wrote: {HEATMAP_PNG}")

    print("\nOK: Interpretation complete. Review heatmap and state_annotations.tsv.")


if __name__ == "__main__":
    main()
