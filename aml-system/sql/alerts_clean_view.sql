CREATE OR REPLACE VIEW aml_db.alerts_clean AS
SELECT alert_id,
    transaction_id,
    customer_id,
    alert_type,
    CAST(alert_score AS DOUBLE) AS alert_score,
    CAST(from_iso8601_timestamp(created_at) AS TIMESTAMP) AS created_at,
    UPPER(status) AS status,
    dt
FROM aml_db.alerts_realtime
WHERE alert_id IS NOT NULL
    AND alert_score IS NOT NULL
    AND CAST(alert_score AS DOUBLE) BETWEEN 0 AND 100;