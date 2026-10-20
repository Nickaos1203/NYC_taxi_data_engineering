
{{ config(
    materialized='table',
    schema='FINAL'
) }}

SELECT
    TO_DATE(tpep_pickup_datetime) AS pickup_date,

    DATE_PART(
        hour,
        tpep_pickup_datetime
    ) AS pickup_hour,

    DAYOFWEEKISO(
        tpep_pickup_datetime
    ) AS pickup_day_of_week_number,

    DAYNAME(
        tpep_pickup_datetime
    ) AS pickup_day_name,

    COUNT(*) AS trip_count,

    SUM(total_amount) AS total_revenue,

    AVG(trip_duration_seconds) / 60.0
        AS avg_trip_duration_minutes,

    COUNT_IF(quality_status = 'WARN')
        AS warning_trip_count,

    COUNT_IF(is_negative_transaction)
        AS negative_transaction_count

FROM {{ ref('fct_trips') }}

WHERE tpep_pickup_datetime IS NOT NULL

GROUP BY
    TO_DATE(tpep_pickup_datetime),
    DATE_PART(hour, tpep_pickup_datetime),
    DAYOFWEEKISO(tpep_pickup_datetime),
    DAYNAME(tpep_pickup_datetime)
