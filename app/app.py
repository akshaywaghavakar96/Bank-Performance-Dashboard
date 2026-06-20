import dash
from dash import dcc, html, Input, Output, dash_table
import dash_bootstrap_components as dbc
import plotly.express as px
import plotly.graph_objects as go
import pandas as pd

from queries import (
    get_bank_summary,
    get_monthly_trend,
    get_chargeback_summary,
    get_laggard_banks
    
)

from db_connection import run_query


app = dash.Dash(__name__, external_stylesheets=[dbc.themes.BOOTSTRAP])

# ─── Load filter options ─────────────────────────────────────────────

products_df = run_query(
    'SELECT product_id, product_name FROM product_master ORDER BY product_name'
)

banks_df = run_query(
    'SELECT DISTINCT bank_id, bank_name FROM bank_master ORDER BY bank_name'
)

months_df = run_query(
    'SELECT DISTINCT month_label, month FROM transaction_performance ORDER BY month'
)

product_opts = [
    {'label': r['product_name'], 'value': r['product_id']}
    for _, r in products_df.iterrows()
]

bank_opts = [
    {'label': r['bank_name'], 'value': r['bank_id']}
    for _, r in banks_df.iterrows()
]

month_opts = [
    {'label': r['month_label'], 'value': r['month_label']}
    for _, r in months_df.iterrows()
]


CARD_STYLE = {
    'background': '#1B3A6B',
    'color': 'white',
    'borderRadius': '10px',
    'padding': '16px',
    'textAlign': 'center'
}


def kpi_card(title, value, sub='', color='#1B3A6B'):
    return dbc.Col(
        html.Div([
            html.P(
                title,
                style={'font-size': '13px', 'opacity': 0.8}
            ),
            html.H3(
                value,
                style={
                    'font-size': '22px',
                    'font-weight': 'bold',
                    'margin': '4px 0'
                }
            ),
            html.P(
                sub,
                style={'font-size': '12px', 'opacity': 0.7}
            ),
        ], style={**CARD_STYLE, 'background': color}),
        md=3
    )


# ─── LAYOUT ─────────────────────────────────────────────

app.layout = dbc.Container(
    fluid=True,
    children=[

        # Header
        dbc.Row(
            dbc.Col(
                html.H2(
                    'Bank Performance Dashboard – FY 2025-26',
                    style={'background':'#1B3A6B', 'color':'white', 'padding':'16px', 'borderRadius':'8px', 'margin':'10px 0'})),),

# Filters Row
dbc.Row([
    dbc.Col([html.Label('Product:'),
             dcc.Dropdown(id='dd-product',
options=[{'label':'All','value':'ALL'}]+product_opts,
                          value='ALL', clearable=False)], md=3),
    dbc.Col([html.Label('Bank:'),
             dcc.Dropdown(id='dd-bank',
options=[{'label':'All','value':'ALL'}]+bank_opts,
                          value='ALL', clearable=False)], md=4),
    dbc.Col([html.Label('Month:'),
             dcc.Dropdown(id='dd-month',
options=[{'label':'All','value':'ALL'}]+month_opts,
                          value='ALL', clearable=False)], md=3),
    ], style={'margin':'10px 0','padding':'10px', 'background':'#F3F4F6', 'borderRadius':'8px'}),

# KPI Cards
dbc.Row(id='kpi-cards', style={'margin':'10px 0'}),

# Charts Row 1
dbc.Row([
    dbc.Col(dcc.Graph(id='chart-top-banks'), md=8),
    dbc.Col(dcc.Graph(id='chart-appr-dist'), md=4),
]),

# Charts Row 2
dbc.Row([
    dbc.Col(dcc.Graph(id='chart-trend'), md=7),
    dbc.Col(dcc.Graph(id='chart-chargeback'), md=5),
]),

# Red Signal Section
dbc.Row(dbc.Col(html.H5('🔴 Red Signal Banks – Needs Immediate Attention',
style={'color':'#DC2626','background':'#FEE2E2','padding':'10px','borderRadius':'6px',
'margin':'10px 0'}))),
    dbc.Row(dbc.Col(html.Div(id='red-table'))),
]),
# ――― CALLBACKS ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
@app.callback(
    Output('kpi-cards', 'children'),
    Output('chart-top-banks', 'figure'),
    Output('chart-appr-dist', 'figure'),
    Output('chart-trend', 'figure'),
    Output('chart-chargeback', 'figure'),
    Output('red-table', 'children'),
    Input('dd-product', 'value'),
    Input('dd-bank', 'value'),
    Input('dd-month', 'value'),
)
def update_all(product, bank, month):
    pid  = None if product == 'ALL' else product
    bid  = None if bank    == 'ALL' else bank
    mon  = None if month   == 'ALL' else month

    summary = get_bank_summary(pid, mon)
    trend   = get_monthly_trend(bid, pid)
    cb      = get_chargeback_summary(pid)
    laggard = get_laggard_banks()

    # KPI Cards
    total_txn = f"{summary['total_td'].sum()/1e6:.1f}M"
    avg_appr  = f"{summary['avg_appr_pct'].mean():.2f}%"
    total_bd  = f"{summary['total_bd'].sum()/1000:.1f}K"
    total_cr  = f"{summary['total_amt'].sum():.0f} Cr"
    kpis = dbc.Row([
        kpi_card('Total Transactions', total_txn, 'All Products', '#1B3A6B'),
        kpi_card('Avg Approval %',    avg_appr,  'Target: 99%+', '#16A34A'),
        kpi_card('Total Bounced (BD)', total_bd,  'Failed Txns', '#DC2626'),
        kpi_card('Transaction Value',  total_cr,  'INR Crores', '#0F766E'),
    ])

    # Top Banks Bar Chart
    top10 = summary.head(10)
    fig1 = px.bar(top10, x='bank_short', y='total_td', color='bank_type',
                  title='Top 10 Banks by Transaction Volume',
                  labels={'total_td':'Transactions','bank_short':'Bank'},
                  color_discrete_map={'Public':'#2563EB','Private':'#0F766E'})

    # Approval % Distribution
    fig2 = px.box(summary, y='avg_appr_pct',
                  title='Approval % Distribution Across Banks',
                  labels={'avg_appr_pct':'Approval %'})

    # Monthly Trend
    fig3 = go.Figure()
    fig3.add_trace(go.Scatter(x=trend['month_label'], y=trend['total_td'], name='Total TD', mode='lines+markers'))
    fig3.add_trace(go.Scatter(x=trend['month_label'], y=trend['total_bd'], name='Bounced BD', mode='lines+markers', line=dict(color='red')))
    fig3.update_layout(title='Monthly Transaction Trend', xaxis_title='Month', yaxis_title='Count')

    # Chargeback Bar
    top_cb = cb.head(10)
    fig4 = px.bar(top_cb, x='bank_short', y='total_pending',
                  title='Pending Chargebacks by Bank',
                  color='avg_res_days', color_continuous_scale='RdYlGn_r',
                  labels={'total_pending':'Pending CB','bank_short':'Bank'})
    # Red Table
    if laggard.empty:
        red_tbl = html.P('No laggard banks found – all banks performing above threshold!')
    else:
        laggard['avg_appr_pct'] = laggard['avg_appr_pct'].round(2).astype(str) + '%'
        red_tbl = dash_table.DataTable(
            data=laggard.to_dict('records'),
            columns=[{'name':c.replace('_',' ').title(),'id':c} for c in laggard.columns],
            style_header={'backgroundColor':'#DC2626','color':'white','fontWeight':'bold'},
            style_data_conditional=[{'if':{'row_index':'odd'},'backgroundColor':'#FEE2E2'}],
        )

    return kpis, fig1, fig2, fig3, fig4, red_tbl 

if __name__ == '__main__':
    app.run(debug=True, port=8050)