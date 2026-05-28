#!/usr/bin/env bash
# Helper: ejecuta un archivo SQL contra el warehouse via databricks SDK.
# Uso: ./run_sql.sh sql/01_create_table.sql
set -euo pipefail

PROFILE="${DATABRICKS_PROFILE:-fe-vm-serverless-stable-rtpa}"
WAREHOUSE_ID="${WAREHOUSE_ID:-960301858d2768fd}"
SQL_FILE="${1:-}"

if [[ -z "$SQL_FILE" || ! -f "$SQL_FILE" ]]; then
  echo "Uso: $0 <ruta/al/archivo.sql>"
  exit 1
fi

# Lee y limpia comentarios / líneas vacías, separa por ;
SQL=$(cat "$SQL_FILE")

# Procesa cada statement por separado (split en ; que esté al final de línea, simple)
python3 <<EOF
import json
import re
import subprocess
import sys

sql = """$SQL"""
# Elimina comentarios -- línea completa
sql = re.sub(r'^\s*--.*$', '', sql, flags=re.MULTILINE)
# Split por ; (simple, sin DELIMITER fancy)
stmts = [s.strip() for s in sql.split(';') if s.strip()]

profile = "$PROFILE"
wh = "$WAREHOUSE_ID"
for i, stmt in enumerate(stmts, 1):
    print(f"\n--- Statement {i}/{len(stmts)} ---")
    print(stmt[:200] + ('...' if len(stmt) > 200 else ''))
    payload = {
        "warehouse_id": wh,
        "statement": stmt,
        "wait_timeout": "30s",
        "on_wait_timeout": "CONTINUE",
    }
    r = subprocess.run(
        ["databricks", "--profile", profile, "api", "post", "/api/2.0/sql/statements",
         "--json", json.dumps(payload)],
        capture_output=True, text=True
    )
    if r.returncode != 0:
        print("ERROR:", r.stderr)
        sys.exit(1)
    out = json.loads(r.stdout)
    status = out.get("status", {}).get("state")
    stmt_id = out.get("statement_id")
    # Poll si está PENDING/RUNNING
    while status in ("PENDING", "RUNNING"):
        r2 = subprocess.run(
            ["databricks", "--profile", profile, "api", "get",
             f"/api/2.0/sql/statements/{stmt_id}"],
            capture_output=True, text=True
        )
        out = json.loads(r2.stdout)
        status = out.get("status", {}).get("state")
    if status == "SUCCEEDED":
        rows = out.get("result", {}).get("data_array") or []
        print(f"OK ({status})")
        for row in rows[:5]:
            print("  ", row)
    else:
        print(f"FAIL ({status})")
        print(json.dumps(out.get("status", {}).get("error", {}), indent=2))
        sys.exit(1)
EOF
