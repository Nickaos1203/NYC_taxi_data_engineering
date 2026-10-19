-- mart des courses de taxi quotidiennes
{{ config(
    materialized='table',
    schema='FINAL'
) }}

SELECT
    TO_DATE(tpep_pickup_datetime) AS pickup_date,
    COUNT(*) AS trip_count,
    SUM(total_amount) AS total_revenue,
    SUM(fare_amount) AS total_fare,
    SUM(tip_amount) AS total_tips,
    AVG(total_amount) AS avg_total_amount,
    AVG(trip_distance) AS avg_trip_distance,
    AVG(trip_duration_seconds) / 60.0 AS avg_trip_duration_minutes,
    COUNT_IF(quality_status = 'WARN') AS warning_trip_count,
    COUNT_IF(is_negative_transaction) AS negative_transaction_count

FROM {{ ref('fct_trips') }}

GROUP BY TO_DATE(tpep_pickup_datetime)
