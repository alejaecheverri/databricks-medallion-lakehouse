"""Bronze: ingesta de datos crudos."""
from pyspark.sql import SparkSession, DataFrame
from src.common.spark_utils import add_audit_columns

def ingest_raw(spark: SparkSession, path: str, fmt: str = "csv") -> DataFrame:
df = spark.read.format(fmt).option("header", True).load(path)
return add_audit_columns(df, source=path)
