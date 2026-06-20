
from db_connection import run_query


def get_bank_summary(product_id=None, month=None):
    filters = []

    if product_id:
        filters.append(f"tp.product_id = '{product_id}'")

    if month:
        filters.append(f"tp.month = '{month}'")

    where = "WHERE " + " AND ".join(filters) if filters else ""

    return run_query(f"""
        SELECT
            bm.bank_short,
            bm.bank_name,
            bm.bank_type,
            bm.region,
            SUM(tp.total_debit_td) AS total_td,
            AVG(tp.approval_pct) AS avg_appr_pct,
            SUM(tp.bounce_debit_bd) AS total_bd,
            SUM(tp.txn_amount_cr) AS total_amt
        FROM transaction_performance tp
        JOIN bank_master bm
            ON tp.bank_id = bm.bank_id
            AND tp.product_id = bm.product_id
        {where}
        GROUP BY
            bm.bank_short,
            bm.bank_name,
            bm.bank_type,
            bm.region
        ORDER BY total_td DESC
    """)

def get_monthly_trend(bank_id=None, product_id=None):
    filters = []
    if bank_id:
        filters.append(f"tp.bank_id = '{bank_id}'")
    if product_id:
        filters.append(f"tp.product_id = '{product_id}'")
    where = 'WHERE ' + ' AND '.join(filters) if filters else ''
    return run_query(f"""
        SELECT tp.month_label,
               SUM(tp.total_debit_td) AS total_td,
               AVG(tp.approval_pct)   AS avg_appr_pct,
               SUM(tp.bounce_debit_bd) AS total_bd
        FROM transaction_performance tp
        JOIN bank_master bm ON tp.bank_id=bm.bank_id AND tp.product_id=bm.product_id
        {where}
        GROUP BY tp.month_label, tp.month
        ORDER BY tp.month""")

def get_chargeback_summary(product_id=None):
    where = f"WHERE cb.product_id='{product_id}'" if product_id else ''
    return run_query(f"""
        SELECT bm.bank_short, bm.bank_name,
               SUM(cb.cb_raised)      AS total_raised,
               SUM(cb.cb_resolved)    AS total_resolved,
               SUM(cb.cb_pending)     AS total_pending,
               AVG(cb.cb_resolution_days) AS avg_res_days
        FROM chargeback_data cb
        JOIN bank_master bm ON cb.bank_id=bm.bank_id AND cb.product_id=bm.product_id
        {where}
        GROUP BY bm.bank_short, bm.bank_name
        ORDER BY total_pending DESC""")

def get_laggard_banks():
    """Banks with approval% below 98% – red flag banks"""
    return run_query(f"""
        SELECT bm.bank_name, bm.bank_short, bm.region,
               pm.product_name,
               AVG(tp.approval_pct) AS avg_appr_pct,
               SUM(tp.bounce_debit_bd) AS total_bd
        FROM transaction_performance tp
        JOIN bank_master bm ON tp.bank_id=bm.bank_id AND tp.product_id=bm.product_id
        JOIN product_master pm ON tp.product_id=pm.product_id
        GROUP BY bm.bank_name, bm.bank_short, bm.region, pm.product_name
        HAVING AVG(tp.approval_pct) < 98.5
        ORDER BY avg_appr_pct ASC""")

def get_gst_laggards():
    return run_query("""
        SELECT bm.bank_name, bm.bank_short,
               AVG(g.compliance_pct) AS avg_gst_compliance,
               SUM(g.gst_pending_lakh) AS total_pending_lakh
        FROM gst_compliance g
        JOIN bank_master bm ON g.bank_id=bm.bank_id
        GROUP BY bm.bank_name, bm.bank_short
        HAVING AVG(g.compliance_pct) < 95
        ORDER BY avg_gst_compliance ASC""")