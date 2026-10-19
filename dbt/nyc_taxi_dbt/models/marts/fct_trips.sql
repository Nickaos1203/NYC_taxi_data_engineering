-- création de la table de faits
{{ config(
    materialized='table',
    schema='FINAL'
) }}

SELECT
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
    Airport_fee,

    trip_duration_seconds,
    trip_speed_mph,

    quality_status,
    has_warning,
    is_negative_transaction,
    distance_quality_status,

    TO_DATE(tpep_pickup_datetime) AS pickup_date,
    PULocationID AS pickup_location_id

FROM {{ ref('stg_yellow_trips') }}

WHERE quality_status IN ('VALID', 'WARN')
