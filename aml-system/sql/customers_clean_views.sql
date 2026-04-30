CREATE OR REPLACE VIEW aml_db.customers_clean AS WITH latest AS (
        SELECT MAX(dt) AS max_dt
        FROM aml_db.customers
    )
SELECT customer_id,
    TRIM(first_name) AS first_name,
    TRIM(last_name) AS last_name,
    UPPER(country_code) AS country_code,
    city,
    UPPER(risk_rating) AS risk_rating,
    business_type,
    CASE
        WHEN LOWER(CAST(pep_flag AS VARCHAR)) IN ('true', '1') THEN TRUE
        ELSE FALSE
    END AS pep_flag,
    CAST(
        from_iso8601_timestamp(created_date) AS TIMESTAMP
    ) AS created_date,
    dt
FROM aml_db.customers
WHERE dt = (
        SELECT max_dt
        FROM latest
    )
    AND customer_id IS NOT NULL;