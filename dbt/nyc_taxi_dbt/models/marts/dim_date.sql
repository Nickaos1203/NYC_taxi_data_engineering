-- table de dimension DATE
{{ config(
    materialized='table',
    schema='FINAL'
) }}

WITH bounds AS (

    SELECT
        MIN(TO_DATE(tpep_pickup_datetime)) AS min_date,
        MAX(TO_DATE(tpep_pickup_datetime)) AS max_date
    FROM {{ ref('fct_trips') }}
    WHERE tpep_pickup_datetime IS NOT NULL

),

date_spine (date_day, max_date) AS (

    SELECT
        min_date,
        max_date
    FROM bounds
    WHERE min_date IS NOT NULL

    UNION ALL

    SELECT
        DATEADD(day, 1, date_day),
        max_date
    FROM date_spine
    WHERE date_day < max_date

)

SELECT
    date_day AS date_key,

    YEAR(date_day) AS year,

    QUARTER(date_day) AS quarter,

    MONTH(date_day) AS month_number,

    MONTHNAME(date_day) AS month_name,

    DAY(date_day) AS day_number,

    DAYOFWEEKISO(date_day) AS day_of_week_number,

    DAYNAME(date_day) AS day_name,

    CASE
        WHEN DAYOFWEEKISO(date_day) IN (6, 7)
            THEN TRUE
        ELSE FALSE
    END AS is_weekend

FROM date_spine
