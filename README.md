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

## 10. Perspectives d'amélioration

Les évolutions envisagées portent sur :

- L'automatisation du chargement des fichiers Parquet dans Snowflake.
- L'amélioration de la gestion des marqueurs Luigi pour détecter les changements de données.
- L'intégration des tests dbt dans un workflow CI/CD.
- L'ajout de nouveaux contrôles de qualité et d'indicateurs de suivi.
- L'amélioration des tableaux de bord Power BI.
