# CPG Audience Intelligence

Demo de un chatbot de inteligencia de audiencias para una **embotelladora CPG**
de bebidas en México. Le preguntas en lenguaje natural por un segmento de
consumidores (por región, canal, estrategia de punto de venta, portafolio, etc.)
y te regresa el tamaño de la audiencia, qué la hace única, por qué canal
activarla y una muestra de consumidores.

Todo corre como una **Databricks App** (FastAPI) sobre Unity Catalog, con datos
sintéticos de 100K consumidores y una estructura organizacional típica de
embotelladora (regiones METRO, BAJIO, CENTRO, PACIFICO, NORTE; territorios; CEDIS).

## Cómo funciona

El chat entra por un solo endpoint, `POST /api/ask`, que dispara un pipeline de
tres pasos (todo en `app/backend/agent_core.py`):

1. **Supervisor**: Claude (vía Foundation Models API, endpoint `databricks-claude-sonnet-4`)
   lee la pregunta y arma un plan: qué filtros aplicar y qué herramientas correr.
2. **Herramientas**: ejecuta funciones deterministas de Unity Catalog (UC Functions)
   sobre la base de consumidores.
3. **Síntesis**: Claude redacta la respuesta final en lenguaje de marketing.

El "cerebro" entonces es un agente supervisor más funciones de UC, no Genie
directo. Eso da control total del formato de respuesta y resultados deterministas.

> El repo también deja listo un **Genie Space** (`scripts/create_genie_space.py`)
> y el cliente para llamarlo (`GenieClient` en `agent_core.py`). Si prefieres que
> el chat use Genie nativo (NL a SQL automático), basta apuntar `ask()` a
> `GenieClient.ask()` en lugar del supervisor.

## Recursos en Databricks que usa

La app no corre sola: depende de estos objetos, todos en
`serverless_stable_rtpa_catalog.gepp_audience_intelligence` (definidos en `app/app.yaml`):

| Recurso | Valor |
|---|---|
| Catálogo / schema | `serverless_stable_rtpa_catalog.gepp_audience_intelligence` |
| Tabla base | `population_attributes` (100K consumidores) |
| Vista | `population_baseline_rates` (tasas baseline para el lift) |
| UC Functions (5) | `audience_size`, `find_top_affinities`, `recommend_channel`, `preview_audience_sample`, `compare_segments` |
| SQL Warehouse | `960301858d2768fd` |
| LLM endpoint | `databricks-claude-sonnet-4` |
| Genie Space | `01f15916a44e1495a61cb48794045b37` |

## Estructura del repo

```
gepp-audience-intelligence/
├── app/                          # Databricks App (FastAPI)
│   ├── app.yaml                  # comando + env vars (warehouse, catálogo, endpoint, genie)
│   ├── main.py                   # endpoints: /, /api/ask, /api/plan, /api/preset
│   ├── requirements.txt
│   ├── backend/agent_core.py     # supervisor + UC functions + GenieClient + síntesis
│   └── frontend/index.html       # UI del chat (HTML único)
├── scripts/
│   ├── generate_population.py    # genera data/population_attributes.parquet (100K)
│   ├── create_genie_space.py     # crea el Genie Space
│   ├── update_genie_space.py     # actualiza instrucciones / sample queries del Space
│   └── run_sql.sh                # corre un archivo .sql contra el warehouse
└── sql/
    ├── 00_setup_catalog.sql      # schema + volume
    ├── 01_create_population_table.sql  # tabla population_attributes + vista baseline
    ├── 02_uc_functions.sql       # las 5 UC functions
    └── 03_app_permissions.sql    # grants al service principal de la app
```

> `data/population_attributes.parquet` no se versiona (está en `.gitignore`). Se
> regenera con `scripts/generate_population.py`.

## Despliegue desde cero

Requiere el [Databricks CLI](https://docs.databricks.com/dev-tools/cli/) autenticado.
El perfil por defecto es `fe-vm-serverless-stable-rtpa`.

```bash
# 1. Crear schema y volume
./scripts/run_sql.sh sql/00_setup_catalog.sql

# 2. Generar la data sintética y subirla (la tabla la crea el paso 3 desde el parquet)
python3 scripts/generate_population.py

# 3. Crear tabla population_attributes + vista baseline
./scripts/run_sql.sh sql/01_create_population_table.sql

# 4. Crear las 5 UC functions
./scripts/run_sql.sh sql/02_uc_functions.sql

# 5. Crear el Genie Space (opcional, si quieres el camino Genie nativo)
python3 scripts/create_genie_space.py

# 6. Otorgar permisos al service principal de la app
#    (ajusta el ID del SP en sql/03_app_permissions.sql al de tu app)
./scripts/run_sql.sh sql/03_app_permissions.sql

# 7. Desplegar la Databricks App
#    Sube la carpeta app/ al workspace y crea/actualiza la app.
databricks apps deploy gepp-audience-intelligence \
  --source-code-path /Workspace/Users/<tu-usuario>/gepp-audience-intelligence/app
```

## Probar el chat

Ejemplos de preguntas (en la UI o por `POST /api/ask`):

- "Consumidores con estrategia Blindar en la región NORTE"
- "¿Qué hace únicos a los compradores heavy de Pepsi en el canal Tradicional?"
- "¿Por qué canal activo a los consumidores con app de la embotelladora y membresía de lealtad?"
- "Dame 10 ejemplos de consumidores lapsados de Pepsi en BAJIO"

## Notas

- Datos 100% sintéticos. No hay información real de consumidores.
- Idioma de la app y del Genie Space: español de México.
- Hecho como demo de Field Engineering (Databricks).
