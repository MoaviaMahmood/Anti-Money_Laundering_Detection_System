CREATE OR REPLACE VIEW aml_db.transactions_clean AS
SELECT
    transaction_id,
    CAST(from_iso8601_timestamp(timestamp) AS TIMESTAMP) AS event_time,
    sender_account,
    receiver_account,
    sender_customer,
    receiver_customer,
    CAST(amount AS DECIMAL(18,2)) AS amount,
    UPPER(currency) AS currency,
    transaction_type,
    merchant_category,
    location_city,
    UPPER(location_country) AS location_country,
    device_used,
    UPPER(country_origin) AS country_origin,
    UPPER(country_dest) AS country_dest,
    CASE 
        WHEN LOWER(CAST(is_suspicious AS VARCHAR)) IN ('true', '1') THEN TRUE
        ELSE FALSE
    END AS is_suspicious,
    aml_pattern,
    CAST(alert_score AS DOUBLE) AS alert_score,
    dt
FROM aml_db.transactions
WHERE
    transaction_id IS NOT NULL
    AND CAST(amount AS DECIMAL(18,2)) > 0
    AND CAST(amount AS DECIMAL(18,2)) < 100000000
    AND sender_account IS NOT NULL
    AND receiver_account IS NOT NULL
    AND sender_account <> receiver_account
    AND CAST(from_iso8601_timestamp(timestamp) AS TIMESTAMP) <= current_timestamp;