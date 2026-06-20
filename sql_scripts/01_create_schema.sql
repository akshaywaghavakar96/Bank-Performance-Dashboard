-- ============================================================
--  BANKING DASHBOARD  –  PostgreSQL Schema
--  Database : banking_dashboard
--  Author   : Banking Analytics Team
--  FY       : 2024-25 (Apr-2024 to Mar-2025)
-- ============================================================

-- Run this entire file in psql or pgAdmin before importing CSVs

-- ─────────────────────────────────────────────
-- 0.  CREATE DATABASE  (run once, as postgres superuser)
-- ─────────────────────────────────────────────
-- CREATE DATABASE banking_dashboard;
-- \c banking_dashboard    -- connect to it in psql

-- ─────────────────────────────────────────────
-- 1.  PRODUCT MASTER
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS product_master (
    product_id      VARCHAR(10)  PRIMARY KEY,   -- PRD001 … PRD005
    product_name    VARCHAR(20)  NOT NULL,       -- UPI, IMPS, AEPS …
    category        VARCHAR(50),
    launch_year     INT,
    regulator       VARCHAR(30)
);

-- ─────────────────────────────────────────────
-- 2.  BANK MASTER   ← JOIN KEY: bank_id + product_id
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bank_master (
    bank_id         VARCHAR(10)  NOT NULL,
    bank_name       VARCHAR(100) NOT NULL,
    bank_short      VARCHAR(10),
    bank_type       VARCHAR(20),               -- Public / Private
    bank_size       VARCHAR(10),               -- Large / Mid / Small
    region          VARCHAR(20),
    product_id      VARCHAR(10)  NOT NULL,     -- FK → product_master.product_id
    product_name    VARCHAR(20),
    rm_name         VARCHAR(100),
    go_live_date    DATE,
    is_active       CHAR(1)      DEFAULT 'Y',
    headquarters    VARCHAR(50),
    PRIMARY KEY (bank_id, product_id),
    FOREIGN KEY (product_id) REFERENCES product_master(product_id)
);

-- ─────────────────────────────────────────────
-- 3.  TRANSACTION PERFORMANCE
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transaction_performance (
    id                SERIAL PRIMARY KEY,
    bank_id           VARCHAR(10)   NOT NULL,
    product_id        VARCHAR(10)   NOT NULL,
    month             DATE          NOT NULL,
    month_label       VARCHAR(15),
    total_debit_td    BIGINT,
    total_credit_td   BIGINT,
    bounce_debit_bd   BIGINT,
    approved_txn      BIGINT,
    approval_pct      NUMERIC(6,2),
    txn_amount_cr     NUMERIC(12,2),           -- in Crores
    FOREIGN KEY (bank_id, product_id) REFERENCES bank_master(bank_id, product_id)
);

-- ─────────────────────────────────────────────
-- 4.  CHARGEBACK DATA
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chargeback_data (
    id                  SERIAL PRIMARY KEY,
    bank_id             VARCHAR(10)   NOT NULL,
    product_id          VARCHAR(10)   NOT NULL,
    month               DATE          NOT NULL,
    month_label         VARCHAR(15),
    cb_raised           INT,
    cb_resolved         INT,
    cb_pending          INT,
    dccb_count          INT,
    cb_resolution_days  NUMERIC(5,1),
    top_reason          VARCHAR(100),
    cb_amount_lakh      NUMERIC(10,2),
    FOREIGN KEY (bank_id, product_id) REFERENCES bank_master(bank_id, product_id)
);

-- ─────────────────────────────────────────────
-- 5.  TCC / RET / RRC
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tcc_ret_rrc (
    id                SERIAL PRIMARY KEY,
    bank_id           VARCHAR(10)   NOT NULL,
    product_id        VARCHAR(10)   NOT NULL,
    month             DATE          NOT NULL,
    month_label       VARCHAR(15),
    tcc_count         INT,
    ret_count         INT,
    rrc_count         INT,
    top_tcc_reason    VARCHAR(100),
    avg_resolution_hr NUMERIC(6,1),
    FOREIGN KEY (bank_id, product_id) REFERENCES bank_master(bank_id, product_id)
);

-- ─────────────────────────────────────────────
-- 6.  DRC – DISPUTE RESOLUTION CASES
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS drc_data (
    id                SERIAL PRIMARY KEY,
    bank_id           VARCHAR(10)   NOT NULL,
    product_id        VARCHAR(10)   NOT NULL,
    month             DATE          NOT NULL,
    month_label       VARCHAR(15),
    drc_opened        INT,
    drc_closed        INT,
    drc_pending       INT,
    closure_pct       NUMERIC(6,2),
    avg_tat_days      NUMERIC(5,1),
    top_dispute_type  VARCHAR(100),
    FOREIGN KEY (bank_id, product_id) REFERENCES bank_master(bank_id, product_id)
);

-- ─────────────────────────────────────────────
-- 7.  GST COMPLIANCE
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS gst_compliance (
    id                SERIAL PRIMARY KEY,
    bank_id           VARCHAR(10)  NOT NULL,
    month             DATE         NOT NULL,
    month_label       VARCHAR(15),
    gst_payable_lakh  NUMERIC(10,2),
    gst_paid_lakh     NUMERIC(10,2),
    gst_pending_lakh  NUMERIC(10,2),
    compliance_pct    NUMERIC(6,2),
    filing_status     VARCHAR(20),
    FOREIGN KEY (bank_id) REFERENCES bank_master(bank_id, product_id)   -- Note: bank_id only join
);
-- Simplify GST FK (bank only, no product):
ALTER TABLE gst_compliance DROP CONSTRAINT IF EXISTS gst_compliance_bank_id_fkey;

-- ─────────────────────────────────────────────
-- 8.  PCOM – PENALTY / COMPLIANCE
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS pcom_data (
    id              SERIAL PRIMARY KEY,
    bank_id         VARCHAR(10)  NOT NULL,
    product_id      VARCHAR(10)  NOT NULL,
    month           DATE         NOT NULL,
    month_label     VARCHAR(15),
    pcom_count      INT,
    penalty_lakh    NUMERIC(8,2),
    pcom_type       VARCHAR(50),
    rectified       CHAR(1),
    FOREIGN KEY (bank_id, product_id) REFERENCES bank_master(bank_id, product_id)
);

-- ─────────────────────────────────────────────
-- 9.  RM SCORECARD
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS rm_scorecard (
    id                  SERIAL PRIMARY KEY,
    bank_id             VARCHAR(10)  NOT NULL,
    month               DATE         NOT NULL,
    month_label         VARCHAR(15),
    rm_name             VARCHAR(100),
    visits_planned      INT,
    visits_completed    INT,
    escalations_raised  INT,
    escalations_closed  INT,
    bank_score          NUMERIC(5,1),
    remarks             VARCHAR(100)
);

-- ─────────────────────────────────────────────
-- 10.  ASP – SERVICE PERFORMANCE
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS asp_data (
    id                SERIAL PRIMARY KEY,
    bank_id           VARCHAR(10)  NOT NULL,
    product_id        VARCHAR(10)  NOT NULL,
    month             DATE         NOT NULL,
    month_label       VARCHAR(15),
    system_uptime_pct NUMERIC(6,2),
    downtime_hrs      NUMERIC(6,2),
    incidents_count   INT,
    p1_incidents      INT,
    avg_response_ms   NUMERIC(8,1),
    sla_breached      CHAR(1),
    FOREIGN KEY (bank_id, product_id) REFERENCES bank_master(bank_id, product_id)
);

-- ─────────────────────────────────────────────
-- INDEXES (for faster dashboard queries)
-- ─────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_tp_bank_product_month  ON transaction_performance(bank_id, product_id, month);
CREATE INDEX IF NOT EXISTS idx_cb_bank_product_month  ON chargeback_data(bank_id, product_id, month);
CREATE INDEX IF NOT EXISTS idx_tcc_bank_product_month ON tcc_ret_rrc(bank_id, product_id, month);
CREATE INDEX IF NOT EXISTS idx_drc_bank_product_month ON drc_data(bank_id, product_id, month);
CREATE INDEX IF NOT EXISTS idx_asp_bank_product_month ON asp_data(bank_id, product_id, month);
CREATE INDEX IF NOT EXISTS idx_pcom_bank_month        ON pcom_data(bank_id, month);
CREATE INDEX IF NOT EXISTS idx_gst_bank_month         ON gst_compliance(bank_id, month);
CREATE INDEX IF NOT EXISTS idx_rm_bank_month          ON rm_scorecard(bank_id, month);
