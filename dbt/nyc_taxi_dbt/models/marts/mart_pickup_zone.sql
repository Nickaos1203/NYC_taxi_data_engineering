-- mart par zone géographique
{{ config(
    materialized='table',
    schema='FINAL'
) }}

SELECT
    f.PULocationID AS pickup_location_id,
    z.zone_name AS pickup_zone,
    z.borough AS pickup_borough,
    z.service_zone AS pickup_service_zone,
    COUNT(*) AS trip_count,
    SUM(f.total_amount) AS total_revenue,
    AVG(f.total_amount) AS avg_total_amount,
    AVG(f.trip_distance) AS avg_trip_distance,
    AVG(f.trip_duration_seconds) / 60.0 AS avg_trip_duration_minutes,
    COUNT_IF(f.quality_status = 'WARN') AS warning_trip_count,
    COUNT_IF(f.is_negative_transaction) AS negative_transaction_count

FROM {{ ref('fct_trips') }} AS f

LEFT JOIN {{ ref('dim_zone') }} AS z
    ON f.PULocationID = z.location_id

GROUP BY
    f.PULocationID,
    z.zone_name,
    z.borough,
    z.service_zone
