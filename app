import pandas as pd
import plotly.express as px
import streamlit as st

# Configurazione Pagina
st.set_page_config(
    page_title="Le Mie Finanze - Personal App",
    page_icon="💰",
    layout="wide",
    initial_sidebar_state="expanded",
)

st.title("💰 Gestione Finanze Personali")
st.caption("App Dinamica & Personalizzabile | Ciclo dal 10 al 9 del mese")

# --- INIZIALIZZAZIONE PARAMETRI DINAMICI (SESSION STATE) ---
if "stipendio" not in st.session_state:
  st.session_state.stipendio = 1700.0

if "spese_fisse" not in st.session_state:
  st.session_state.spese_fisse = {
      "Affitto + Condominio": 480.0,
      "Finanziamento": 250.0,
      "Luce & Gas (Pulsee)": 90.0,
      "Internet Fibra": 25.0,
      "Acqua & TARI": 25.0,
  }

if "target_risparmio" not in st.session_state:
  st.session_state.target_risparmio = 265.0

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

# --- BARRA LATERALE: IMPOSTAZIONI E MODIFICA PARAMETRI ---
st.sidebar.header("⚙️ Impostazioni & Budget")

# Modifica Stipendio
st.session_state.stipendio = st.sidebar.number_input(
    "💶 Stipendio Netto Mensile (€)",
    value=float(st.session_state.stipendio),
    step=50.0,
)

# Modifica Target Risparmio
st.session_state.target_risparmio = st.sidebar.number_input(
    "🎯 Target Risparmio (€)",
    value=float(st.session_state.target_risparmio),
    step=10.0,
)

# Gestione Spese Fisse
st.sidebar.subheader("📌 Gestione Spese Fisse")
spese_fisse_aggiornate = {}
for voce, valore in st.session_state.spese_fisse.items():
  spese_fisse_aggiornate[voce] = st.sidebar.number_input(
      f"• {voce} (€)", value=float(valore), step=5.0
  )
st.session_state.spese_fisse = spese_fisse_aggiornate

# Aggiungi Nuova Spesa Fissa
with st.sidebar.expander("➕ Aggiungi / Rimuovi Spesa Fissa"):
  nuova_voce_fissa = st.text_input("Nome nuova spesa fissa")
  nuovo_imp_fiss = st.number_input("Importo (€)", min_value=0.0, step=5.0)
  if st.button("Aggiungi Spesa Fissa"):
    if nuova_voce_fissa:
      st.session_state.spese_fisse[nuova_voce_fissa] = nuovo_imp_fiss
      st.rerun()

# --- CALCOLI METRICHE IN TEMPO REALE ---
totale_spese_fisse = sum(st.session_state.spese_fisse.values())
df = st.session_state.transazioni
totale_speso_registrato = (
    df["Importo"].sum() if not df.empty else 0.0
)  # Tutte le transazioni inserite

# Risparmio Effettivo e Budget Giornaliero
disponibile_residuo = st.session_state.stipendio - totale_speso_registrato
budget_giornaliero = max(0.0, disponibile_residuo / 30)

# --- TABS APP ---
tab1, tab2, tab3 = st.tabs(
    ["📊 Dashboard & KPI", "📲 Inserisci Spesa", "📋 Gestisci Transazioni"]
)

# === TAB 1: DASHBOARD ===
with tab1:
  st.subheader("💡 Indicatori Finanziari Chiave")
  k1, k2, k3, k4 = st.columns(4)
  k1.metric("Entrata Netta", f"€ {st.session_state.stipendio:,.2f}")
  k2.metric("Spese Fisse Totali", f"€ {totale_spese_fisse:,.2f}")
  k3.metric(
      "Risparmio Attuale",
      f"€ {disponibile_residuo:,.2f}",
      delta=(
          f"{disponibile_residuo - st.session_state.target_risparmio:,.2f} vs"
          " Target"
      ),
  )
  k4.metric("Disponibile / Giorno", f"€ {budget_giornaliero:,.2f}")

  st.divider()

  col_chart1, col_chart2 = st.columns(2)
  with col_chart1:
    st.subheader("📊 Ripartizione Spese per Categoria")
    if not df.empty:
      fig_pie = px.pie(
          df,
          values="Importo",
          names="Categoria",
          hole=0.4,
          color_discrete_sequence=px.colors.qualitative.Pastel,
      )
      st.plotly_chart(fig_pie, use_container_width=True)
    else:
      st.info("Nessuna transazione registrata.")

  with col_chart2:
    st.subheader("📈 Spese Registrate per Categoria")
    if not df.empty:
      df_cat = df.groupby("Categoria")["Importo"].sum().reset_index()
      fig_bar = px.bar(
          df_cat,
          x="Categoria",
          y="Importo",
          color="Categoria",
          text_auto=".2f",
      )
      st.plotly_chart(fig_bar, use_container_width=True)
    else:
      st.info("Nessuna transazione registrata.")

# === TAB 2: INSERIMENTO SPESA ===
with tab2:
  st.subheader("➕ Inserisci una Nuova Spesa")
  with st.form("form_spesa", clear_on_submit=True):
    c_data, c_cat = st.columns(2)
    with c_data:
      data_spesa = st.date_input("Data")
    with c_cat:
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

    c_desc, c_imp = st.columns(2)
    with c_desc:
      descrizione = st.text_input("Descrizione", placeholder="es. Conad, Cena")
    with c_imp:
      importo = st.number_input("Importo (€)", min_value=0.01, step=1.0)

    submit = st.form_submit_button("💾 Salva Spesa")
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
      st.success("Spesa aggiunta con successo!")
      st.rerun()

# === TAB 3: REGISTRO E MODIFICA TRANSAZIONI ===
with tab3:
  st.subheader("📋 Modifica o Elimina Transazioni")
  st.info(
      "Puoi modificare gli importi direttamente nella tabella qui sotto"
      " oppure selezionare una spesa da eliminare."
  )

  # Tabella modificabile
  df_modificato = st.data_editor(
      st.session_state.transazioni, num_rows="dynamic", use_container_width=True
  )
  if st.button("💾 Salva Modifiche Tabella"):
    st.session_state.transazioni = df_modificato
    st.success("Transazioni aggiornate!")
    st.rerun()
