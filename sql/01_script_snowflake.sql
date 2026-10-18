-- création de la base de données, des schémas et affectation par défaut
CREATE DATABASE IF NOT EXISTS NYC_TAXI;

CREATE SCHEMA IF NOT EXISTS NYC_TAXI.RAW;
CREATE SCHEMA IF NOT EXISTS NYC_TAXI.STAGING;
CREATE SCHEMA IF NOT EXISTS NYC_TAXI.FINAL;
CREATE SCHEMA IF NOT EXISTS NYC_TAXI.QUARANTINE;

USE DATABASE NYC_TAXI;


-- création du data warehouse et affectation par défaut
CREATE WAREHOUSE IF NOT EXISTS NYC_TAXI_WH
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

USE WAREHOUSE NYC_TAXI_WH;


-- création du format parquet
CREATE FILE FORMAT IF NOT EXISTS NYC_TAXI.RAW.PARQUET_FORMAT
TYPE = PARQUET;

SHOW FILE FORMATS IN SCHEMA NYC_TAXI.RAW;


-- création du internal stage (zone d"arrivée des fichiers parquet)
CREATE STAGE IF NOT EXISTS NYC_TAXI.RAW.TLC_STAGE
FILE_FORMAT = NYC_TAXI.RAW.PARQUET_FORMAT;

SHOW STAGES IN SCHEMA NYC_TAXI.RAW;

-- ajouter les fichiers parquets manuellement sur SNowflake

-- voir les fichiers parquet disponible dans TLC_STAGE
LIST @NYC_TAXI.RAW.TLC_STAGE;


-- analyse des types SQL
SELECT *
FROM TABLE(
    INFER_SCHEMA(
        LOCATION => '@NYC_TAXI.RAW.TLC_STAGE',
        FILE_FORMAT => 'NYC_TAXI.RAW.PARQUET_FORMAT'
    )
);


-- Création de la table YELLOW_TRIPS dans le schéma RAW
CREATE OR REPLACE TABLE NYC_TAXI.RAW.YELLOW_TRIPS (
    VendorID                 NUMBER(38,0),
    tpep_pickup_datetime     TIMESTAMP_NTZ,
    tpep_dropoff_datetime    TIMESTAMP_NTZ,
    passenger_count          NUMBER(38,0),
    trip_distance            FLOAT,
    RatecodeID               NUMBER(38,0),
    store_and_fwd_flag       VARCHAR,
    PULocationID             NUMBER(38,0),
    DOLocationID             NUMBER(38,0),
    payment_type             NUMBER(38,0),
    fare_amount              FLOAT,
    extra                    FLOAT,
    mta_tax                  FLOAT,
    tip_amount               FLOAT,
    tolls_amount             FLOAT,
    improvement_surcharge    FLOAT,
    total_amount             FLOAT,
    congestion_surcharge     FLOAT,
    Airport_fee              FLOAT
);

DESC TABLE NYC_TAXI.RAW.YELLOW_TRIPS;


-- chargement des données du fichier parquet dans la table YELLOW_TRIP
COPY INTO NYC_TAXI.RAW.YELLOW_TRIPS
(
    VendorID,
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    passenger_count,
    trip_distance,
    RatecodeID,
    store_and_fwd_flag,
    PULocationID,
    DOLocationID,
    payment_type,
    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    improvement_surcharge,
    total_amount,
    congestion_surcharge,
    Airport_fee
)
FROM (
    SELECT
        $1:VendorID::NUMBER(38,0),

        TO_TIMESTAMP_NTZ(
            $1:tpep_pickup_datetime::NUMBER,
            6
        ),

        TO_TIMESTAMP_NTZ(
            $1:tpep_dropoff_datetime::NUMBER,
            6
        ),

        $1:passenger_count::NUMBER(38,0),
        $1:trip_distance::FLOAT,
        $1:RatecodeID::NUMBER(38,0),
        $1:store_and_fwd_flag::VARCHAR,
        $1:PULocationID::NUMBER(38,0),
        $1:DOLocationID::NUMBER(38,0),
        $1:payment_type::NUMBER(38,0),
        $1:fare_amount::FLOAT,
        $1:extra::FLOAT,
        $1:mta_tax::FLOAT,
        $1:tip_amount::FLOAT,
        $1:tolls_amount::FLOAT,
        $1:improvement_surcharge::FLOAT,
        $1:total_amount::FLOAT,
        $1:congestion_surcharge::FLOAT,
        $1:Airport_fee::FLOAT

    FROM @NYC_TAXI.RAW.TLC_STAGE
)
FILE_FORMAT = (
    FORMAT_NAME = 'NYC_TAXI.RAW.PARQUET_FORMAT'
)
ON_ERROR = 'ABORT_STATEMENT';


-- Vérification du chargement du fichier parquet
SELECT COUNT(*) AS NB_ROWS
FROM NYC_TAXI.RAW.YELLOW_TRIPS
LIMIT 10;


SELECT
    MIN(tpep_pickup_datetime) AS MIN_PICKUP,
    MAX(tpep_pickup_datetime) AS MAX_PICKUP,
    MIN(tpep_dropoff_datetime) AS MIN_DROPOFF,
    MAX(tpep_dropoff_datetime) AS MAX_DROPOFF
FROM NYC_TAXI.RAW.YELLOW_TRIPS;


SELECT *
FROM NYC_TAXI.RAW.YELLOW_TRIPS
LIMIT 10;


-- vérification de la présence du fichier parquet
LIST @NYC_TAXI.RAW.TLC_STAGE;

SELECT *
FROM TABLE(
    INFER_SCHEMA(
        LOCATION => '@NYC_TAXI.RAW.TLC_STAGE',
        FILE_FORMAT => 'NYC_TAXI.RAW.PARQUET_FORMAT'
    )
);