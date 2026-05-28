"""
GEPP Audience Intelligence Multi-Agent Core (v2)
Estructura GEPP: región, territorio, CEDIS, canal de venta, estrategia comercial.
"""
from __future__ import annotations

import json
import os
import time
from dataclasses import dataclass
from typing import Any, Optional

import requests

try:
    from databricks.sdk import WorkspaceClient
    _SDK_AVAILABLE = True
except ImportError:
    _SDK_AVAILABLE = False


_RAW_HOST = os.environ.get(
    "DATABRICKS_HOST", "https://fevm-serverless-stable-rtpa.cloud.databricks.com"
).rstrip("/")
WORKSPACE_HOST = _RAW_HOST if _RAW_HOST.startswith("http") else f"https://{_RAW_HOST}"
WAREHOUSE_ID = os.environ.get("DATABRICKS_WAREHOUSE_ID", "960301858d2768fd")
GENIE_SPACE_ID = os.environ.get("GENIE_SPACE_ID", "")
CATALOG = os.environ.get("CATALOG", "serverless_stable_rtpa_catalog")
SCHEMA = os.environ.get("SCHEMA", "gepp_audience_intelligence")
LLM_ENDPOINT = os.environ.get("LLM_ENDPOINT", "databricks-claude-sonnet-4")
DEV_MODE = os.environ.get("AUDIENCE_DEMO_DEV", "0") == "1"

_sdk_token_cache: dict[str, Any] = {"token": None, "expires_at": 0.0}


def _token() -> str:
    t = os.environ.get("DATABRICKS_TOKEN") or os.environ.get("DATABRICKS_PAT")
    if t:
        return t
    if _SDK_AVAILABLE:
        now = time.time()
        if _sdk_token_cache["token"] and _sdk_token_cache["expires_at"] > now + 60:
            return _sdk_token_cache["token"]
        try:
            w = WorkspaceClient()
            auth_headers = w.config.authenticate()
            token = (auth_headers.get("Authorization") or "").replace("Bearer ", "")
            if token:
                _sdk_token_cache["token"] = token
                _sdk_token_cache["expires_at"] = now + 540
                return token
        except Exception as e:
            if not DEV_MODE:
                raise RuntimeError(f"SDK auth failed: {e}")
    if DEV_MODE:
        return ""
    raise RuntimeError("No hay credenciales")


def _headers() -> dict[str, str]:
    return {"Authorization": f"Bearer {_token()}", "Content-Type": "application/json"}


def execute_sql(statement: str, timeout_sec: int = 30) -> dict[str, Any]:
    url = f"{WORKSPACE_HOST}/api/2.0/sql/statements"
    payload = {
        "warehouse_id": WAREHOUSE_ID,
        "statement": statement,
        "wait_timeout": f"{min(timeout_sec, 50)}s",
        "on_wait_timeout": "CONTINUE",
        "format": "JSON_ARRAY",
        "disposition": "INLINE",
    }
    r = requests.post(url, headers=_headers(), json=payload, timeout=timeout_sec + 5)
    r.raise_for_status()
    data = r.json()
    stmt_id = data["statement_id"]
    while data.get("status", {}).get("state") in ("PENDING", "RUNNING"):
        time.sleep(0.5)
        r = requests.get(
            f"{WORKSPACE_HOST}/api/2.0/sql/statements/{stmt_id}",
            headers=_headers(),
            timeout=10,
        )
        r.raise_for_status()
        data = r.json()
    state = data.get("status", {}).get("state")
    if state != "SUCCEEDED":
        err = data.get("status", {}).get("error", {})
        raise RuntimeError(f"SQL {state}: {err.get('message', err)}")
    return data


def sql_rows(statement: str) -> list[dict[str, Any]]:
    data = execute_sql(statement)
    cols = [c["name"] for c in data.get("manifest", {}).get("schema", {}).get("columns", [])]
    rows = data.get("result", {}).get("data_array") or []
    return [dict(zip(cols, row)) for row in rows]


def _arr(values: Optional[list[str]]) -> str:
    if not values:
        return "NULL"
    safe = [v.replace("'", "''") for v in values]
    return "array(" + ",".join(f"'{v}'" for v in safe) + ")"


def _i(v: Optional[int]) -> str:
    return "NULL" if v is None else str(int(v))


def _b(v: Optional[bool]) -> str:
    if v is None:
        return "NULL"
    return "true" if v else "false"


@dataclass
class AudienceFilters:
    # GEPP organizational
    regions: Optional[list[str]] = None
    territorios: Optional[list[str]] = None
    cedis_list: Optional[list[str]] = None
    sales_channels: Optional[list[str]] = None
    pdv_strategies: Optional[list[str]] = None
    # Consumer
    nse_levels: Optional[list[str]] = None
    lifecycle_stages: Optional[list[str]] = None
    personas: Optional[list[str]] = None
    cola_tiers: Optional[list[str]] = None
    pepsi_preferences: Optional[list[str]] = None
    formats: Optional[list[str]] = None
    age_min: Optional[int] = None
    age_max: Optional[int] = None
    # Boolean filters
    buys_pepsi: Optional[bool] = None
    buys_coca: Optional[bool] = None
    buys_gatorade: Optional[bool] = None
    buys_epura: Optional[bool] = None
    buys_energetico: Optional[bool] = None
    buys_2L: Optional[bool] = None
    buys_600ml: Optional[bool] = None
    health_conscious: Optional[bool] = None
    family_buyer: Optional[bool] = None
    sport_drink_user: Optional[bool] = None
    is_pepsi_lapsed: Optional[bool] = None
    is_pepsi_heavy: Optional[bool] = None
    has_gepp_app: Optional[bool] = None
    loyalty_member: Optional[bool] = None
    promo_responsive: Optional[bool] = None
    weekly_units_min: Optional[int] = None

    def to_sql_args(self) -> str:
        parts = [
            f"regions => {_arr(self.regions)}",
            f"territorios => {_arr(self.territorios)}",
            f"cedis_list => {_arr(self.cedis_list)}",
            f"sales_channels => {_arr(self.sales_channels)}",
            f"pdv_strategies => {_arr(self.pdv_strategies)}",
            f"nse_levels => {_arr(self.nse_levels)}",
            f"lifecycle_stages => {_arr(self.lifecycle_stages)}",
            f"personas => {_arr(self.personas)}",
            f"cola_tiers => {_arr(self.cola_tiers)}",
            f"pepsi_preferences => {_arr(self.pepsi_preferences)}",
            f"formats => {_arr(self.formats)}",
            f"age_min => {_i(self.age_min)}",
            f"age_max => {_i(self.age_max)}",
            f"buys_pepsi_filter => {_b(self.buys_pepsi)}",
            f"buys_coca_filter => {_b(self.buys_coca)}",
            f"buys_gatorade_filter => {_b(self.buys_gatorade)}",
            f"buys_epura_filter => {_b(self.buys_epura)}",
            f"buys_energetico_filter => {_b(self.buys_energetico)}",
            f"buys_2L_filter => {_b(self.buys_2L)}",
            f"buys_600ml_filter => {_b(self.buys_600ml)}",
            f"health_conscious_filter => {_b(self.health_conscious)}",
            f"family_buyer_filter => {_b(self.family_buyer)}",
            f"sport_drink_user_filter => {_b(self.sport_drink_user)}",
            f"is_pepsi_lapsed_filter => {_b(self.is_pepsi_lapsed)}",
            f"is_pepsi_heavy_filter => {_b(self.is_pepsi_heavy)}",
            f"has_gepp_app_filter => {_b(self.has_gepp_app)}",
            f"loyalty_member_filter => {_b(self.loyalty_member)}",
            f"promo_responsive_filter => {_b(self.promo_responsive)}",
            f"weekly_units_min => {_i(self.weekly_units_min)}",
        ]
        return ",\n  ".join(parts)


class AffinityTool:
    @staticmethod
    def audience_size(filters: AudienceFilters) -> dict[str, Any]:
        sql = f"SELECT {CATALOG}.{SCHEMA}.audience_size({filters.to_sql_args()}) AS r"
        rows = sql_rows(sql)
        if not rows:
            return {"segment_count": 0, "total_population": 0, "pct_of_population": 0}
        raw = rows[0]["r"]
        return json.loads(raw) if isinstance(raw, str) else raw

    @staticmethod
    def find_top_affinities(filters: AudienceFilters, min_lift: float = 1.2, min_support: int = 500) -> list[dict[str, Any]]:
        sql = f"SELECT * FROM {CATALOG}.{SCHEMA}.find_top_affinities({filters.to_sql_args()}, min_lift => {min_lift}, min_support => {min_support})"
        return sql_rows(sql)

    @staticmethod
    def recommend_channel(filters: AudienceFilters) -> list[dict[str, Any]]:
        sql = f"SELECT * FROM {CATALOG}.{SCHEMA}.recommend_channel({filters.to_sql_args()})"
        return sql_rows(sql)

    @staticmethod
    def preview_audience_sample(filters: AudienceFilters, sample_size: int = 10) -> list[dict[str, Any]]:
        sql = f"SELECT * FROM {CATALOG}.{SCHEMA}.preview_audience_sample({filters.to_sql_args()}, sample_size => {sample_size})"
        return sql_rows(sql)


class GenieClient:
    def __init__(self, space_id: str = GENIE_SPACE_ID):
        self.space_id = space_id

    def ask(self, question: str, conversation_id: Optional[str] = None) -> dict[str, Any]:
        if not self.space_id:
            return {"error": "GENIE_SPACE_ID no configurado", "answer": None}
        base = f"{WORKSPACE_HOST}/api/2.0/genie/spaces/{self.space_id}"
        url = f"{base}/conversations/{conversation_id}/messages" if conversation_id else f"{base}/start-conversation"
        r = requests.post(url, headers=_headers(), json={"content": question}, timeout=30)
        if not r.ok:
            return {"error": f"Genie API {r.status_code}: {r.text[:200]}", "answer": None}
        return r.json()


def llm_chat(messages: list[dict[str, str]], max_tokens: int = 1500, tools: Optional[list[dict]] = None) -> dict[str, Any]:
    if DEV_MODE:
        return {"role": "assistant", "content": "[DEV_MODE] stub"}
    url = f"{WORKSPACE_HOST}/serving-endpoints/{LLM_ENDPOINT}/invocations"
    payload = {"messages": messages, "max_tokens": max_tokens}
    if tools:
        payload["tools"] = tools
    r = requests.post(url, headers=_headers(), json=payload, timeout=60)
    r.raise_for_status()
    data = r.json()
    if "choices" in data:
        return data["choices"][0]["message"]
    return data


SUPERVISOR_SYSTEM = """Eres el Supervisor Agent de GEPP Audience Intelligence (embotelladora Pepsi MX).

Tu rol: traducir la pregunta del usuario (español MX, tuteo) a un plan estructurado que invoque las herramientas correctas.

ESTRUCTURA ORGANIZACIONAL GEPP:
- Regiones (5): METRO, BAJIO, CENTRO, PACIFICO, NORTE.
- Territorios (17): CDMX Norte, CDMX Sur, Naucalpan, Ecatepec, León, Querétaro, Irapuato, Puebla, Veracruz Norte, Xalapa, Guadalajara, Vallarta, Cancún, Monterrey, Saltillo-Torreón, Chihuahua-Juárez, Hermosillo-Tijuana.
- CEDIS (~32): ej. CEDIS Apodaca, CEDIS Vallejo, CEDIS León Norte.

CANALES DE VENTA (5): Moderno, Tradicional, Hogar, On Premise, Cuentas Clave.

ESTRATEGIA COMERCIAL (4): Blindar (heavy Pepsi loyalist), Impulsar (switcher/Coca con volumen), Desarrollar (lapsado/light), Conservar (regular Pepsi loyal).

PORTAFOLIO: Pepsi, Pepsi Light, Pepsi Black, Mirinda, 7UP, Manzanita, Gatorade, AHA, Epura, Be Light.
COMPETENCIA: Coca-Cola, Coca Zero, Sprite, Fanta, Powerade, Ciel.
PRESENTACIONES: 235ml mini lata, 355ml lata, 600ml PET, 1L PET, 2L PET, 3L PET, 500ml vidrio retornable, 355ml vidrio nostalgia.

REGLAS:
- "Heavy buyer Pepsi" → is_pepsi_heavy = true.
- "Lapsado" → is_pepsi_lapsed = true.
- "Health" → health_conscious = true.
- "Familia / formato familiar" → family_buyer = true.
- "Audiencia activable" >= 500.
- "Compran Pepsi pero no Coca" → buys_pepsi=true, buys_coca=false.

Para CADA pregunta devuelve JSON:
{
  "thought": "1 línea",
  "filters": {
    "regions": null | ["METRO","BAJIO","CENTRO","PACIFICO","NORTE"],
    "territorios": null | ["León","Monterrey",...],
    "cedis_list": null | ["CEDIS Apodaca",...],
    "sales_channels": null | ["Moderno","Tradicional","Hogar","On Premise","Cuentas Clave"],
    "pdv_strategies": null | ["Blindar","Impulsar","Desarrollar","Conservar"],
    "nse_levels": null | ["A/B","C+","C","C-","D+","D","E"],
    "lifecycle_stages": null | ["Heavy fan","Loyalty active","Engaged digital","Regular buyer","Light buyer","Lapsado","No engaged"],
    "personas": null | ["Joven Energético","Health Switcher","Wellness Maduro","Familia Refresquera","Deportista Activo","Pepsi Heavy Loyalist","Cola Heavy User","Maduro Tradicional","Mainstream Bebida"],
    "cola_tiers": null | ["Heavy","Medium","Light","Non-buyer"],
    "pepsi_preferences": null | ["Loyalist Pepsi","Loyalist Coca","Pepsi-leaning switcher","Coca-leaning switcher","No cola"],
    "formats": null | ["355ml lata","600ml PET","1L PET","2L PET","3L PET","235ml mini lata","500ml vidrio retornable","355ml vidrio nostalgia"],
    "age_min": null | int,
    "age_max": null | int,
    "buys_pepsi": null | true | false,
    "buys_coca": null | true | false,
    "buys_gatorade": null | true | false,
    "buys_epura": null | true | false,
    "buys_energetico": null | true | false,
    "buys_2L": null | true | false,
    "buys_600ml": null | true | false,
    "health_conscious": null | true | false,
    "family_buyer": null | true | false,
    "sport_drink_user": null | true | false,
    "is_pepsi_lapsed": null | true | false,
    "is_pepsi_heavy": null | true | false,
    "has_gepp_app": null | true | false,
    "loyalty_member": null | true | false,
    "promo_responsive": null | true | false,
    "weekly_units_min": null | int
  },
  "tools_to_run": ["audience_size","find_top_affinities","recommend_channel","preview_audience_sample"],
  "compare_with": null
}

- SIEMPRE incluye "audience_size".
- Incluye "find_top_affinities" si la pregunta es sobre patrones/afinidades.
- Incluye "recommend_channel" si la pregunta es sobre canal/activación.
- Incluye "preview_audience_sample" si pide ejemplos/muestras.
- NO inventes filtros. Responde SOLO con el JSON."""


SYNTHESIS_SYSTEM = """Eres un trade marketer senior de GEPP (embotelladora Pepsi MX).
Recibes la pregunta original y resultados de tools deterministas.

Redacta respuesta concisa (3-5 oraciones + bullets) que:
- Empiece con tamaño del segmento (count + %).
- Liste 3-5 afinidades clave con lift (ej "Compran Pepsi Light: 2.4x más que la base").
- Recomendación de canal/activación de trade en 1 oración (incluye región/territorio si aplica).
- Cierre con 1 línea accionable de trade.

Tono: trade marketer mexicano. NO em dashes. NO inventes data."""


def supervisor_plan(question: str) -> dict[str, Any]:
    msg = llm_chat([
        {"role": "system", "content": SUPERVISOR_SYSTEM},
        {"role": "user", "content": question},
    ], max_tokens=800)
    content = msg.get("content", "")
    try:
        if isinstance(content, list):
            content = "".join(c.get("text", "") if isinstance(c, dict) else str(c) for c in content)
        start = content.find("{")
        end = content.rfind("}")
        return json.loads(content[start : end + 1])
    except Exception as e:
        return {
            "thought": f"No pude parsear el plan: {e}",
            "filters": {},
            "tools_to_run": ["audience_size"],
            "compare_with": None,
        }


def run_tools(plan: dict[str, Any]) -> dict[str, Any]:
    f = AudienceFilters(**{k: v for k, v in (plan.get("filters") or {}).items() if v is not None})
    tools_to_run = plan.get("tools_to_run") or ["audience_size"]
    out: dict[str, Any] = {"filters": plan.get("filters", {})}
    try:
        if "audience_size" in tools_to_run:
            out["audience_size"] = AffinityTool.audience_size(f)
        if "find_top_affinities" in tools_to_run:
            out["affinities"] = AffinityTool.find_top_affinities(f, min_lift=1.2, min_support=300)
        if "recommend_channel" in tools_to_run:
            out["channels"] = AffinityTool.recommend_channel(f)
        if "preview_audience_sample" in tools_to_run:
            out["sample"] = AffinityTool.preview_audience_sample(f, sample_size=10)
    except Exception as e:
        out["error"] = str(e)
    return out


def synthesize(question: str, tool_results: dict[str, Any]) -> str:
    msg = llm_chat([
        {"role": "system", "content": SYNTHESIS_SYSTEM},
        {"role": "user", "content": f"Pregunta: {question}\n\nResultados:\n{json.dumps(tool_results, ensure_ascii=False, indent=2)}"},
    ], max_tokens=1500)
    content = msg.get("content", "")
    if isinstance(content, list):
        content = "".join(c.get("text", "") if isinstance(c, dict) else str(c) for c in content)
    return content


@dataclass
class AgentResponse:
    question: str
    plan: dict[str, Any]
    tool_results: dict[str, Any]
    answer: str


def ask(question: str) -> AgentResponse:
    plan = supervisor_plan(question)
    tool_results = run_tools(plan)
    answer = synthesize(question, tool_results)
    return AgentResponse(question=question, plan=plan, tool_results=tool_results, answer=answer)


if __name__ == "__main__":
    import sys
    q = " ".join(sys.argv[1:]) or "Consumidores con estrategia Blindar en la región NORTE"
    print(f"\n>> {q}\n")
    r = ask(q)
    print("PLAN:", json.dumps(r.plan, ensure_ascii=False, indent=2))
    print("\nTOOLS:", json.dumps(r.tool_results, ensure_ascii=False, indent=2)[:2000])
    print("\nANSWER:\n", r.answer)
