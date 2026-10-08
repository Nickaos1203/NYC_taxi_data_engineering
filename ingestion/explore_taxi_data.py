from pathlib import Path

import pandas as pd


FILE_PATH = Path("data/raw/yellow_tripdata_2024-01.parquet")


def main():
    print("Chargement du fichier")

    df = pd.read_parquet(FILE_PATH)

    print("\n" + "=" * 60)
    print("DIMENSIONS")
    print("=" * 60)

    print(f"Lignes : {len(df):,}")
    print(f"Colonnes : {len(df.columns)}")

    print("\n" + "=" * 60)
    print("COLONNES")
    print("=" * 60)

    print(df.columns.tolist())

    print("\n" + "=" * 60)
    print("TYPES")
    print("=" * 60)

    print(df.dtypes)

    print("\n" + "=" * 60)
    print("APERÇU")
    print("=" * 60)

    print(df.head())

    print("\n" + "=" * 60)
    print("STATISTIQUES")
    print("=" * 60)

    print(df.describe(include="all").transpose())


if __name__ == "__main__":
    main()