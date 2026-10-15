"""Utilidades compartidas entre capas."""
from pyspark.sql import DataFrame
from pyspark.sql import functions as F

def add_audit_columns(df: DataFrame, source: str) -> DataFrame:
"""Agrega columnas de auditoria estandar."""
return (
df.withColumn("_ingestion_ts", F.current_timestamp())
.withColumn("_source", F.lit(source))
)
