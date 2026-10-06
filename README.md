# NYC_taxi_data_engineering

## Présentation
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

Technologies utilisées : Snowflake, SQL, dbt Core, Python, GitHub Actions, Parquet.