"""
FastAPI entrypoint para la Databricks App "Audience Intelligence".
Sirve el frontend (HTML único) y expone POST /api/ask que ejecuta
el pipeline Supervisor → Genie/Affinity → Synthesis.
"""
from __future__ import annotations

import os
import json
from pathlib import Path
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

from backend.agent_core import (
    ask,
    AffinityTool,
    AudienceFilters,
    supervisor_plan,
    run_tools,
    synthesize,
    GENIE_SPACE_ID,
)

FRONTEND_DIR = Path(__file__).parent / "frontend"

app = FastAPI(title="GEPP Audience Intelligence · Bebidas MX")


class AskRequest(BaseModel):
    question: str


@app.get("/")
def index():
    return FileResponse(FRONTEND_DIR / "index.html")


@app.get("/healthz")
def health():
    return {"status": "ok", "genie_space_id": GENIE_SPACE_ID or "not configured"}


@app.post("/api/ask")
def api_ask(req: AskRequest):
    if not req.question.strip():
        raise HTTPException(400, "Pregunta vacía")
    try:
        r = ask(req.question)
        return {
            "question": r.question,
            "plan": r.plan,
            "tool_results": r.tool_results,
            "answer": r.answer,
        }
    except Exception as e:
        raise HTTPException(500, f"Agent error: {e}")


@app.post("/api/plan")
def api_plan(req: AskRequest):
    """Endpoint para debug: solo retorna el plan, no ejecuta tools."""
    plan = supervisor_plan(req.question)
    return plan


@app.get("/api/preset/{preset_id}")
def api_preset(preset_id: str):
    """Presets para el demo en vivo (sin necesidad de LLM, para fallback)."""
    import traceback
    presets = {
        "blindar_norte": AudienceFilters(pdv_strategies=["Blindar"], regions=["NORTE"]),
        "impulsar_bajio": AudienceFilters(pdv_strategies=["Impulsar"], regions=["BAJIO"]),
        "desarrollar_lapsados": AudienceFilters(pdv_strategies=["Desarrollar"], is_pepsi_lapsed=True),
        "familia_2L_metro": AudienceFilters(family_buyer=True, buys_2L=True, regions=["METRO"]),
        "moderno_cuentas_clave": AudienceFilters(sales_channels=["Cuentas Clave"]),
        "tradicional_heavy": AudienceFilters(sales_channels=["Tradicional"], is_pepsi_heavy=True),
        "health_switchers": AudienceFilters(health_conscious=True, age_max=40),
        "joven_energetico": AudienceFilters(personas=["Joven Energético"]),
    }
    f = presets.get(preset_id)
    if not f:
        raise HTTPException(404, "Preset no encontrado")
    try:
        out = {
            "filters": {k: v for k, v in f.__dict__.items() if v is not None},
            "audience_size": AffinityTool.audience_size(f),
            "affinities": AffinityTool.find_top_affinities(f, min_lift=1.2, min_support=300),
            "channels": AffinityTool.recommend_channel(f),
            "sample": AffinityTool.preview_audience_sample(f, sample_size=8),
        }
        return out
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={
                "error": str(e),
                "type": type(e).__name__,
                "traceback": traceback.format_exc().splitlines()[-15:],
            },
        )


@app.get("/api/debug/env")
def api_debug_env():
    """Devuelve algunos env vars y resultado de auth (sin filtrar el token)."""
    import traceback
    keys = ["DATABRICKS_HOST", "DATABRICKS_WAREHOUSE_ID", "LLM_ENDPOINT",
            "DATABRICKS_CLIENT_ID", "DATABRICKS_APP_NAME", "DATABRICKS_APP_PORT",
            "DATABRICKS_APP_URL", "DATABRICKS_WORKSPACE_ID"]
    env = {k: ("***" if "secret" in k.lower() or "token" in k.lower() else os.environ.get(k, "<unset>")) for k in keys}
    env["has_client_secret"] = bool(os.environ.get("DATABRICKS_CLIENT_SECRET"))
    env["has_token"] = bool(os.environ.get("DATABRICKS_TOKEN"))
    try:
        from backend.agent_core import _token, execute_sql
        t = _token()
        env["token_obtained"] = bool(t)
        env["token_prefix"] = t[:12] + "..." if t else ""
        # try a trivial SQL
        try:
            r = execute_sql("SELECT 1 AS x")
            env["sql_test"] = r.get("status", {}).get("state")
        except Exception as e:
            env["sql_test_error"] = str(e)[:300]
    except Exception as e:
        env["token_error"] = str(e)
        env["traceback"] = traceback.format_exc().splitlines()[-10:]
    return env


# Sirve assets estáticos (CSS, JS, imágenes) si se agregan después
if (FRONTEND_DIR / "static").exists():
    app.mount("/static", StaticFiles(directory=FRONTEND_DIR / "static"), name="static")


if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", "8000"))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=False)
