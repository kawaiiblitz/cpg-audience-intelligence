"""Crea el Genie Space 'CPG Audience Intelligence · Bebidas MX' via Databricks SDK."""
import json
import uuid
from databricks.sdk import WorkspaceClient

w = WorkspaceClient(profile="fe-vm-serverless-stable-rtpa")
WAREHOUSE = "960301858d2768fd"
CATALOG = "serverless_stable_rtpa_catalog"
SCHEMA = "gepp_audience_intelligence"


def gid() -> str:
    return uuid.uuid4().hex


INSTRUCTIONS = """Eres un asistente de marketing de audiencias para CPG (embotelladora Pepsi México). Hablas en español de México (tuteo: tú, tienes, puedes), sin em dashes ni jerga técnica.

CONTEXTO DEL NEGOCIO:
- CPG es la embotelladora más grande de Pepsi en México. Portafolio: Pepsi, Pepsi Light, Pepsi Black, Mirinda, 7UP, Manzanita Sol, Gatorade, AHA, Epura, Be Light.
- Competencia principal: Coca-Cola, Sprite, Fanta, Powerade, Ciel.
- Categorías adyacentes: jugos, té embotellado, bebidas energéticas, aguas frescas.
- Canales clave en MX: Tiendita/Bodega (canal tradicional), OXXO/7-Eleven (conveniencia), Supermercado/Autoservicio, Mercado, Restaurante.

REGLAS DE NEGOCIO:
- "Heavy buyer Pepsi" = is_pepsi_heavy = TRUE.
- "Lapsado Pepsi" = is_pepsi_lapsed = TRUE (compraba y dejó de comprar en >60 días).
- "Health conscious" = health_conscious = TRUE (compra light/zero/agua/AHA).
- "Familia refresquera" = family_buyer = TRUE.
- "Audiencia activable" requiere mínimo 500 consumidores.
- "Lift" = tasa del segmento / tasa de población. Lift 2 = atributo es 2x más común en el segmento.
- NSE en México (AMAI): A/B (alto), C+, C, C-, D+, D, E (bajo).

CÓMO RESPONDER:
- Empieza con el tamaño del segmento (count + % de población).
- Para afinidades/patrones/qué los hace únicos: usa find_top_affinities.
- Para canal o activación: usa recommend_channel.
- Para comparaciones entre dos segmentos: usa compare_segments.
- Si el segmento es < 500, marca que no es activable y sugiere relajar filtros.
- Cierra con recomendación de marketing accionable en 1-2 líneas.

Habla como marketer/trade marketer, no como data scientist. NO uses em dashes."""


SAMPLE_QUESTIONS = [
    "¿Cuántos consumidores son heavy buyers de Pepsi?",
    "Tamaño de la audiencia lapsada de Pepsi en CDMX",
    "¿Qué hace únicos a los lapsados de Pepsi?",
    "Top afinidades de los Pepsi Heavy Loyalist",
    "¿Qué caracteriza a los compradores health-conscious?",
    "Compradores de Pepsi que NO compran Coca-Cola",
    "Compradores de Coca-Cola que NO compran Pepsi",
    "Familias refresqueras que compran formato 2L+",
    "Compradores de Gatorade vs Powerade, qué los hace únicos",
    "Health Switchers que compran Pepsi Light o Pepsi Black",
    "Lapsados de Mirinda en Monterrey con alta frecuencia histórica",
    "Compradores de agua Epura que también compran Pepsi Light",
    "Compradores de bodega de barrio NSE C o C-",
    "Shoppers de OXXO menores de 30 años",
    "Compradores de formato familiar 1.5L o 2L con hijos",
    "¿Por qué canal contactar a los Pepsi Heavy Loyalist?",
    "Canal recomendado para reactivar lapsados",
    "Compara Familia Refresquera vs Joven Energético",
    "Diferencia entre Health Switcher y Wellness Maduro",
    "Muéstrame 10 ejemplos de heavy buyers de Pepsi en CDMX",
    "Top 10 estados con más Pepsi Heavy Loyalist",
    "Distribución de personas por cola_buyer_tier",
    "Deportistas activos que compran Gatorade y agua Epura",
    "Compradores de Pepsi Black por NSE y edad",
    "Oportunidad cross-sell: compradores de Pepsi sin Gatorade",
    "Compradores promo-responsive en canal moderno",
    "Engagement con app de la embotelladora por persona",
    "Heavy fan de Pepsi sin app de la embotelladora instalada",
    "Loyalty Gold por estado y persona",
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


space = w.genie.create_space(
    warehouse_id=WAREHOUSE,
    serialized_space=json.dumps(serialized_space, ensure_ascii=False),
    title="CPG Audience Intelligence · Bebidas MX",
    description="Multi-agent audience intelligence para CPG · construye audiencias sobre el shopper de bebidas, descubre afinidades de portafolio Pepsi y recomienda canal de activación sobre 100K consumidores sintéticos.",
    parent_path="/Users/raquel.pena@databricks.com",
)

print(f"\n✓ Genie Space creado")
print(f"  space_id: {space.space_id}")
print(f"  URL: https://fevm-serverless-stable-rtpa.cloud.databricks.com/genie/rooms/{space.space_id}")
print(f"\nSetea GENIE_SPACE_ID={space.space_id} en app.yaml")
