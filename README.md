# 🏦 Bank Performance Dashboard

**Python · Dash · PostgreSQL · Plotly · Pandas**

> Real-time NPCI payments monitoring across 20 member banks — FY 2024-25

[![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python)](https://python.org)
[![Dash](https://img.shields.io/badge/Dash-2.x-teal?logo=plotly)](https://dash.plotly.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791?logo=postgresql)](https://postgresql.org)
[![Plotly](https://img.shields.io/badge/Plotly-5.x-purple)](https://plotly.com)

---

## 📌 What This Project Does

A full-stack, database-driven analytical dashboard built to monitor and evaluate the performance of member banks across NPCI's payment products (UPI, IMPS, AEPS, NFS, RuPay).

It connects directly to a PostgreSQL database, runs dynamic SQL queries based on active user filters, and renders interactive charts and KPI cards in the browser — all in real-time with zero manual refresh.

**Built to solve a real operational problem:** identifying which banks are lagging on approval rates, accumulating unresolved chargebacks, or breaching SLAs — so the Customer Care Unit (CCU) team can prioritise outreach and intervention.

**Live prototype:** [akshaywaghavakar96.github.io/Dashboard_V2](https://akshaywaghavakar96.github.io/Dashboard_V2/)

---

## ✨ Key Features

| Feature | What It Shows | Business Value |
|---|---|---|
| **4 KPI Cards** | Total transactions (M), Avg approval %, Bounce count (K), Amount (Cr) | Instant FY health check at a glance |
| **Top 10 Banks Chart** | Ranked bar chart by volume, coloured by Public / Private | Volume contribution at a glance |
| **Approval % Box Plot** | Distribution of approval rates across all banks | Spot outliers dragging down the average |
| **Monthly Trend Line** | Total TD and Bounce BD tracked month-over-month | See if quality is improving or degrading |
| **Chargeback Heatmap Bar** | Pending CB per bank, colour-coded by resolution days | Find banks with oldest unresolved disputes |
| **🔴 Red Signal Table** | Auto-flagged banks with approval rate < 98.5% | Immediate action list for the CCU team |
| **3 Dynamic Filters** | Slice all charts by Product, Bank, and Month simultaneously | Any view, any combination |

---

## 🛠️ Tech Stack

| Layer | Tool | Purpose |
|---|---|---|
| Database | PostgreSQL 16 | Stores all bank, product, and transaction data |
| DB Connection | SQLAlchemy + psycopg2-binary | Python ↔ PostgreSQL bridge |
| Data Layer | Pandas 2.x | DataFrame-based query results and transformations |
| Web Framework | Plotly Dash 2.x | Reactive web app — no JavaScript required |
| UI Layout | Dash Bootstrap Components | Responsive 12-column grid |
| Charts | Plotly Express + Graph Objects | Bar, line, box, and colour-scaled charts |
| Config | python-dotenv | Secure credential management via `.env` |
| Production | Gunicorn | WSGI server for cloud deployment |

---

## 📁 Project Structure

```
banking_dashboard/
│
├── app/
│   ├── app.py              ← Layout + Dash callback (presentation layer)
│   ├── queries.py          ← All SQL query functions (data layer)
│   ├── db_connection.py    ← Shared DB engine + run_query() helper
│   ├── .env                ← DB credentials (never committed to Git)
│   └── requirements.txt    ← Python dependencies
│
├── raw_data/               ← 10 source CSV files
│   ├── bank_master.csv     ← Master: 20 banks × 5 products (composite JOIN key)
│   ├── product_master.csv  ← UPI, IMPS, AEPS, NFS, RuPay
│   ├── transaction_performance.csv
│   ├── chargeback_data.csv
│   ├── tcc_ret_rrc.csv
│   ├── drc_data.csv
│   ├── gst_compliance.csv
│   ├── pcom_data.csv
│   ├── rm_scorecard.csv
│   └── asp_data.csv
│
└── sql_scripts/
    ├── 01_create_schema.sql ← Creates all 10 tables with indexes
    └── 02_load_data.sql     ← COPY commands to load CSV data
```

---

## 🗄️ Data Model

Star schema design — two master tables at the centre, eight fact tables joined via a composite key of `bank_id + product_id`.

```
product_master (5 rows)
       │
       │ product_id
       ▼
bank_master (100 rows: 20 banks × 5 products)
       │
       │ bank_id + product_id  ←──── composite join key
       ▼
┌──────────────────────────────────────────────────────┐
│  transaction_performance  │  chargeback_data          │
│  tcc_ret_rrc              │  drc_data                 │
│  pcom_data                │  asp_data                 │
│  gst_compliance (bank_id) │  rm_scorecard (bank_id)   │
└──────────────────────────────────────────────────────┘
     Each with 12 months of FY 2024-25 data
```

| Table | Rows | Key Metrics |
|---|---|---|
| transaction_performance | 1,200 | TD, BD, Approval %, Amount (Cr) |
| chargeback_data | 1,200 | CB raised, resolved, pending, DCCB |
| tcc_ret_rrc | 1,200 | TCC, RET, RRC counts, resolution hrs |
| drc_data | 1,200 | DRC opened, closed, TAT days |
| gst_compliance | 240 | GST payable, paid, compliance % |
| pcom_data | 1,200 | Penalty count, amount in lakhs |
| rm_scorecard | 240 | RM visits, escalations, bank score |
| asp_data | 1,200 | Uptime %, incidents, SLA breach flag |

---

## ⚙️ Architecture — How It Works

### The 3-File Separation of Concerns

```
db_connection.py  →  queries.py  →  app.py  →  Browser
(DB engine)          (SQL layer)    (UI + callbacks)
```

Each file has exactly one job:

- **`db_connection.py`** — Creates the SQLAlchemy engine from `.env` credentials. Exposes a single `run_query(sql)` function that any file can import. Never duplicates the DB connection.

- **`queries.py`** — Five functions, each wrapping one SQL query. Accepts optional filter parameters (`product_id`, `bank_id`, `month`). Dynamically builds the `WHERE` clause from whichever filters are active. Returns a pandas DataFrame.

- **`app.py`** — Defines the full page layout (dropdowns, KPI placeholders, chart containers). One `@app.callback` with 3 Inputs and 6 Outputs — whenever any filter changes, all charts rebuild simultaneously.

### Dynamic SQL Filtering

```python
# queries.py — get_bank_summary() builds the WHERE clause at runtime

filters = []
if product_id:
    filters.append(f"tp.product_id = '{product_id}'")
if month:
    filters.append(f"tp.month = '{month}'")

where = "WHERE " + " AND ".join(filters) if filters else ""
# → "WHERE tp.product_id = 'PRD001' AND tp.month = '2024-06-01'"
# → "" (empty) if both filters are set to 'All'
```

### Red Signal Detection

Laggard bank detection runs entirely in SQL using a `HAVING` clause — no Python-side filtering:

```sql
-- get_laggard_banks() in queries.py
SELECT bm.bank_name, bm.bank_short, bm.region, pm.product_name,
       AVG(tp.approval_pct) AS avg_appr_pct,
       SUM(tp.bounce_debit_bd) AS total_bd
FROM transaction_performance tp
JOIN bank_master bm ON tp.bank_id = bm.bank_id AND tp.product_id = bm.product_id
JOIN product_master pm ON tp.product_id = pm.product_id
GROUP BY bm.bank_name, bm.bank_short, bm.region, pm.product_name
HAVING AVG(tp.approval_pct) < 98.5   -- ← filters on aggregated result
ORDER BY avg_appr_pct ASC
```

---

## 🚀 Local Setup

### Prerequisites
- Python 3.11+
- PostgreSQL 14+ with pgAdmin
- Git

### 1 — Clone the repo

```bash
git clone https://github.com/YOUR_USERNAME/banking-dashboard.git
cd banking-dashboard/app
```

### 2 — Install dependencies

```bash
pip install -r requirements.txt
```

### 3 — Configure credentials

Create `app/.env` (this file is in `.gitignore` — never committed):

```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=banking_dashboard
DB_USER=postgres
DB_PASSWORD=your_password_here
```

### 4 — Create database schema and load data

In pgAdmin query tool, run in order:

```sql
-- Creates all 10 tables with indexes
\i sql_scripts/01_create_schema.sql

-- Loads all CSV files (update the file path to your machine first)
\i sql_scripts/02_load_data.sql
```

### 5 — Start the dashboard

```bash
python app.py
```

Open **http://127.0.0.1:8050** in your browser.

---

## 💡 Skills Demonstrated

| Skill Area | Demonstrated By |
|---|---|
| **SQL & Relational Databases** | Multi-table JOINs, GROUP BY + HAVING, SUM/AVG aggregates, dynamic WHERE, composite PKs, indexed schema design |
| **Python Development** | 3-file modular architecture, f-strings, list comprehensions, pandas DataFrames, env-based config |
| **Data Visualisation** | Plotly Express (bar, box), Plotly Graph Objects (multi-trace line), conditional colouring, colour-continuous scales |
| **Reactive UI / Web Apps** | Dash callback pattern — 3 Inputs → 6 Outputs simultaneously, DB-driven filter dropdowns |
| **Payments Domain** | NPCI product coverage, approval rate monitoring, chargeback lifecycle, TCC/RRC/DRC/PCOM/ASP concepts |
| **Data Modelling** | Star schema with composite keys, FK relationships, 10-table design covering ops + compliance metrics |
| **Analytics Thinking** | Laggard detection with HAVING, red/green classification, FY trend analysis, multi-dimensional slicing |

---

## 🗺️ Roadmap

- [ ] GST Compliance tab — bank-wise compliance % gauge charts
- [ ] RM Scorecard tab — visit completion rate, escalation closure rate
- [ ] ASP / Uptime tab — system availability, P1 incident tracker
- [ ] PCOM Penalties tab — penalty amounts over time, rectification status
- [ ] Excel export — download filtered view as `.xlsx`
- [ ] Cloud deployment — Railway / Render + Supabase
- [ ] Authentication — login gate for authorised users only

---

## 📖 Domain Glossary

| Term | Meaning |
|---|---|
| **NPCI** | National Payments Corporation of India — operates UPI, IMPS, RuPay, AEPS, NFS |
| **CCU** | Customer Care Unit — monitors member banks, resolves disputes, enforces compliance |
| **TD / BD** | Total Debits / Bounce Debits — total transactions attempted vs. failed |
| **Appr%** | Approval Percentage — % of TD successfully processed. Target: 99%+ |
| **CB / DCCB** | Chargeback / Duplicate Chargeback — customer dispute; DCCB = same dispute filed twice |
| **TCC / RET / RRC** | Technical Complaint Case / Return Transaction / Re-credit Request Case |
| **DRC** | Dispute Resolution Case — formal dispute tracked from open to closure |
| **PCOM** | Penalty / Compliance — monetary penalty for SLA or compliance breach |
| **ASP** | Acquirer/Issuer Service Provider — bank's payment system uptime and performance |

---

## 👤 About

Built by **Akshay Waghavakar** — Data Analyst, CCU Team, NPCI, Mumbai.

This project reflects real operational work. The metrics, product names, compliance categories, and team structure are drawn from actual day-to-day experience monitoring NPCI member banks.

Previously all analytics was delivered via SQL, Power BI, and Apache Superset. This dashboard was built independently as a self-learning project in Python.

---

*Banking Performance Dashboard · Python + PostgreSQL · NPCI CCU Analytics · FY 2024-25*
