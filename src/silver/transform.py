"""Silver: limpieza y deduplicacion."""
from pyspark.sql import DataFrame

def clean(df: DataFrame) -> DataFrame:
return df.dropDuplicates().na.drop(how="all")
