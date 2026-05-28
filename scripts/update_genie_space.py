"""Actualiza el Genie Space existente con sample questions de las nuevas dimensiones GEPP."""
import json
import uuid
from databricks.sdk import WorkspaceClient

w = WorkspaceClient(profile="fe-vm-serverless-stable-rtpa")
WAREHOUSE = "960301858d2768fd"
CATALOG = "serverless_stable_rtpa_catalog"
SCHEMA = "gepp_audience_intelligence"
SPACE_ID = "01f15916a44e1495a61cb48794045b37"


def gid() -> str:
    return uuid.uuid4().hex


INSTRUCTIONS = """Eres un asistente de marketing/trade marketing para GEPP (embotelladora Pepsi MX). Hablas en español MX (tuteo), sin em dashes ni jerga técnica.

ESTRUCTURA ORGANIZACIONAL GEPP:
- Regiones (5): METRO, BAJIO, CENTRO, PACIFICO, NORTE.
- Cada región tiene varios territorios (ej. Monterrey, León, CDMX Norte).
- Cada territorio tiene CEDIS (centros de distribución).

CANALES DE VENTA GEPP (5):
- Moderno: supermercados, OXXO, conveniencia.
- Tradicional: tiendita, bodega, mercado.
- Hogar: e-commerce, delivery a domicilio.
- On Premise: restaurante, bar, cines.
- Cuentas Clave: Walmart, Costco, Soriana.

ESTRATEGIA COMERCIAL (4):
- Blindar: heavy buyer + Pepsi loyalist + alto valor. Protege lo que ya es nuestro.
- Impulsar: switcher/Coca-leaning con volumen. Convertir.
- Desarrollar: lapsado/light/no engaged. Crecer su consumo.
- Conservar: regular buyer Pepsi loyal. Mantener.

PORTAFOLIO PEPSI: Pepsi, Pepsi Light, Pepsi Black, Mirinda, 7UP, Manzanita Sol, Gatorade, AHA, Epura, Be Light.
COMPETENCIA: Coca-Cola, Coca Zero, Sprite, Fanta, Powerade, Ciel.
PRESENTACIONES: 235ml mini lata, 355ml lata, 600ml PET, 1L PET, 2L PET, 3L PET, 500ml vidrio retornable, 355ml vidrio nostalgia.

REGLAS DE NEGOCIO:
- "Heavy buyer Pepsi" → is_pepsi_heavy = TRUE.
- "Lapsado Pepsi" → is_pepsi_lapsed = TRUE.
- "Health conscious" → health_conscious = TRUE.
- "Audiencia activable" >= 500 consumidores.

CÓMO RESPONDER:
- Empieza con tamaño del segmento.
- find_top_affinities para qué los hace únicos.
- recommend_channel para activación.
- compare_segments para diferencias entre dos.
- Si <500, no activable, sugiere relajar filtros.
- Cierra con acción de trade marketing en 1-2 líneas.

Habla como marketer/trade, no como data scientist. NO uses em dashes."""


SAMPLE_QUESTIONS = [
    # Estrategia comercial
    "Consumidores con estrategia Blindar en la región NORTE",
    "¿Qué hace únicos a los consumidores con estrategia Impulsar en BAJIO?",
    "Distribución de la estrategia comercial por región",
    "Top territorios con más consumidores Blindar",
    "Lapsados de Pepsi a Desarrollar en territorio Monterrey",

    # Regiones
    "Tamaño de audiencia heavy buyer Pepsi en región METRO",
    "Heavy fans de Pepsi por región",
    "Compara la región METRO vs NORTE en consumo de Pepsi",
    "Compara BAJIO vs PACIFICO en preferencia Pepsi vs Coca",
    "Distribución de consumidores por territorio en la región CENTRO",

    # Canales de venta
    "Consumidores que compran en canal Tradicional",
    "Compradores de Pepsi 2L en canal Moderno",
    "Lapsados de Pepsi en canal Cuentas Clave",
    "Health Switchers en canal On Premise",
    "Compradores de Hogar (e-commerce) que prefieren Pepsi Black",
    "Diferencia entre canal Moderno y Tradicional en consumo Pepsi",

    # Presentaciones
    "Compradores de Pepsi 2L familiar",
    "Compradores de lata 355ml en NORTE",
    "Heavy buyers de Pepsi en presentación 600ml PET",
    "Compradores de vidrio retornable por región",
    "Familias refresqueras que compran 3L PET",

    # Cross-portafolio
    "Compradores de Pepsi que NO compran Coca-Cola por región",
    "Compradores de Gatorade y Epura juntos",
    "Pepsi Light + AHA: tamaño de audiencia",
    "Health Switchers que compran Pepsi Black o Be Light",
    "Compradores de energéticos por edad y región",

    # Sample / preview
    "Muéstrame 10 consumidores Blindar en territorio Monterrey",
    "Ejemplos de Impulsar en BAJIO con alto LTV",
    "Top consumidores Heavy fan en CEDIS León Norte",

    # Activación / canal
    "Mejor canal para activar Blindar en NORTE",
    "Cómo reactivar lapsados de Pepsi en canal Tradicional",
    "Estrategia para Cuentas Clave con compradores Pepsi 2L",
]


serialized_space = {
    "version": 2,
    "config": {
        "sample_questions": [
            {"id": gid(), "question": [q]} for q in SAMPLE_QUESTIONS
        ]
    },
    "data_sources": {
        "tables": [
            {"identifier": f"{CATALOG}.{SCHEMA}.population_attributes"},
            {"identifier": f"{CATALOG}.{SCHEMA}.population_baseline_rates"},
        ],
    },
    "instructions": {
        "text_instructions": [
            {"id": gid(), "content": [INSTRUCTIONS]}
        ]
    },
}


# Update existing space
result = w.genie.update_space(
    space_id=SPACE_ID,
    warehouse_id=WAREHOUSE,
    serialized_space=json.dumps(serialized_space, ensure_ascii=False),
    title="GEPP Audience Intelligence · Bebidas MX",
    description="Multi-agent audience intelligence para GEPP · estructura organizacional (región, territorio, CEDIS), canales de venta GEPP, estrategia comercial (Blindar/Impulsar/Desarrollar/Conservar) y portafolio Pepsi con presentaciones reales.",
)

print(f"✓ Genie Space actualizado: {SPACE_ID}")
print(f"  URL: https://fevm-serverless-stable-rtpa.cloud.databricks.com/genie/rooms/{SPACE_ID}")
