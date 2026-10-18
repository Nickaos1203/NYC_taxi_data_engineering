----------------------------------------------------------------------
----------------CREATION DE LA VIEW STG_YELLOW_TRIP-------------------
----------------------------------------------------------------------

-- Création de la view staging STG_YELLOW_TRIP en prenant les données actuelles YELLOW_TRIP, le calcul de la durée de course (trip_duration_second) et la vitesse moyenne de la course en mph (trip_speed_mph)
CREATE OR REPLACE VIEW NYC_TAXI.STAGING.STG_YELLOW_TRIPS AS

WITH base AS (
    SELECT
        *,
        DATEDIFF('second', tpep_pickup_datetime, tpep_dropoff_datetime) AS trip_duration_seconds,

        CASE
            WHEN trip_distance > 0 AND DATEDIFF('second', tpep_pickup_datetime, tpep_dropoff_datetime) > 0
            THEN trip_distance * 3600.0 / DATEDIFF('second', tpep_pickup_datetime, tpep_dropoff_datetime)
            ELSE NULL
        END AS trip_speed_mph

    FROM NYC_TAXI.RAW.YELLOW_TRIPS
),

-- 
quality AS (
    SELECT
        *,

        /* Anomalies critiques */
        (
            trip_distance < 0
            OR trip_distance > 1000
            OR tpep_dropoff_datetime < tpep_pickup_datetime
            OR trip_duration_seconds > 86400
            OR passenger_count < 0
            OR passenger_count > 20
        ) AS is_invalid,

        /* Anomalies à surveiller */
        (
            trip_distance = 0
            OR trip_speed_mph > 100
            OR passenger_count IS NULL
            OR RatecodeID IS NULL
            OR store_and_fwd_flag IS NULL
            OR Airport_fee IS NULL
            OR congestion_surcharge IS NULL
        ) AS has_warning,

        /* Exception métier : remboursement ou correction possible */
        (total_amount < 0) AS is_negative_transaction,

        CASE
            WHEN trip_distance < 0
                THEN 'INVALID_DISTANCE_NEGATIVE'
            WHEN trip_distance > 1000
                THEN 'INVALID_DISTANCE_EXTREME'
            WHEN tpep_dropoff_datetime < tpep_pickup_datetime
                THEN 'INVALID_NEGATIVE_DURATION'
            WHEN trip_duration_seconds > 86400
                THEN 'INVALID_DURATION_OVER_24H'
            WHEN passenger_count < 0 OR passenger_count > 20
                THEN 'INVALID_PASSENGER_COUNT'
            ELSE NULL
        END AS primary_quality_issue

    FROM base
)

SELECT
    *,

    CASE
        WHEN is_invalid THEN 'INVALID'
        WHEN has_warning OR is_negative_transaction THEN 'WARN'
        ELSE 'VALID'
    END AS quality_status,

    CASE
        WHEN trip_distance = 0
         AND PULocationID = DOLocationID
            THEN 'ZERO_DISTANCE_SAME_ZONE'
        WHEN trip_distance = 0
         AND PULocationID != DOLocationID
            THEN 'ZERO_DISTANCE_DIFFERENT_ZONE'
        ELSE 'NORMAL'
    END AS distance_quality_status

FROM quality;


-------------------------------------------------------
------------VERIFICATIONS------------------------------
-------------------------------------------------------

-- vérification du nombre de ligne total
SELECT
    COUNT(*) AS total_rows,
    COUNT_IF(quality_status = 'VALID') AS valid_rows,
    COUNT_IF(quality_status = 'WARN') AS warning_rows,
    COUNT_IF(quality_status = 'INVALID') AS invalid_rows
FROM NYC_TAXI.STAGING.STG_YELLOW_TRIPS;


-- Vérification des anomalies
SELECT
    primary_quality_issue,
    COUNT(*) AS row_count
FROM NYC_TAXI.STAGING.STG_YELLOW_TRIPS
WHERE quality_status = 'INVALID'
GROUP BY primary_quality_issue
ORDER BY row_count DESC;

-- Vérification des exceptions métier
SELECT
    COUNT_IF(is_negative_transaction) AS negative_transactions,
    COUNT_IF(trip_distance = 0) AS zero_distance_trips,
    COUNT_IF(trip_speed_mph > 100) AS high_speed_trips
FROM NYC_TAXI.STAGING.STG_YELLOW_TRIPS;


----------------------------------------------------------------------
----------------CREATION DE LA VIEW DE QUARANTAINE--------------------
----------------------------------------------------------------------

CREATE OR REPLACE VIEW NYC_TAXI.QUARANTINE.INVALID_YELLOW_TRIPS AS
SELECT *
FROM NYC_TAXI.STAGING.STG_YELLOW_TRIPS
WHERE quality_status = 'INVALID';

-- Vérification
SELECT COUNT(*) AS quarantined_rows
FROM NYC_TAXI.QUARANTINE.INVALID_YELLOW_TRIPS;