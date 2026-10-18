
-- test sur la classification de la qualité des données
SELECT *
FROM {{ ref('stg_yellow_trips') }}

WHERE (is_invalid AND quality_status != 'INVALID')
    OR (NOT is_invalid 
        AND (has_warning OR is_negative_transaction) 
        AND quality_status != 'WARN')
    OR (NOT is_invalid
        AND NOT has_warning
        AND NOT is_negative_transaction
        AND quality_status != 'VALID')
