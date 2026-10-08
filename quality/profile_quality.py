from pathlib import Path

import pandas as pd
import numpy as np


FILE_PATH = Path("data/raw/yellow_tripdata_2024-01.parquet")


def main():
    df = pd.read_parquet(FILE_PATH)

    total_rows = len(df)

    print("=" * 70)
    print("NYC TAXI - DATA QUALITY REPORT")
    print("=" * 70)

    print(f"\nNombre total de lignes : {total_rows:,}")

    # ---------------------------------------------------------
    # 1. VALEURS MANQUANTES
    # ---------------------------------------------------------

    print("\n" + "=" * 70)
    print("1. VALEURS MANQUANTES")
    print("=" * 70)

    missing = df.isna().sum()
    missing_pct = (missing / total_rows * 100).round(2)

    missing_report = pd.DataFrame({
        "missing_count": missing,
        "missing_pct": missing_pct
    })

    print(
        missing_report
        .sort_values("missing_pct", ascending=False)
        .to_string()
    )

    # ---------------------------------------------------------
    # 2. DISTANCES NULLLES
    # ---------------------------------------------------------

    print("\n" + "=" * 70)
    print("2. DISTANCES NULLLES")
    print("=" * 70)

    zero_distance = (df["trip_distance"] == 0).sum()
    zero_distance_pct = zero_distance / total_rows * 100

    print(f"Nombre : {zero_distance:,}")
    print(f"Pourcentage : {zero_distance_pct:.2f}%")

    # ---------------------------------------------------------
    # 3. DISTANCES NEGATIVES
    # ---------------------------------------------------------

    print("\n" + "=" * 70)
    print("3. DISTANCES NEGATIVES")
    print("=" * 70)

    negative_distance = (df["trip_distance"] < 0).sum()

    print(f"Nombre : {negative_distance:,}")

    # ---------------------------------------------------------
    # 4. DISTANCES EXTREMES
    # ---------------------------------------------------------

    print("\n" + "=" * 70)
    print("4. DISTANCES EXTREMES")
    print("=" * 70)

    extreme_distance = (df["trip_distance"] > 1000).sum()

    print(f"Nombre > 1000 miles : {extreme_distance:,}")

    # ---------------------------------------------------------
    # 5. MONTANTS NEGATIFS
    # ---------------------------------------------------------

    print("\n" + "=" * 70)
    print("5. MONTANTS NEGATIFS")
    print("=" * 70)

    amount_columns = [
        "fare_amount",
        "extra",
        "mta_tax",
        "tip_amount",
        "tolls_amount",
        "improvement_surcharge",
        "total_amount",
    ]

    for column in amount_columns:
        count = (df[column] < 0).sum()
        percentage = count / total_rows * 100

        print(
            f"{column:30} "
            f"{count:10,} "
            f"({percentage:.2f}%)"
        )

    # ---------------------------------------------------------
    # 6. COHERENCE TEMPORELLE
    # ---------------------------------------------------------

    print("\n" + "=" * 70)
    print("6. COHERENCE TEMPORELLE")
    print("=" * 70)

    invalid_dates = (
        df["tpep_dropoff_datetime"]
        < df["tpep_pickup_datetime"]
    ).sum()

    print(
        f"Dropoff avant pickup : "
        f"{invalid_dates:,}"
    )

    # ---------------------------------------------------------
    # 7. DOUBLONS
    # ---------------------------------------------------------

    print("\n" + "=" * 70)
    print("7. DOUBLONS")
    print("=" * 70)

    duplicates = df.duplicated().sum()

    print(f"Nombre de doublons : {duplicates:,}")

    # ---------------------------------------------------------
    # 8. PASSENGERS
    # ---------------------------------------------------------

    print("\n" + "=" * 70)
    print("8. PASSENGER COUNT")
    print("=" * 70)

    invalid_passengers = (
        (df["passenger_count"] < 0)
        | (df["passenger_count"] > 20)
    ).sum()

    print(
        f"Valeurs négatives ou > 20 : "
        f"{invalid_passengers:,}"
    )

    # ---------------------------------------------------------
    # 9. DUREE DU TRAJET
    # ---------------------------------------------------------

    df["trip_duration_seconds"] = (
        df["tpep_dropoff_datetime"]
        - df["tpep_pickup_datetime"]
    ).dt.total_seconds()

    df["trip_duration_minutes"] = (
        df["trip_duration_seconds"] / 60
    )

    df["trip_speed_mph"] = np.where(
        (df["trip_distance"] > 0)
        & (df["trip_duration_seconds"] > 0),
        df["trip_distance"] / (df["trip_duration_seconds"] / 3600),
        np.nan
)

    print("\n" + "=" * 70)
    print("9. DUREE DES TRAJETS")
    print("=" * 70)

    print(
        df["trip_duration_minutes"]
        .describe()
    )

    # ---------------------------------------------------------
    # 10. VITESSE
    # ---------------------------------------------------------

    print("\n" + "=" * 70)
    print("10. VITESSE")
    print("=" * 70)

    valid_speed = df["trip_speed_mph"].dropna()

    print(valid_speed.describe())

    print("\nVitesse > 60 mph :", (valid_speed > 60).sum())
    print("Vitesse > 80 mph :", (valid_speed > 80).sum())
    print("Vitesse > 100 mph :", (valid_speed > 100).sum())

if __name__ == "__main__":
    main()