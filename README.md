# NYC Taxi Data Engineering

## 1. Présentation du projet

Ce projet consiste à concevoir et mettre en œuvre un pipeline d'ingénierie des données à partir des données de trajets des taxis jaunes de New York (NYC Yellow Taxi).

Source : https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page

L'objectif est de construire un entrepôt de données analytique dans Snowflake, de transformer les données avec dbt et de mettre en place une orchestration des traitements avec Luigi. Les données préparées sont ensuite exploitées dans Power BI pour produire des indicateurs et des visualisations.

Le projet couvre les champs en ingénierie des données suivants :

- Ingestion et structuration des données dans un entrepôt Snowflake.
- Transformation des données avec dbt.
- Contrôle de la qualité des données.
- Orchestration des traitements avec Luigi.
- Modélisation analytique et restitution dans Power BI.

## 2. Architecture du projet

```text
Données NYC Yellow Taxi (Parquet)
              |
              | Chargement manuellement des fichiers en format parquet dans Snowflake
              v
       Snowflake - RAW
              |
              v
         Luigi
       Orchestration
              |
              v
        dbt - STAGING
   Nettoyage et contrôles
              |
              v
         dbt - MARTS
 Modélisation analytique
              |
              v
          Snowflake
              |
              v
          Power BI
   Tableaux de bord
```

**Périmètre de l'automatisation :** les fichiers Parquet sont chargés manuellement dans Snowflake (en zone de préparation), dans le schéma RAW. Luigi intervient ensuite pour orchestrer les transformations dbt et les tests.

## 3. Technologies utilisées

| Technologie | Utilisation |
|---|---|
| Python | Scripts et orchestration |
| Luigi | Gestion des dépendances entre les traitements |
| Snowflake | Entrepôt de données cloud |
| dbt Core | Transformation et modélisation SQL |
| Snowflake Connector for Python | Connexion à Snowflake depuis Python |
| python-dotenv | Chargement des variables d'environnement |
| Power BI | Visualisation et analyse des données |
| Git / GitHub | Versionnement du projet |

## 4. Architecture de données Snowflake

L'entrepôt repose sur trois niveaux de données.

### RAW

Le schéma RAW contient les données sources chargées dans Snowflake.

Principales tables :

- `RAW.YELLOW_TRIPS` : données des trajets des taxis jaunes.
- `RAW.TAXI_ZONE_LOOKUP` : référentiel des zones de taxi.

Les fichiers Parquet sont chargés dans Snowflake avant le lancement du pipeline Luigi.

### STAGING

Le schéma STAGING contient les transformations intermédiaires réalisées avec dbt.

Le modèle `STG_YELLOW_TRIPS` permet de :

- Calculer la durée des trajets.
- Calculer la vitesse moyenne lorsque les données le permettent.
- Identifier les anomalies et les avertissements de qualité.
- Attribuer un statut de qualité aux trajets.

Les statuts de qualité utilisés sont `VALID`, `WARN` et `INVALID`.

### MARTS

Le schéma MARTS contient les modèles analytiques destinés à l'exploitation des données.

| Modèle | Description |
|---|---|
| `DIM_DATE` | Dimension temporelle |
| `DIM_ZONE` | Dimension géographique |
| `FCT_TRIPS` | Table de faits des trajets |
| `MART_DAILY_TRIPS` | Indicateurs quotidiens |
| `MART_PICKUP_ZONE` | Analyse par zone de départ |
| `MART_TEMPORAL_PATTERNS` | Analyse des trajets par date et heure |

## 5. Qualité des données

La qualité des données est contrôlée pendant les transformations dbt.

Les contrôles portent notamment sur :

- Les durées de trajet négatives.
- Les distances incohérentes ou excessives.
- Les trajets dont la date de dépose précède la date de prise en charge.
- Les montants négatifs.
- Les valeurs manquantes et les anomalies de certaines colonnes.

Les trajets invalides sont séparés des données retenues pour l'analyse. Les trajets présentant des avertissements sont conservés afin de permettre leur analyse.

Les montants négatifs sont également conservés comme indicateur de suivi, car ils peuvent correspondre à des situations particulières et ne sont pas systématiquement considérés comme invalides.

## 6. Orchestration avec Luigi

Luigi permet d'organiser l'exécution des traitements dbt en fonction de leurs dépendances.

Le pipeline comprend les tâches suivantes :

1. **CheckRawData** : vérifie que la table `RAW.YELLOW_TRIPS` contient des données.
2. **RunStaging** : exécute les transformations dbt de STAGING.
3. **RunMarts** : exécute les modèles analytiques de MARTS après STAGING.
4. **RunTests** : lance les tests dbt après les transformations.

Luigi utilise des marqueurs de tâches terminées pour éviter de réexécuter inutilement certaines étapes. Dans la version actuelle, ces marqueurs doivent être gérés lorsque les données sources changent.

## 7. Installation et configuration

### Prérequis

- Python et un environnement virtuel.
- Un compte Snowflake avec les droits nécessaires.
- dbt Core et l'adaptateur Snowflake.
- Luigi.
- Power BI Desktop pour consulter les tableaux de bord.

### Installation des dépendances

Depuis la racine du projet :

```bash
# Activer l'environnement virtuel
source .nyc_venv/Scripts/activate

# Installer les dépendances
pip install -r requirements.txt
```

### Variables d'environnement

Les paramètres de connexion Snowflake sont stockés dans un fichier `.env` à la racine du projet.

Exemple de structure :

```dotenv
SNOWFLAKE_ACCOUNT=your_account
SNOWFLAKE_USER=your_user
SNOWFLAKE_PASSWORD=your_password
```

Le fichier `.env` ne doit pas être versionné dans Git.

## 8. Exécution du pipeline

Les fichiers Parquet doivent être chargés dans Snowflake, dans la table `RAW.YELLOW_TRIPS`, avant le lancement.

Depuis la racine du projet :

```bash
python luigi/pipeline.py --local-scheduler
```

Cette commande déclenche les tâches Luigi et les traitements dbt associés.

Pour exécuter séparément les modèles dbt depuis leur répertoire :

```bash
cd dbt/nyc_taxi_dbt

# Modèle intermédiaire
dbt run --select staging

# Modèles analytiques
dbt run --select marts

# Tests de qualité
dbt test
```


## 09. Visualisation avec Power BI

Power BI est utilisé pour analyser les données préparées dans Snowflake.

Les tableaux de bord couvrent notamment :

- Les indicateurs généraux de transport.
- Les revenus et volumes de trajets.
- La répartition géographique des trajets.
- Les tendances temporelles par jour et par heure.
- Les indicateurs de qualité des données.

## 10. Dictionnaire de données — NYC Taxi

> Les types de données et les noms de colonnes sont issus de l'export Snowflake du 21 octobre 2026.
> Les colonnes sont indiquées comme nullable dans cet export. Les descriptions sont fonctionnelles et proposées à partir du nom des colonnes et de leur usage dans le projet.

### 1. Schéma RAW

#### RAW.YELLOW_TRIPS

| Colonne | Type | Description |
|---|---|---|
| `VENDORID` | NUMBER | Identifiant du fournisseur de technologie taxi. |
| `TPEP_PICKUP_DATETIME` | TIMESTAMP_NTZ | Date et heure de prise en charge du passager. |
| `TPEP_DROPOFF_DATETIME` | TIMESTAMP_NTZ | Date et heure de dépôt du passager. |
| `PASSENGER_COUNT` | NUMBER | Nombre de passagers déclarés. |
| `TRIP_DISTANCE` | FLOAT | Distance du trajet en miles. |
| `RATECODEID` | NUMBER | Code du tarif appliqué au trajet. |
| `STORE_AND_FWD_FLAG` | TEXT | Indique si les données du trajet ont été stockées puis transmises. |
| `PULOCATIONID` | NUMBER | Identifiant de la zone de prise en charge. |
| `DOLOCATIONID` | NUMBER | Identifiant de la zone de dépôt. |
| `PAYMENT_TYPE` | NUMBER | Code du moyen de paiement utilisé. |
| `FARE_AMOUNT` | FLOAT | Montant du tarif de base. |
| `EXTRA` | FLOAT | Montant des suppléments. |
| `MTA_TAX` | FLOAT | Montant de la taxe MTA. |
| `TIP_AMOUNT` | FLOAT | Montant du pourboire. |
| `TOLLS_AMOUNT` | FLOAT | Montant des péages. |
| `IMPROVEMENT_SURCHARGE` | FLOAT | Montant du supplément d'amélioration. |
| `TOTAL_AMOUNT` | FLOAT | Montant total facturé pour le trajet. |
| `CONGESTION_SURCHARGE` | FLOAT | Montant du supplément lié à la congestion. |
| `AIRPORT_FEE` | FLOAT | Frais liés aux trajets concernés par les aéroports. |

#### RAW.TAXI_ZONE_LOOKUP

| Colonne | Type | Description |
|---|---|---|
| `LOCATIONID` | NUMBER | Identifiant unique de la zone taxi. |
| `BOROUGH` | TEXT | Borough ou arrondissement de New York associé à la zone. |
| `ZONE` | TEXT | Nom de la zone taxi. |
| `SERVICE_ZONE` | TEXT | Catégorie de zone de service. |

### 2. Schéma STAGING

#### STAGING.STG_YELLOW_TRIPS

| Colonne | Type | Description |
|---|---|---|
| `VENDORID` | NUMBER | Identifiant du fournisseur de technologie taxi. |
| `TPEP_PICKUP_DATETIME` | TIMESTAMP_NTZ | Date et heure de prise en charge. |
| `TPEP_DROPOFF_DATETIME` | TIMESTAMP_NTZ | Date et heure de dépôt. |
| `PASSENGER_COUNT` | NUMBER | Nombre de passagers déclarés. |
| `TRIP_DISTANCE` | FLOAT | Distance du trajet en miles. |
| `RATECODEID` | NUMBER | Code du tarif appliqué. |
| `STORE_AND_FWD_FLAG` | TEXT | Indicateur de stockage puis transmission des données. |
| `PULOCATIONID` | NUMBER | Identifiant de la zone de prise en charge. |
| `DOLOCATIONID` | NUMBER | Identifiant de la zone de dépôt. |
| `PAYMENT_TYPE` | NUMBER | Code du moyen de paiement. |
| `FARE_AMOUNT` | FLOAT | Montant du tarif de base. |
| `EXTRA` | FLOAT | Montant des suppléments. |
| `MTA_TAX` | FLOAT | Montant de la taxe MTA. |
| `TIP_AMOUNT` | FLOAT | Montant du pourboire. |
| `TOLLS_AMOUNT` | FLOAT | Montant des péages. |
| `IMPROVEMENT_SURCHARGE` | FLOAT | Montant du supplément d'amélioration. |
| `TOTAL_AMOUNT` | FLOAT | Montant total facturé. |
| `CONGESTION_SURCHARGE` | FLOAT | Montant du supplément de congestion. |
| `AIRPORT_FEE` | FLOAT | Frais liés aux aéroports. |
| `TRIP_DURATION_SECONDS` | NUMBER | Durée du trajet calculée en secondes. |
| `TRIP_SPEED_MPH` | FLOAT | Vitesse moyenne calculée en miles par heure. |
| `IS_INVALID` | BOOLEAN | Indique si le trajet est considéré comme invalide. |
| `HAS_WARNING` | BOOLEAN | Indique si le trajet présente une anomalie non bloquante. |
| `IS_NEGATIVE_TRANSACTION` | BOOLEAN | Indique si le trajet comporte un montant de transaction négatif. |
| `PRIMARY_QUALITY_ISSUE` | TEXT | Principale anomalie identifiée pour le trajet. |
| `QUALITY_STATUS` | TEXT | Statut global de qualité du trajet. |
| `DISTANCE_QUALITY_STATUS` | TEXT | Statut de qualité associé à la distance du trajet. |

### 3. Schéma QUARANTINE

#### QUARANTINE.INVALID_YELLOW_TRIPS

| Colonne | Type | Description |
|---|---|---|
| `VENDORID` | NUMBER | Identifiant du fournisseur de technologie taxi. |
| `TPEP_PICKUP_DATETIME` | TIMESTAMP_NTZ | Date et heure de prise en charge. |
| `TPEP_DROPOFF_DATETIME` | TIMESTAMP_NTZ | Date et heure de dépôt. |
| `PASSENGER_COUNT` | NUMBER | Nombre de passagers déclarés. |
| `TRIP_DISTANCE` | FLOAT | Distance du trajet en miles. |
| `RATECODEID` | NUMBER | Code du tarif appliqué. |
| `STORE_AND_FWD_FLAG` | TEXT | Indicateur de stockage puis transmission des données. |
| `PULOCATIONID` | NUMBER | Identifiant de la zone de prise en charge. |
| `DOLOCATIONID` | NUMBER | Identifiant de la zone de dépôt. |
| `PAYMENT_TYPE` | NUMBER | Code du moyen de paiement. |
| `FARE_AMOUNT` | FLOAT | Montant du tarif de base. |
| `EXTRA` | FLOAT | Montant des suppléments. |
| `MTA_TAX` | FLOAT | Montant de la taxe MTA. |
| `TIP_AMOUNT` | FLOAT | Montant du pourboire. |
| `TOLLS_AMOUNT` | FLOAT | Montant des péages. |
| `IMPROVEMENT_SURCHARGE` | FLOAT | Montant du supplément d'amélioration. |
| `TOTAL_AMOUNT` | FLOAT | Montant total facturé. |
| `CONGESTION_SURCHARGE` | FLOAT | Montant du supplément de congestion. |
| `AIRPORT_FEE` | FLOAT | Frais liés aux aéroports. |
| `TRIP_DURATION_SECONDS` | NUMBER | Durée du trajet calculée en secondes. |
| `TRIP_SPEED_MPH` | FLOAT | Vitesse moyenne calculée en miles par heure. |
| `IS_INVALID` | BOOLEAN | Indique si le trajet est invalide. |
| `HAS_WARNING` | BOOLEAN | Indique si le trajet présente un avertissement. |
| `IS_NEGATIVE_TRANSACTION` | BOOLEAN | Indique si le trajet comporte une transaction négative. |
| `PRIMARY_QUALITY_ISSUE` | TEXT | Principale anomalie identifiée. |
| `QUALITY_STATUS` | TEXT | Statut global de qualité. |
| `DISTANCE_QUALITY_STATUS` | TEXT | Statut de qualité associé à la distance. |

### 4. Schéma FINAL

#### FINAL.FCT_TRIPS

| Colonne | Type | Description |
|---|---|---|
| `VENDORID` | NUMBER | Identifiant du fournisseur de technologie taxi. |
| `TPEP_PICKUP_DATETIME` | TIMESTAMP_NTZ | Date et heure de prise en charge. |
| `TPEP_DROPOFF_DATETIME` | TIMESTAMP_NTZ | Date et heure de dépôt. |
| `PASSENGER_COUNT` | NUMBER | Nombre de passagers déclarés. |
| `TRIP_DISTANCE` | FLOAT | Distance du trajet en miles. |
| `RATECODEID` | NUMBER | Code du tarif appliqué. |
| `STORE_AND_FWD_FLAG` | TEXT | Indicateur de stockage puis transmission des données. |
| `PULOCATIONID` | NUMBER | Identifiant de la zone de prise en charge d'origine. |
| `DOLOCATIONID` | NUMBER | Identifiant de la zone de dépôt. |
| `PAYMENT_TYPE` | NUMBER | Code du moyen de paiement. |
| `FARE_AMOUNT` | FLOAT | Montant du tarif de base. |
| `EXTRA` | FLOAT | Montant des suppléments. |
| `MTA_TAX` | FLOAT | Montant de la taxe MTA. |
| `TIP_AMOUNT` | FLOAT | Montant du pourboire. |
| `TOLLS_AMOUNT` | FLOAT | Montant des péages. |
| `IMPROVEMENT_SURCHARGE` | FLOAT | Montant du supplément d'amélioration. |
| `TOTAL_AMOUNT` | FLOAT | Montant total facturé. |
| `CONGESTION_SURCHARGE` | FLOAT | Montant du supplément de congestion. |
| `AIRPORT_FEE` | FLOAT | Frais liés aux aéroports. |
| `TRIP_DURATION_SECONDS` | NUMBER | Durée du trajet en secondes. |
| `TRIP_SPEED_MPH` | FLOAT | Vitesse moyenne en miles par heure. |
| `QUALITY_STATUS` | TEXT | Statut global de qualité du trajet. |
| `HAS_WARNING` | BOOLEAN | Indique si le trajet présente un avertissement. |
| `IS_NEGATIVE_TRANSACTION` | BOOLEAN | Indique si le trajet comporte une transaction négative. |
| `DISTANCE_QUALITY_STATUS` | TEXT | Statut de qualité de la distance. |
| `PICKUP_DATE` | DATE | Date de prise en charge, utilisée pour les analyses temporelles. |
| `PICKUP_LOCATION_ID` | NUMBER | Identifiant de la zone de prise en charge, utilisé pour les relations analytiques. |

#### FINAL.DIM_DATE

| Colonne | Type | Description |
|---|---|---|
| `DATE_KEY` | DATE | Date de référence de la dimension. |
| `YEAR` | NUMBER | Année de la date. |
| `QUARTER` | NUMBER | Trimestre de l'année. |
| `MONTH_NUMBER` | NUMBER | Numéro du mois. |
| `MONTH_NAME` | TEXT | Nom du mois. |
| `DAY_NUMBER` | NUMBER | Numéro du jour dans le mois. |
| `DAY_OF_WEEK_NUMBER` | NUMBER | Numéro du jour dans la semaine. |
| `DAY_NAME` | TEXT | Nom du jour de la semaine. |
| `IS_WEEKEND` | BOOLEAN | Indique si la date correspond à un samedi ou dimanche. |

#### FINAL.DIM_ZONE

| Colonne | Type | Description |
|---|---|---|
| `LOCATION_ID` | NUMBER | Identifiant unique de la zone taxi. |
| `BOROUGH` | TEXT | Borough ou arrondissement associé à la zone. |
| `ZONE_NAME` | TEXT | Nom de la zone taxi. |
| `SERVICE_ZONE` | TEXT | Catégorie de zone de service. |

#### FINAL.MART_DAILY_TRIPS

| Colonne | Type | Description |
|---|---|---|
| `PICKUP_DATE` | DATE | Date de prise en charge des trajets agrégés. |
| `TRIP_COUNT` | NUMBER | Nombre de trajets pour la date. |
| `TOTAL_REVENUE` | FLOAT | Somme des revenus totaux des trajets. |
| `TOTAL_FARE` | FLOAT | Somme des tarifs de base. |
| `TOTAL_TIPS` | FLOAT | Somme des pourboires. |
| `AVG_TOTAL_AMOUNT` | FLOAT | Montant total moyen par trajet. |
| `AVG_TRIP_DISTANCE` | FLOAT | Distance moyenne des trajets. |
| `AVG_TRIP_DURATION_MINUTES` | NUMBER | Durée moyenne des trajets en minutes. |
| `WARNING_TRIP_COUNT` | NUMBER | Nombre de trajets avec avertissement. |
| `NEGATIVE_TRANSACTION_COUNT` | NUMBER | Nombre de trajets avec transaction négative. |

#### FINAL.MART_PICKUP_ZONE

| Colonne | Type | Description |
|---|---|---|
| `PICKUP_LOCATION_ID` | NUMBER | Identifiant de la zone de prise en charge. |
| `PICKUP_ZONE` | TEXT | Nom de la zone de prise en charge. |
| `PICKUP_BOROUGH` | TEXT | Borough associé à la zone de prise en charge. |
| `PICKUP_SERVICE_ZONE` | TEXT | Catégorie de zone de service. |
| `TRIP_COUNT` | NUMBER | Nombre de trajets au départ de la zone. |
| `TOTAL_REVENUE` | FLOAT | Somme des revenus générés par les trajets. |
| `AVG_TOTAL_AMOUNT` | FLOAT | Montant total moyen par trajet. |
| `AVG_TRIP_DISTANCE` | FLOAT | Distance moyenne des trajets. |
| `AVG_TRIP_DURATION_MINUTES` | NUMBER | Durée moyenne des trajets en minutes. |
| `WARNING_TRIP_COUNT` | NUMBER | Nombre de trajets avec avertissement. |
| `NEGATIVE_TRANSACTION_COUNT` | NUMBER | Nombre de trajets avec transaction négative. |

#### FINAL.MART_TEMPORAL_PATTERNS

| Colonne | Type | Description |
|---|---|---|
| `PICKUP_DATE` | DATE | Date de prise en charge. |
| `PICKUP_HOUR` | NUMBER | Heure de prise en charge, de 0 à 23. |
| `PICKUP_DAY_OF_WEEK_NUMBER` | NUMBER | Numéro du jour de la semaine. |
| `PICKUP_DAY_NAME` | TEXT | Nom du jour de la semaine. |
| `TRIP_COUNT` | NUMBER | Nombre de trajets pour la date et l'heure. |
| `TOTAL_REVENUE` | FLOAT | Somme des revenus générés. |
| `AVG_TRIP_DURATION_MINUTES` | NUMBER | Durée moyenne des trajets en minutes. |
| `WARNING_TRIP_COUNT` | NUMBER | Nombre de trajets avec avertissement. |
| `NEGATIVE_TRANSACTION_COUNT` | NUMBER | Nombre de trajets avec transaction négative. |