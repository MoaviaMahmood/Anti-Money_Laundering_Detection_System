CREATE OR REPLACE VIEW aml_db.alerts_enriched AS
SELECT
    a.alert_id,
    a.transaction_id,
    a.customer_id,
    a.alert_type,
    a.alert_score,
    a.created_at,
    a.status,
    c.first_name,
    c.last_name,
    c.country_code AS customer_country,
    c.business_type,
    c.risk_rating  AS customer_risk_rating,
    c.pep_flag,
    t.amount       AS transaction_amount,
    t.currency     AS transaction_currency,
    t.country_origin,
    t.country_dest,
    t.merchant_category,
    a.dt
FROM aml_db.alerts_clean a
LEFT JOIN aml_db.customers_clean c
    ON a.customer_id = c.customer_id
LEFT JOIN aml_db.transactions_clean t
    ON a.transaction_id = t.transaction_id;