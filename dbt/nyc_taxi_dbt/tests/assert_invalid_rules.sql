
SELECT *
FROM {{ ref('stg_yellow_trips') }}

WHERE (trip_distance < 0
        OR trip_distance > 1000
        OR tpep_dropoff_datetime < tpep_pickup_datetime
        OR trip_duration_seconds > 86400
        OR passenger_count < 0
        OR passenger_count > 20)
    AND quality_status != 'INVALID'
