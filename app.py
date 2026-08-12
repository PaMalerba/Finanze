import pandas as pd
import plotly.express as px
import streamlit as st

# Configurazione della Pagina
st.set_page_config(
    page_title="Le Mie Finanze",
    page_icon="💰",
    layout="wide",
    initial_sidebar_state="collapsed",
)

# Titolo App
st.title("💰 Gestione Finanze Personali")
st.caption("Ciclo mensile dal 10 al 9 del mese successivo | Stipendio: € 1.700")

# --- PARAMETRI DI BASE ---
stipendio = 1700.0
target_risparmio = 265.0

# Dati di esempio iniziali per mostrare la dashboard
if "transazioni" not in st.session_state:
  st.session_state.transazioni = pd.DataFrame([
      {
          "Data": "2026-09-10",
          "Categoria": "Spese Fisse",
          "Descrizione": "Affitto + Condominio",
          "Importo": 480.0,
      },
      {
          "Data": "2026-09-10",
          "Categoria": "Spese Fisse",
          "Descrizione": "Finanziamento",
          "Importo": 250.0,
      },
      {
          "Data": "2026-09-11",
          "Categoria": "Spesa Alimentare",
          "Descrizione": "Supermercato",
          "Importo": 55.40,
      },
      {
          "Data": "2026-09-12",
          "Categoria": "Sport",
          "Descrizione": "Tennis / Calcetto",
          "Importo": 12.00,
      },
      {
          "Data": "2026-09-15",
          "Categoria": "Svago / Uscite",
          "Descrizione": "Cena fuori",
          "Importo": 32.00,
      },
  ])

# --- MODULO PER AGGIUNGERE UNA NUOVA SPESA ---
st.subheader("📲 Inserisci Spesa Rapida")
with st.form("form_spesa", clear_on_submit=True):
  col_data, col_cat = st.columns(2)
  with col_data:
    data_spesa = st.date_input("Data")
  with col_cat:
    categoria = st.selectbox(
        "Categoria",
        [
            "Spesa Alimentare",
            "Sport",
            "Svago / Uscite",
            "Abbonamenti",
            "Spese Fisse",
            "Altro",
        ],
    )

  col_desc, col_imp = st.columns(2)
  with col_desc:
    descrizione = st.text_input("Descrizione", placeholder="es. Conad, Cena")
  with col_imp:
    importo = st.number_input("Importo (€)", min_value=0.01, step=1.0)

  submit = st.form_submit_button("➕ Salva Spesa")
  if submit:
    nuova_riga = pd.DataFrame([{
        "Data": str(data_spesa),
        "Categoria": categoria,
        "Descrizione": descrizione,
        "Importo": importo,
    }])
    st.session_state.transazioni = pd.concat(
        [st.session_state.transazioni, nuova_riga], ignore_index=True
    )
    st.success("Spesa registrata con successo!")

# --- CALCOLI METRICHE ---
df = st.session_state.transazioni
totale_speso = df["Importo"].sum()
risparmio_attuale = stipendio - totale_speso
budget_giornaliero = max(0.0, risparmio_attuale / 30)

st.divider()

# --- INDICATORI KPI ---
k1, k2, k3, k4 = st.columns(4)
k1.metric("Stipendio Netto", f"€ {stipendio:,.2f}")
k2.metric("Speso Totale", f"€ {totale_speso:,.2f}")
k3.metric("Risparmio Netto", f"€ {risparmio_attuale:,.2f}")
k4.metric("Disponibile / Giorno", f"€ {budget_giornaliero:,.2f}")

st.divider()

# --- GRAFICI INTERATTIVI ---
c1, c2 = st.columns(2)
with c1:
  st.subheader("📊 Ripartizione Spese")
  fig_pie = px.pie(
      df,
      values="Importo",
      names="Categoria",
      hole=0.4,
      color_discrete_sequence=px.colors.qualitative.Pastel,
  )
  st.plotly_chart(fig_pie, use_container_width=True)

with c2:
  st.subheader("📈 Totale per Categoria")
  df_cat = df.groupby("Categoria")["Importo"].sum().reset_index()
  fig_bar = px.bar(
      df_cat,
      x="Categoria",
      y="Importo",
      color="Categoria",
      text_auto=".2f",
  )
  st.plotly_chart(fig_bar, use_container_width=True)

# --- TABELLA DISSOCIANTE TRANSAZIONI ---
st.subheader("📋 Registro Spese")
st.dataframe(df, use_container_width=True)
