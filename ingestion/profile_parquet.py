# script permettant de lire des métadonnées du fichier parquet sans chargement de ce dernier

from pathlib import Path

import pandas as pd
import pyarrow.parquet as pq


FILE_PATH = Path("data/raw/yellow_tripdata_2024-01.parquet")


def main():
    if not FILE_PATH.exists():
        raise FileNotFoundError(f"Fichier introuvable : {FILE_PATH}")

    parquet_file = pq.ParquetFile(FILE_PATH)

    print("=" * 60)
    print("NYC TAXI - PROFILAGE DU FICHIER")
    print("=" * 60)

    print(f"\nFichier : {FILE_PATH}")
    print(f"Taille : {FILE_PATH.stat().st_size / (1024**2):.2f} MB")

    print(f"\nNombre de lignes : {parquet_file.metadata.num_rows:,}")
    print(f"Nombre de colonnes : {len(parquet_file.schema.names)}")

    print("\nColonnes :")

    for field in parquet_file.schema_arrow:
        print(f" - {field.name}: {field.type}")

    print("\nNombre de row groups :", parquet_file.num_row_groups)


if __name__ == "__main__":
    main()