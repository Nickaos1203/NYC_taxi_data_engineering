-- table conservant les lignes invalides
{{ config(
    materialized='table',
    schema='QUARANTINE'
) }}

SELECT *
FROM {{ ref('stg_yellow_trips') }}
WHERE quality_status = 'INVALID'
