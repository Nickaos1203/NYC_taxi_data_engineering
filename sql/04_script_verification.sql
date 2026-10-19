-- Vérification du nombre de lignes
SELECT COUNT(*)
FROM NYC_TAXI.STAGING.STG_YELLOW_TRIPS;


-- Vérification de la qualité des lignes
SELECT
    quality_status,
    COUNT(*) AS nb_lignes
FROM NYC_TAXI.STAGING.STG_YELLOW_TRIPS
GROUP BY quality_status
ORDER BY quality_status;


-- Vérification les catégories d'anomalies
SELECT
    primary_quality_issue,
    COUNT(*) AS nb_lignes
FROM NYC_TAXI.STAGING.STG_YELLOW_TRIPS
WHERE quality_status = 'INVALID'
GROUP BY primary_quality_issue
ORDER BY nb_lignes DESC;


-- Vérification des lignes présentes dans les couches staging, quarantine et final
SELECT
    'STAGING' AS layer,
    COUNT(*) AS nb_rows
FROM NYC_TAXI.STAGING.STG_YELLOW_TRIPS

UNION ALL

SELECT
    'QUARANTINE' AS layer,
    COUNT(*) AS nb_rows
FROM NYC_TAXI.QUARANTINE.INVALID_YELLOW_TRIPS

UNION ALL

SELECT
    'FINAL' AS layer,
    COUNT(*) AS nb_rows
FROM NYC_TAXI.FINAL.FCT_TRIPS;


-- Vérification de la création de la table mart_daily_trips
SELECT *
FROM NYC_TAXI.FINAL.MART_DAILY_TRIPS
ORDER BY pickup_date;


-- Vérification de la création de la table mart_pickup_zone
SELECT *
FROM NYC_TAXI.FINAL.MART_PICKUP_ZONE
ORDER BY trip_count DESC
LIMIT 10;


-- vérification de DIM_ZONE
SELECT
    COUNT(*) AS nb_zones,
    COUNT(DISTINCT location_id) AS nb_ids_distinct,
    COUNT_IF(location_id IS NULL) AS ids_nuls
FROM NYC_TAXI.FINAL.DIM_ZONE;


SELECT *
FROM NYC_TAXI.FINAL.DIM_ZONE
ORDER BY location_id
LIMIT 10;


-- Vérification de la table MART_PICKUP_ZONE
SELECT
    pickup_location_id,
    pickup_borough,
    pickup_zone,
    trip_count,
    total_revenue
FROM NYC_TAXI.FINAL.MART_PICKUP_ZONE
ORDER BY trip_count DESC
LIMIT 10;

SELECT
    SUM(trip_count) AS total_trips,
    SUM(total_revenue) AS total_revenue,
    COUNT_IF(pickup_zone IS NULL) AS zones_non_reconnues
FROM NYC_TAXI.FINAL.MART_PICKUP_ZONE;


-- Vérification de la table DIM_TABLE
SELECT
    COUNT(*) AS nb_dates,
    MIN(date_key) AS premiere_date,
    MAX(date_key) AS derniere_date
FROM NYC_TAXI.FINAL.DIM_DATE;
