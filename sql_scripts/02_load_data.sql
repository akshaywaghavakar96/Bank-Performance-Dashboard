-- ============================================================
--  STEP 2 – LOAD CSV DATA INTO POSTGRESQL
--  Run this AFTER 01_create_schema.sql
--  IMPORTANT: Change the path below to where your CSV files are
-- ============================================================

-- ⚠️  IMPORTANT: Replace C:/Users/YourName/banking_dashboard/raw_data/
--    with the actual folder path on your computer

-- ORDER MATTERS: Load master tables FIRST, then child tables

-- 1. Product Master (must be first)
COPY product_master (product_id, product_name, category, launch_year, regulator)
FROM 'C:/Users/YourName/banking_dashboard/raw_data/product_master.csv'
WITH (FORMAT CSV, HEADER TRUE);

-- 2. Bank Master (depends on product_master)
COPY bank_master (bank_id, bank_name, bank_short, bank_type, bank_size,
                  region, product_id, product_name, rm_name, go_live_date,
                  is_active, headquarters)
FROM 'C:/Users/YourName/banking_dashboard/raw_data/bank_master.csv'
WITH (FORMAT CSV, HEADER TRUE);

-- 3. Transaction Performance
COPY transaction_performance (bank_id, product_id, month, month_label,
     total_debit_td, total_credit_td, bounce_debit_bd, approved_txn,
     approval_pct, txn_amount_cr)
FROM 'C:/Users/YourName/banking_dashboard/raw_data/transaction_performance.csv'
WITH (FORMAT CSV, HEADER TRUE);

-- 4. Chargeback Data
COPY chargeback_data (bank_id, product_id, month, month_label,
     cb_raised, cb_resolved, cb_pending, dccb_count,
     cb_resolution_days, top_reason, cb_amount_lakh)
FROM 'C:/Users/YourName/banking_dashboard/raw_data/chargeback_data.csv'
WITH (FORMAT CSV, HEADER TRUE);

-- 5. TCC / RET / RRC
COPY tcc_ret_rrc (bank_id, product_id, month, month_label,
     tcc_count, ret_count, rrc_count, top_tcc_reason, avg_resolution_hr)
FROM 'C:/Users/YourName/banking_dashboard/raw_data/tcc_ret_rrc.csv'
WITH (FORMAT CSV, HEADER TRUE);

-- 6. DRC
COPY drc_data (bank_id, product_id, month, month_label,
     drc_opened, drc_closed, drc_pending, closure_pct,
     avg_tat_days, top_dispute_type)
FROM 'C:/Users/YourName/banking_dashboard/raw_data/drc_data.csv'
WITH (FORMAT CSV, HEADER TRUE);

-- 7. GST Compliance
COPY gst_compliance (bank_id, month, month_label,
     gst_payable_lakh, gst_paid_lakh, gst_pending_lakh,
     compliance_pct, filing_status)
FROM 'C:/Users/YourName/banking_dashboard/raw_data/gst_compliance.csv'
WITH (FORMAT CSV, HEADER TRUE);

-- 8. PCOM Data
COPY pcom_data (bank_id, product_id, month, month_label,
     pcom_count, penalty_lakh, pcom_type, rectified)
FROM 'C:/Users/YourName/banking_dashboard/raw_data/pcom_data.csv'
WITH (FORMAT CSV, HEADER TRUE);

-- 9. RM Scorecard
COPY rm_scorecard (bank_id, month, month_label, rm_name,
     visits_planned, visits_completed, escalations_raised,
     escalations_closed, bank_score, remarks)
FROM 'C:/Users/YourName/banking_dashboard/raw_data/rm_scorecard.csv'
WITH (FORMAT CSV, HEADER TRUE);

-- 10. ASP Data
COPY asp_data (bank_id, product_id, month, month_label,
     system_uptime_pct, downtime_hrs, incidents_count,
     p1_incidents, avg_response_ms, sla_breached)
FROM 'C:/Users/YourName/banking_dashboard/raw_data/asp_data.csv'
WITH (FORMAT CSV, HEADER TRUE);

-- ─────────────────────────────────────────────
-- VERIFY – Row counts after loading
-- ─────────────────────────────────────────────
SELECT 'product_master'        AS table_name, COUNT(*) AS rows FROM product_master
UNION ALL
SELECT 'bank_master',                          COUNT(*) FROM bank_master
UNION ALL
SELECT 'transaction_performance',              COUNT(*) FROM transaction_performance
UNION ALL
SELECT 'chargeback_data',                      COUNT(*) FROM chargeback_data
UNION ALL
SELECT 'tcc_ret_rrc',                          COUNT(*) FROM tcc_ret_rrc
UNION ALL
SELECT 'drc_data',                             COUNT(*) FROM drc_data
UNION ALL
SELECT 'gst_compliance',                       COUNT(*) FROM gst_compliance
UNION ALL
SELECT 'pcom_data',                            COUNT(*) FROM pcom_data
UNION ALL
SELECT 'rm_scorecard',                         COUNT(*) FROM rm_scorecard
UNION ALL
SELECT 'asp_data',                             COUNT(*) FROM asp_data;
