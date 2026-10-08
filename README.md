# NYC_taxi_data_engineering


## Description du projet

La NYC Taxi & Limousine Commission publie chaque mois les données de millions de trajets en taxi jaune à New York, au format Parquet.

source : https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page

En tant que Data Engineer, l'objectif est de construire le Data Warehouse analytique d'une société de transport. Pour cela, une pipeline de données sera conçu pour ingérer les données brutes, les nettoyer, les transformer et produire des tables d'analyse prêtes à alimenter des dashboards décisionnels.

Le dataset présente des problèmes de qualité des données :
- 15,54% de valeurs manquantes
- 4,15% de montants négatifs
- 2,62% de trajets avec distance zéro
- Valeurs extrêmes aberrantes (distance > 1000 miles)

L'architecture cible repose sur 3 schémas Snowflake :
- RAW : Données brutes importées sans modification depuis les fichiers Parquet
- STAGING : Données nettoyées, filtrées et enrichies (durée, vitesse, catégorisation)
- FINAL : Tables d'analyse métier (résumés quotidiens, analyses par zone, patterns horaires)

Technologies utilisées : Snowflake, SQL, dbt Core, Python, GitHub Actions, Luigi, Power Bi.


## Data Quality

Le projet intègre des contrôles portant notamment sur :

- les valeurs manquantes ;
- les valeurs négatives ;
- les distances nulles ;
- les valeurs extrêmes ;
- les doublons ;
- la cohérence temporelle ;
- l'intégrité référentielle.


## Architecture
```
nyc-taxi-data-engineering
│   .env.example
│   .gitignore
│   README.md
│   requirements.txt
│
├── data
│   ├── processed
│   │       .gitkeep
│   ├── raw
│   │       .gitkeep
│   └── reference
│           .gitkeep
│
├── ingestion
│   |__ __init__.py
│   |__ download_tlc.py
│   |__ validate_parquet.py
│
├── luigi
│   |__ __init__.py
│   |__ pipeline.py
│
├── quality
│   |__ __init__.py
│   |__ data_quality.py
│
├── sql
│
├── tests
│   |__ __init__.py
│   |__ test_ingestion.py
│
├── dbt
│
└── powerbi
```

## Etapes

NYC TLC
   ↓
Python
   ↓
Luigi
   ↓
Snowflake RAW
   ↓
dbt
   ↓
Snowflake STAGING
   ↓
Snowflake FINAL
   ↓
Power BI


