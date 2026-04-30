CREATE OR REPLACE VIEW aml_db.accounts_clean AS WITH latest AS (
        SELECT MAX(dt) AS max_dt
        FROM aml_db.accounts
    )
SELECT account_id,
    customer_id,
    UPPER(account_type) AS account_type,
    UPPER(currency) AS currency,
    CAST(balance AS DECIMAL(18, 2)) AS balance,
    CAST(from_iso8601_timestamp(opened_date) AS TIMESTAMP) AS opened_date,
    UPPER(country_code) AS country_code,
    city,
    CASE
        WHEN LOWER(CAST(is_active AS VARCHAR)) IN ('true', '1') THEN TRUE
        ELSE FALSE
    END AS is_active,
    dt
FROM aml_db.accounts
WHERE dt = (
        SELECT max_dt
        FROM latest
    )
    AND account_id IS NOT NULL
    AND balance IS NOT NULL;