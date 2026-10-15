#!/usr/bin/env bash
set -euo pipefail

REMOTE_URL="${1:-}"
COMMIT_MSG="${2:-feat: add medallion architecture skeleton}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
echo "ERROR: Ejecuta este script desde la raiz del repositorio Git."
exit 1
fi

BRANCH="$(git branch --show-current)"
if [[ -z "$BRANCH" ]]; then
echo "ERROR: No hay una rama activa."
exit 1
fi

echo "Rama actual: $BRANCH"

LAYERS=(bronze silver gold)
mkdir -p data/raw docs config src/common

for layer in "${LAYERS[@]}"; do
mkdir -p "data/$layer" "notebooks/$layer" "src/$layer" "tests/$layer"
done

for dir in data/raw data/bronze data/silver data/gold docs config; do
touch "$dir/.gitkeep"
done

touch src/**init**.py src/common/**init**.py

for layer in "${LAYERS[@]}"; do
touch "src/$layer/**init**.py" "tests/$layer/**init**.py"
done

cat > src/common/spark_utils.py <<'EOF'
"""Utilidades compartidas entre capas."""
from pyspark.sql import DataFrame
from pyspark.sql import functions as F

def add_audit_columns(df: DataFrame, source: str) -> DataFrame:
"""Agrega columnas de auditoria estandar."""
return (
df.withColumn("_ingestion_ts", F.current_timestamp())
.withColumn("_source", F.lit(source))
)
EOF

cat > src/bronze/ingest.py <<'EOF'
"""Bronze: ingesta de datos crudos."""
from pyspark.sql import SparkSession, DataFrame
from src.common.spark_utils import add_audit_columns

def ingest_raw(spark: SparkSession, path: str, fmt: str = "csv") -> DataFrame:
df = spark.read.format(fmt).option("header", True).load(path)
return add_audit_columns(df, source=path)
EOF

cat > src/silver/transform.py <<'EOF'
"""Silver: limpieza y deduplicacion."""
from pyspark.sql import DataFrame

def clean(df: DataFrame) -> DataFrame:
return df.dropDuplicates().na.drop(how="all")
EOF

cat > src/gold/aggregate.py <<'EOF'
"""Gold: agregaciones y modelos analiticos."""
from pyspark.sql import DataFrame

def build_gold(df: DataFrame) -> DataFrame:
# TODO: definir metricas y dimensiones de negocio.
return df
EOF

make_notebook() {
local layer="$1" title="$2" desc="$3"
cat > "notebooks/${layer}/01_${layer}_notebook.py" <<EOF

# Databricks notebook source

# MAGIC %md

# MAGIC # ${title}

# MAGIC ${desc}

# COMMAND ----------

# TODO: lectura de la capa anterior

# COMMAND ----------

# TODO: transformaciones

# COMMAND ----------

# TODO: escritura en tabla Delta de la capa ${layer}

EOF
}

make_notebook bronze "Bronze" "Ingesta de datos crudos desde las fuentes."
make_notebook silver "Silver" "Datos limpios, validados y conformados."
make_notebook gold "Gold" "Datos agregados listos para consumo."

cat > tests/test_placeholder.py <<'EOF'
def test_placeholder():
assert True
EOF

cat > config/config.example.yaml <<'EOF'
catalog: main
schemas:
bronze: bronze
silver: silver
gold: gold
paths:
raw: data/raw
EOF

if [[ ! -f .gitignore ]]; then
cat > .gitignore <<'EOF'
**pycache**/
*.py[cod]
.venv/
venv/
.pytest_cache/
.env
*.env
config/config.yaml
.databricks/
databricks.yml.local
data/**
!data/**/
!data/**/.gitkeep
.DS_Store
.idea/
.vscode/
EOF
fi

if [[ ! -f README.md ]]; then
touch README.md
fi

if ! grep -q "Arquitectura Medallion" README.md; then
cat >> README.md <<'EOF'

## Arquitectura Medallion

* `data/raw`: datos originales de entrada.
* `data/bronze`: datos ingeridos.
* `data/silver`: datos limpios y validados.
* `data/gold`: datos preparados para analitica.
* `src/`: transformaciones Python reutilizables.
* `notebooks/`: notebooks por capa.
* `tests/`: pruebas automatizadas.
* `docs/`: documentacion.
* `config/`: plantillas de configuracion.

| Capa   | Proposito                             |
| ------ | ------------------------------------- |
| Bronze | Datos crudos                          |
| Silver | Datos limpios, tipados y deduplicados |
| Gold   | Modelos y agregaciones para BI        |
| EOF    |                                       |
| fi     |                                       |

if ! git remote get-url origin >/dev/null 2>&1; then
if [[ -n "$REMOTE_URL" ]]; then
git remote add origin "$REMOTE_URL"
else
echo "ERROR: No existe origin. Ejecuta: ./setup_medallion.sh [git@github.com](mailto:git@github.com):USUARIO/REPO.git"
exit 1
fi
fi

echo "Revisa los cambios antes de publicarlos:"
git status --short
echo
echo "Script preparado. No se hizo commit ni push automaticamente."
