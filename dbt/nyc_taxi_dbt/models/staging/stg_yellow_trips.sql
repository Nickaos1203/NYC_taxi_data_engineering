
{{ config(materialized='view') }}

WITH base AS (

    SELECT
        *,
        DATEDIFF('second', tpep_pickup_datetime, tpep_dropoff_datetime) AS trip_duration_seconds,
        CASE
            WHEN trip_distance > 0 AND DATEDIFF('second', tpep_pickup_datetime, tpep_dropoff_datetime) > 0
            THEN trip_distance * 3600.0 / DATEDIFF('second', tpep_pickup_datetime, tpep_dropoff_datetime)
            ELSE NULL
        END AS trip_speed_mph
    FROM {{ source('nyc_taxi_raw', 'YELLOW_TRIPS') }}

),

quality AS (

    SELECT
        *,
        /* Anomalies critiques */
        COALESCE(
            trip_distance < 0
            OR trip_distance > 1000
            OR tpep_dropoff_datetime < tpep_pickup_datetime
            OR trip_duration_seconds > 86400
            OR passenger_count < 0
            OR passenger_count > 20,
            FALSE
        ) AS is_invalid,

        /* Anomalies à surveiller */
        COALESCE(
            trip_distance = 0
            OR trip_speed_mph > 100
            OR passenger_count IS NULL
            OR RatecodeID IS NULL
            OR store_and_fwd_flag IS NULL
            OR Airport_fee IS NULL
            OR congestion_surcharge IS NULL,
            FALSE
        ) AS has_warning,

        /* Exception métier */
        COALESCE(total_amount < 0, FALSE)
            AS is_negative_transaction,

        /* Anomalie principale selon l'ordre de priorité */
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
        WHEN trip_distance = 0 AND PULocationID = DOLocationID
            THEN 'ZERO_DISTANCE_SAME_ZONE'
        WHEN trip_distance = 0 AND PULocationID != DOLocationID
            THEN 'ZERO_DISTANCE_DIFFERENT_ZONE'
        ELSE 'NORMAL'
    END AS distance_quality_status

FROM quality
