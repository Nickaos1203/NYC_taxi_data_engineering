-- table de dimension associant chaque identifiant TLC à une zone
{{ config(
    materialized='table',
    schema='FINAL'
) }}

SELECT
    LOCATIONID AS location_id,
    BOROUGH AS borough,
    ZONE AS zone_name,
    SERVICE_ZONE AS service_zone

FROM {{ source('nyc_taxi_raw', 'TAXI_ZONE_LOOKUP') }}
