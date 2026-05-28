"""
Generador de población sintética para CPG Audience Intelligence.
CPG / Bebidas México · 100K consumidores · estructura organizacional de la embotelladora real.

Output: data/population_attributes.parquet
"""
from __future__ import annotations

import numpy as np
import polars as pl
from pathlib import Path
from datetime import datetime, timedelta

SEED = 42
N = 100_000
OUT = Path(__file__).parent.parent / "data" / "population_attributes.parquet"

rng = np.random.default_rng(SEED)


def weighted(values, weights, n=N):
    weights = np.array(weights, dtype=float)
    weights = weights / weights.sum()
    return rng.choice(values, size=n, p=weights)


# ---------------------------------------------------------------------
# Estructura organizacional de la embotelladora: Región → Territorio → CEDIS
# ---------------------------------------------------------------------
STATE_TO_REGION = {
    "Ciudad de México": "METRO",
    "Estado de México": "METRO",
    "Guanajuato": "BAJIO",
    "Querétaro": "BAJIO",
    "Puebla": "CENTRO",
    "Veracruz": "CENTRO",
    "Jalisco": "PACIFICO",
    "Yucatán": "PACIFICO",
    "Quintana Roo": "PACIFICO",
    "Nuevo León": "NORTE",
    "Coahuila": "NORTE",
    "Chihuahua": "NORTE",
    "Sonora": "NORTE",
    "Baja California": "NORTE",
}

# Territorios por región (estructura sintética realista)
REGION_TERRITORIES = {
    "METRO":    ["CDMX Norte", "CDMX Sur", "Naucalpan", "Ecatepec"],
    "BAJIO":    ["León", "Querétaro", "Irapuato"],
    "CENTRO":   ["Puebla", "Veracruz Norte", "Xalapa"],
    "PACIFICO": ["Guadalajara", "Vallarta", "Cancún"],
    "NORTE":    ["Monterrey", "Saltillo-Torreón", "Chihuahua-Juárez", "Hermosillo-Tijuana"],
}

# CEDIS por territorio (2 cada uno)
TERRITORY_CEDIS = {
    "CDMX Norte":          ["CEDIS Tlalnepantla", "CEDIS Vallejo"],
    "CDMX Sur":            ["CEDIS Iztapalapa", "CEDIS Coyoacán"],
    "Naucalpan":           ["CEDIS Naucalpan", "CEDIS Cuautitlán"],
    "Ecatepec":            ["CEDIS Ecatepec", "CEDIS Texcoco"],
    "León":                ["CEDIS León Norte", "CEDIS León Sur"],
    "Querétaro":           ["CEDIS Querétaro", "CEDIS San Juan del Río"],
    "Irapuato":            ["CEDIS Irapuato", "CEDIS Celaya"],
    "Puebla":              ["CEDIS Puebla Centro", "CEDIS Cholula"],
    "Veracruz Norte":      ["CEDIS Veracruz", "CEDIS Coatzacoalcos"],
    "Xalapa":              ["CEDIS Xalapa", "CEDIS Córdoba"],
    "Guadalajara":         ["CEDIS Zapopan", "CEDIS Tlaquepaque"],
    "Vallarta":            ["CEDIS Vallarta", "CEDIS Manzanillo"],
    "Cancún":              ["CEDIS Cancún", "CEDIS Mérida"],
    "Monterrey":           ["CEDIS Apodaca", "CEDIS Santa Catarina"],
    "Saltillo-Torreón":    ["CEDIS Saltillo", "CEDIS Torreón"],
    "Chihuahua-Juárez":    ["CEDIS Chihuahua", "CEDIS Ciudad Juárez"],
    "Hermosillo-Tijuana":  ["CEDIS Hermosillo", "CEDIS Tijuana"],
}

STATE_CITY = {
    "Ciudad de México": ["Coyoacán", "Benito Juárez", "Iztapalapa", "Cuauhtémoc", "Tlalpan", "Miguel Hidalgo"],
    "Estado de México": ["Naucalpan", "Ecatepec", "Toluca", "Tlalnepantla", "Nezahualcóyotl"],
    "Jalisco": ["Guadalajara", "Zapopan", "Tlaquepaque", "Tonalá"],
    "Nuevo León": ["Monterrey", "San Pedro", "San Nicolás", "Apodaca", "Guadalupe"],
    "Puebla": ["Puebla", "Cholula", "Tehuacán"],
    "Guanajuato": ["León", "Irapuato", "Celaya", "Guanajuato"],
    "Querétaro": ["Querétaro", "San Juan del Río"],
    "Yucatán": ["Mérida", "Valladolid"],
    "Veracruz": ["Veracruz", "Xalapa", "Coatzacoalcos"],
    "Baja California": ["Tijuana", "Mexicali", "Ensenada"],
    "Chihuahua": ["Chihuahua", "Ciudad Juárez"],
    "Sonora": ["Hermosillo", "Ciudad Obregón"],
    "Quintana Roo": ["Cancún", "Playa del Carmen"],
    "Coahuila": ["Saltillo", "Torreón"],
}
STATE_WEIGHTS = [22, 18, 9, 8, 5, 5, 4, 3, 4, 5, 4, 3, 5, 5]

# ---------------------------------------------------------------------
# 1. Demografía
# ---------------------------------------------------------------------
print("Generando demografía y geografía...")
state = weighted(list(STATE_CITY.keys()), STATE_WEIGHTS)
city = np.array([rng.choice(STATE_CITY[s]) for s in state])
region = np.array([STATE_TO_REGION[s] for s in state])

# Territorio: aleatorio dentro de la región del consumidor
territorio = np.array([
    rng.choice(REGION_TERRITORIES[r]) for r in region
])
# CEDIS: aleatorio dentro del territorio
cedis = np.array([rng.choice(TERRITORY_CEDIS[t]) for t in territorio])

age = rng.choice(
    list(range(15, 76)),
    size=N,
    p=np.array([3 if 18 <= a <= 45 else 2 if a < 60 else 1 for a in range(15, 76)])
    / sum(3 if 18 <= a <= 45 else 2 if a < 60 else 1 for a in range(15, 76)),
)
age_range = pl.Series(age).map_elements(
    lambda a: "15-17" if a < 18 else "18-24" if a < 25 else "25-34" if a < 35 else "35-44" if a < 45 else "45-54" if a < 55 else "55-64" if a < 65 else "65+",
    return_dtype=pl.Utf8,
).to_numpy()

gender = weighted(["F", "M", "Otro"], [49, 49, 2])
household_size = rng.integers(1, 8, size=N)
has_kids = (household_size >= 3) & (rng.random(N) < 0.7)

nse = weighted(["A/B", "C+", "C", "C-", "D+", "D", "E"], [6, 11, 18, 18, 22, 17, 8])
nse_income = {"A/B": 95000, "C+": 50000, "C": 28000, "C-": 18000, "D+": 12000, "D": 8000, "E": 5000}
income_monthly_mxn = np.array([int(nse_income[s] * rng.uniform(0.6, 1.6)) for s in nse])
income_monthly_mxn = np.clip(income_monthly_mxn, 3000, 350_000)

urban_rural = np.where(rng.random(N) < 0.84, "Urbano", "Rural")

household_type = np.where(
    has_kids,
    np.where(rng.random(N) < 0.35, "Familia grande con hijos", "Familia con hijos"),
    np.where(household_size == 1, "Hogar individual",
             np.where(household_size == 2, "Pareja sin hijos", "Hogar compartido"))
)

# ---------------------------------------------------------------------
# 2. Canal de venta CPG (5 categorías)
# ---------------------------------------------------------------------
print("Generando canal de venta...")
def channel_weights(nse_val):
    # Distribución típica de venta de bebidas en MX
    # Tradicional, Moderno, Cuentas Clave, On Premise, Hogar
    if nse_val in ("A/B", "C+"):
        return [22, 32, 24, 14, 8]
    if nse_val in ("C", "C-"):
        return [38, 28, 18, 10, 6]
    return [55, 22, 10, 8, 5]

sales_channel = np.array([
    rng.choice(
        ["Tradicional", "Moderno", "Cuentas Clave", "On Premise", "Hogar"],
        p=np.array(channel_weights(s)) / 100,
    ) for s in nse
])

# Sub-canal específico (más granular)
sub_channel = np.where(
    sales_channel == "Tradicional",
    rng.choice(["Tiendita/Bodega", "Mercado", "Misceláneas"], N, p=[0.65, 0.20, 0.15]),
    np.where(
        sales_channel == "Moderno",
        rng.choice(["OXXO/7-Eleven", "Supermercado regional", "Conveniencia"], N, p=[0.55, 0.30, 0.15]),
        np.where(
            sales_channel == "Cuentas Clave",
            rng.choice(["Walmart/Bodega Aurrera", "Costco/Sam's", "Soriana", "Chedraui"], N, p=[0.45, 0.20, 0.20, 0.15]),
            np.where(
                sales_channel == "On Premise",
                rng.choice(["Restaurante", "Bar/Antro", "Cine/Entretenimiento", "Hotel"], N, p=[0.55, 0.20, 0.15, 0.10]),
                rng.choice(["E-commerce", "Delivery", "Mayoreo a domicilio"], N, p=[0.50, 0.40, 0.10]),
            )
        )
    )
)

# ---------------------------------------------------------------------
# 3. Frecuencia, volumen y presentaciones Pepsi reales
# ---------------------------------------------------------------------
print("Generando frecuencia, volumen y formatos...")
buy_frequency = weighted(
    ["Diaria", "3-5x semana", "1-2x semana", "Quincenal", "Mensual u ocasional"],
    [22, 30, 28, 14, 6],
)
freq_to_units = {"Diaria": 18, "3-5x semana": 10, "1-2x semana": 5, "Quincenal": 2, "Mensual u ocasional": 1}
weekly_units_base = np.array([freq_to_units[f] for f in buy_frequency])
weekly_beverage_units = np.maximum(1, weekly_units_base + rng.integers(-3, 6, N) + (household_size - 2))

# Presentaciones reales de portafolio Pepsi CPG
preferred_format = weighted(
    ["355ml lata", "600ml PET", "1L PET", "2L PET", "3L PET",
     "235ml mini lata", "500ml vidrio retornable", "355ml vidrio nostalgia"],
    [22, 28, 14, 18, 6, 4, 5, 3],
)

# Compra cada formato (multi-select)
buys_355ml_lata = (preferred_format == "355ml lata") | (rng.random(N) < 0.32)
buys_600ml = (preferred_format == "600ml PET") | (rng.random(N) < 0.38)
buys_1L = (preferred_format == "1L PET") | (rng.random(N) < 0.22)
buys_2L = (preferred_format == "2L PET") | (rng.random(N) < 0.28)
buys_3L = (preferred_format == "3L PET") | (rng.random(N) < 0.08)
buys_mini_lata = (preferred_format == "235ml mini lata") | (rng.random(N) < 0.06)
buys_vidrio_retornable = (preferred_format == "500ml vidrio retornable") | (rng.random(N) < 0.08)

# ---------------------------------------------------------------------
# 4. Portafolio Pepsi (CPG)
# ---------------------------------------------------------------------
print("Generando consumo Pepsi y competencia...")
buys_pepsi = rng.random(N) < 0.55
buys_pepsi_light = (rng.random(N) < 0.25) & (buys_pepsi | (rng.random(N) < 0.6))
buys_pepsi_black = rng.random(N) < 0.18
buys_mirinda = rng.random(N) < 0.32
buys_7up = rng.random(N) < 0.28
buys_manzanita = rng.random(N) < 0.22
buys_gatorade = rng.random(N) < 0.34
buys_aha = rng.random(N) < 0.08
buys_epura = rng.random(N) < 0.42
buys_be_light = rng.random(N) < 0.06

# Coca-Cola portfolio (competencia)
buys_coca = rng.random(N) < 0.62
buys_coca_zero = rng.random(N) < 0.22
buys_sprite = rng.random(N) < 0.30
buys_fanta = rng.random(N) < 0.18
buys_powerade = rng.random(N) < 0.22
buys_ciel = rng.random(N) < 0.36

# Adyacentes
buys_jugos = rng.random(N) < 0.40
buys_te = rng.random(N) < 0.22
buys_energetico = (age < 35) & (rng.random(N) < 0.4)
buys_horchata_jamaica = rng.random(N) < 0.28

# ---------------------------------------------------------------------
# 5. Segmentación comportamental
# ---------------------------------------------------------------------
print("Derivando segmentos comportamentales...")
cola_units = (buys_pepsi.astype(int) + buys_coca.astype(int) + buys_pepsi_light.astype(int) +
              buys_pepsi_black.astype(int) + buys_coca_zero.astype(int))
cola_buyer_tier = np.where(
    (weekly_beverage_units > 12) & (cola_units >= 2), "Heavy",
    np.where((weekly_beverage_units > 5) & (cola_units >= 1), "Medium",
             np.where(cola_units >= 1, "Light", "Non-buyer"))
)

pepsi_preference = np.where(
    buys_pepsi & ~buys_coca, "Loyalist Pepsi",
    np.where(~buys_pepsi & buys_coca, "Loyalist Coca",
             np.where(buys_pepsi & buys_coca,
                      np.where(rng.random(N) < 0.5, "Pepsi-leaning switcher", "Coca-leaning switcher"),
                      "No cola"))
)

health_score = (
    buys_pepsi_light.astype(int) * 2 + buys_pepsi_black.astype(int) * 2 +
    buys_coca_zero.astype(int) * 2 + buys_epura.astype(int) +
    buys_ciel.astype(int) + buys_aha.astype(int) * 2 + buys_te.astype(int) +
    buys_be_light.astype(int) * 2 -
    buys_pepsi.astype(int) - buys_coca.astype(int) - buys_energetico.astype(int)
)
health_conscious = health_score >= 2

family_buyer = (preferred_format.astype(str) == "2L PET") | (preferred_format.astype(str) == "3L PET") | (preferred_format.astype(str) == "1L PET")
family_buyer = family_buyer | (has_kids & (rng.random(N) < 0.6))

sport_drink_user = buys_gatorade | buys_powerade
fitness_engagement = np.clip(
    rng.normal(loc=np.where(sport_drink_user, 7, 4), scale=2.5, size=N).round().astype(int), 1, 10
)
energy_drink_user = buys_energetico

last_pepsi_purchase_days = np.where(
    buys_pepsi,
    rng.integers(0, 14, N),
    np.where(rng.random(N) < 0.35, rng.integers(45, 180, N), 999)
)
is_pepsi_lapsed = (last_pepsi_purchase_days > 60) & (last_pepsi_purchase_days < 999)
is_pepsi_active = buys_pepsi & (last_pepsi_purchase_days <= 14)
is_pepsi_heavy = is_pepsi_active & (weekly_beverage_units > 8) & (cola_units >= 2)

# ---------------------------------------------------------------------
# 6. Estrategia comercial CPG (derivada per consumer / PDV asociado)
# ---------------------------------------------------------------------
print("Derivando estrategia comercial...")
# Blindar: heavy buyer + Pepsi loyal + alto valor
# Impulsar: switcher / coca-leaning con volumen (oportunidad de conversión)
# Desarrollar: lapsado / light buyer / no engaged (necesita crecer)
# Conservar: regular buyer Pepsi loyal sin ser heavy
def derive_strategy(idx):
    tier = cola_buyer_tier[idx]
    pref = pepsi_preference[idx]
    lapsed = is_pepsi_lapsed[idx]
    heavy = is_pepsi_heavy[idx]

    if lapsed:
        return "Desarrollar"
    if heavy and pref in ("Loyalist Pepsi", "Pepsi-leaning switcher"):
        return "Blindar"
    if tier == "Heavy" and pref in ("Loyalist Coca", "Coca-leaning switcher"):
        return "Impulsar"
    if tier in ("Light", "Non-buyer"):
        return "Desarrollar"
    if pref in ("Loyalist Pepsi", "Pepsi-leaning switcher"):
        return "Conservar"
    if pref in ("Pepsi-leaning switcher", "Coca-leaning switcher"):
        return "Impulsar"
    return "Desarrollar"

pdv_strategy = np.array([derive_strategy(i) for i in range(N)])

# ---------------------------------------------------------------------
# 7. Otros atributos
# ---------------------------------------------------------------------
price_sensitive = (np.array([nse_income[s] for s in nse]) < 20000) | (rng.random(N) < 0.35)
brand_loyal = rng.random(N) < 0.38
trend_seeker = (age < 35) & (rng.random(N) < 0.4)
pairs_with_snacks = rng.random(N) < 0.62
healthy_lifestyle_score = np.clip(
    rng.normal(loc=np.where(health_conscious, 7, 4), scale=2, size=N).round().astype(int), 1, 10
)

# Momentos de consumo
consumes_with_food = rng.random(N) < 0.65
consumes_party = (age < 50) & (rng.random(N) < 0.55)
consumes_breakfast = rng.random(N) < 0.18
consumes_workout = sport_drink_user & (rng.random(N) < 0.7)
weekend_heavy = rng.random(N) < 0.45

# Engagement digital con CPG
print("Generando engagement digital...")
has_gepp_app = (age < 50) & (rng.random(N) < 0.18)
loyalty_member = has_gepp_app & (rng.random(N) < 0.7)
loyalty_tier = np.where(
    ~loyalty_member, "No miembro",
    np.where(weekly_beverage_units > 12, "Gold",
             np.where(weekly_beverage_units > 6, "Silver", "Bronze"))
)
app_sessions_monthly = np.where(has_gepp_app, rng.integers(2, 30, N), 0)

# Comunicación
email_opt_in = rng.random(N) < 0.42
whatsapp_opt_in = rng.random(N) < 0.58
sms_opt_in = rng.random(N) < 0.34
email_open_rate = np.round(rng.beta(2, 4, size=N), 3) * email_opt_in
whatsapp_response_rate = np.round(rng.beta(3, 4, size=N), 3) * whatsapp_opt_in
push_engagement = np.where(has_gepp_app, np.round(rng.beta(3, 3, size=N), 3), 0.0)
promo_redemption_rate = np.round(rng.beta(2, 4, size=N), 3)
promo_responsive = promo_redemption_rate > 0.35

# ---------------------------------------------------------------------
# 8. Persona derivada
# ---------------------------------------------------------------------
print("Generando personas...")
def persona(row_idx):
    a = age[row_idx]
    h = health_conscious[row_idx]
    f = family_buyer[row_idx]
    e = energy_drink_user[row_idx]
    s = sport_drink_user[row_idx]
    pref = pepsi_preference[row_idx]
    tier = cola_buyer_tier[row_idx]
    if a < 25 and e:
        return "Joven Energético"
    if h and a < 40:
        return "Health Switcher"
    if h:
        return "Wellness Maduro"
    if f:
        return "Familia Refresquera"
    if s:
        return "Deportista Activo"
    if tier == "Heavy" and pref.startswith("Loyalist Pepsi"):
        return "Pepsi Heavy Loyalist"
    if tier == "Heavy":
        return "Cola Heavy User"
    if a > 50:
        return "Maduro Tradicional"
    return "Mainstream Bebida"

persona_tag = np.array([persona(i) for i in range(N)])

def lifecycle(idx):
    if is_pepsi_lapsed[idx]:
        return "Lapsado"
    if not buys_pepsi[idx] and not buys_coca[idx]:
        return "No engaged"
    if is_pepsi_heavy[idx]:
        return "Heavy fan"
    if loyalty_member[idx]:
        return "Loyalty active"
    if has_gepp_app[idx]:
        return "Engaged digital"
    if cola_buyer_tier[idx] == "Light":
        return "Light buyer"
    return "Regular buyer"

lifecycle_stage = np.array([lifecycle(i) for i in range(N)])

# ---------------------------------------------------------------------
# 9. Spend y LTV
# ---------------------------------------------------------------------
weekly_spend_mxn = (weekly_beverage_units * rng.uniform(8, 22, N)).round().astype(int)
monthly_spend_beverages_mxn = (weekly_spend_mxn * 4.3).round().astype(int)
ltv_score = (monthly_spend_beverages_mxn * 12 / 50).round(1)

acquisition_channel = weighted(
    ["Sin app", "App store", "Referido", "Promoción PDV", "Redes sociales", "Loyalty card"],
    [60, 15, 8, 7, 6, 4],
)
today = datetime(2026, 5, 26)
days_since_first_purchase = rng.integers(7, 1825, size=N)
first_purchase_date = np.array(
    [(today - timedelta(days=int(d))).date().isoformat() for d in days_since_first_purchase]
)

consumer_id = np.array([f"CPG{1_000_000 + i:08d}" for i in range(N)])

# ---------------------------------------------------------------------
# Construir DataFrame
# ---------------------------------------------------------------------
df = pl.DataFrame({
    "consumer_id": consumer_id,
    # Demographics
    "age": age,
    "age_range": age_range,
    "gender": gender,
    # Geografía CPG
    "region": region,
    "territorio": territorio,
    "cedis": cedis,
    "state": state,
    "city": city,
    "urban_rural": urban_rural,
    # Hogar
    "household_size": household_size,
    "has_kids": has_kids,
    "household_type": household_type,
    "nse": nse,
    "income_monthly_mxn": income_monthly_mxn,
    # Canal de venta
    "sales_channel": sales_channel,
    "sub_channel": sub_channel,
    # Frecuencia / volumen
    "buy_frequency": buy_frequency,
    "weekly_beverage_units": weekly_beverage_units,
    "preferred_format": preferred_format,
    "weekly_spend_mxn": weekly_spend_mxn,
    "monthly_spend_beverages_mxn": monthly_spend_beverages_mxn,
    # Compra por formato (multi)
    "buys_355ml_lata": buys_355ml_lata,
    "buys_600ml": buys_600ml,
    "buys_1L": buys_1L,
    "buys_2L": buys_2L,
    "buys_3L": buys_3L,
    "buys_mini_lata": buys_mini_lata,
    "buys_vidrio_retornable": buys_vidrio_retornable,
    # Portafolio Pepsi
    "buys_pepsi": buys_pepsi,
    "buys_pepsi_light": buys_pepsi_light,
    "buys_pepsi_black": buys_pepsi_black,
    "buys_mirinda": buys_mirinda,
    "buys_7up": buys_7up,
    "buys_manzanita": buys_manzanita,
    "buys_gatorade": buys_gatorade,
    "buys_aha": buys_aha,
    "buys_epura": buys_epura,
    "buys_be_light": buys_be_light,
    # Competencia Coca-Cola
    "buys_coca": buys_coca,
    "buys_coca_zero": buys_coca_zero,
    "buys_sprite": buys_sprite,
    "buys_fanta": buys_fanta,
    "buys_powerade": buys_powerade,
    "buys_ciel": buys_ciel,
    # Adyacentes
    "buys_jugos": buys_jugos,
    "buys_te": buys_te,
    "buys_energetico": buys_energetico,
    "buys_horchata_jamaica": buys_horchata_jamaica,
    # Comportamiento / tier
    "cola_buyer_tier": cola_buyer_tier,
    "pepsi_preference": pepsi_preference,
    "health_conscious": health_conscious,
    "healthy_lifestyle_score": healthy_lifestyle_score,
    "family_buyer": family_buyer,
    "sport_drink_user": sport_drink_user,
    "energy_drink_user": energy_drink_user,
    "fitness_engagement": fitness_engagement,
    "last_pepsi_purchase_days": last_pepsi_purchase_days,
    "is_pepsi_lapsed": is_pepsi_lapsed,
    "is_pepsi_active": is_pepsi_active,
    "is_pepsi_heavy": is_pepsi_heavy,
    "price_sensitive": price_sensitive,
    "brand_loyal": brand_loyal,
    "trend_seeker": trend_seeker,
    "pairs_with_snacks": pairs_with_snacks,
    # Estrategia comercial CPG
    "pdv_strategy": pdv_strategy,
    # Momentos
    "consumes_with_food": consumes_with_food,
    "consumes_party": consumes_party,
    "consumes_breakfast": consumes_breakfast,
    "consumes_workout": consumes_workout,
    "weekend_heavy": weekend_heavy,
    # CPG digital
    "has_gepp_app": has_gepp_app,
    "loyalty_member": loyalty_member,
    "loyalty_tier": loyalty_tier,
    "app_sessions_monthly": app_sessions_monthly,
    # Engagement comms
    "email_opt_in": email_opt_in,
    "whatsapp_opt_in": whatsapp_opt_in,
    "sms_opt_in": sms_opt_in,
    "email_open_rate": email_open_rate,
    "whatsapp_response_rate": whatsapp_response_rate,
    "push_engagement": push_engagement,
    "promo_redemption_rate": promo_redemption_rate,
    "promo_responsive": promo_responsive,
    # Derived
    "persona_tag": persona_tag,
    "lifecycle_stage": lifecycle_stage,
    "ltv_score": ltv_score,
    "acquisition_channel": acquisition_channel,
    "first_purchase_date": first_purchase_date,
})

df = df.with_columns(pl.col("first_purchase_date").str.to_date())

OUT.parent.mkdir(parents=True, exist_ok=True)
df.write_parquet(OUT)
print(f"\nGenerado: {OUT} · {df.shape[0]:,} filas · {df.shape[1]} columnas")
print(f"Tamaño: {OUT.stat().st_size / 1024 / 1024:.1f} MB")

# Sanity checks
print("\nDistribuciones:")
print(df.group_by("region").len().sort("region"))
print(df.group_by("sales_channel").len().sort("sales_channel"))
print(df.group_by("pdv_strategy").len().sort("pdv_strategy"))
print(df.group_by("preferred_format").len().sort("preferred_format"))
print(df.group_by("territorio").len().sort("territorio"))
print(f"\nPepsi buyers: {df['buys_pepsi'].sum():,} ({df['buys_pepsi'].mean()*100:.1f}%)")
print(f"Coca buyers: {df['buys_coca'].sum():,} ({df['buys_coca'].mean()*100:.1f}%)")
print(f"Pepsi lapsed: {df['is_pepsi_lapsed'].sum():,}")
print(f"Pepsi heavy: {df['is_pepsi_heavy'].sum():,}")
print(f"CPG app users: {df['has_gepp_app'].sum():,}")
