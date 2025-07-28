from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Step 1: Initialize Spark
spark = SparkSession.builder.appName("FixPipeline").getOrCreate()

# Step 2: Load both CSVs
df_tx = spark.read.option("header", True).csv("/Users/vamsydamekar/Desktop/Spark Project/ecommerce_transactions.csv")
df_region = spark.read.option("header", True).csv("/Users/vamsydamekar/Desktop/Spark Project/country_region.csv")

# Step 3: Validate schema
df_tx.printSchema()
df_region.printSchema()

# Step 4: Clean only transactions dataframe (df_tx)
df_clean = (
    df_tx.dropDuplicates()
    .filter(col("customer_id").isNotNull())
    .filter(col("quantity").cast("int") > 0)
)

df_clean.show(5)


from pyspark.sql.functions import year, month, dayofmonth

# Enrich the cleaned data
df_enriched = df_clean.withColumn(
    "quantity", col("quantity").cast("int")
).withColumn(
    "unit_price", col("unit_price").cast("float")
).withColumn(
    "order_value", col("quantity") * col("unit_price")
).withColumn(
    "year", year(col("order_date"))
).withColumn(
    "month", month(col("order_date"))
).withColumn(
    "day", dayofmonth(col("order_date"))
)

df_enriched.show(5)

from pyspark.sql.functions import sum as _sum

country_revenue_df = df_enriched.groupBy("country") \
    .agg(_sum("order_value").alias("total_revenue")) \
    .orderBy("total_revenue", ascending=False)

country_revenue_df.show()

from pyspark.sql.window import Window
from pyspark.sql.functions import row_number

# First, compute total spend per customer per country
customer_spend_df = df_enriched.groupBy("country", "customer_id") \
    .agg(_sum("order_value").alias("customer_total_spend"))

# Define a window partitioned by country, ordered by spend descending
window_spec = Window.partitionBy("country").orderBy(customer_spend_df["customer_total_spend"].desc())

# Apply row_number to rank customers within each country
top_customers_df = customer_spend_df.withColumn("rank", row_number().over(window_spec)) \
    .filter("rank = 1") \
    .drop("rank")

top_customers_df.show()

# Ensure both DataFrames have a common column: "country"
df_region_clean = df_region.dropDuplicates(["country"])  # Avoid join duplication

# Join transaction data with region mapping
df_with_region = df_enriched.join(df_region_clean, on="country", how="left")

# Group by region and compute total sales
region_summary_df = df_with_region.groupBy("region") \
    .agg(_sum("order_value").alias("total_revenue")) \
    .orderBy("total_revenue", ascending=False)

region_summary_df.show()

from pyspark.sql.functions import date_format

# Extract month from the order_date
df_monthly = df_with_region.withColumn("order_month", date_format(col("order_date"), "yyyy-MM"))

# Pivot: sum of order_value by month and category
pivot_df = df_monthly.groupBy("order_month") \
    .pivot("category") \
    .agg(_sum("order_value").alias("monthly_sales")) \
    .orderBy("order_month")

pivot_df.show()

from pyspark.sql.functions import when

# Define price bands with conditions
df_price_banded = df_enriched.withColumn(
    "price_band",
    when(col("order_value") < 50, "<50")
    .when((col("order_value") >= 50) & (col("order_value") < 100), "50-99")
    .when((col("order_value") >= 100) & (col("order_value") < 200), "100-199")
    .otherwise("200+")
)

# Count orders in each price band
price_band_counts = df_price_banded.groupBy("price_band").count().orderBy("price_band")

price_band_counts.show()

import time

# Check initial number of partitions
print(f"Initial partitions: {df_enriched.rdd.getNumPartitions()}")

# Repartition by country (wide transformation with shuffle)
df_repartitioned = df_enriched.repartition("country")

# Check new number of partitions
print(f"Repartitioned partitions: {df_repartitioned.rdd.getNumPartitions()}")

# Measure job duration with repartition
start_time = time.time()
df_repartitioned.groupBy("country").agg(_sum("order_value")).collect()
print(f"Time with repartition (country): {time.time() - start_time:.2f} seconds")

# Measure job duration without repartition
start_time = time.time()
df_enriched.groupBy("country").agg(_sum("order_value")).collect()
print(f"Time without repartition: {time.time() - start_time:.2f} seconds")

# Cache the DataFrame
df_cached = df_enriched.cache()

# First action triggers cache computation
start_time = time.time()
df_cached.count()
print(f"Time for first action (cache populate): {time.time() - start_time:.2f} seconds")

# Second action uses cached data
start_time = time.time()
df_cached.groupBy("country").agg(_sum("order_value")).collect()
print(f"Time for second action (using cache): {time.time() - start_time:.2f} seconds")

# For comparison, unpersist and recompute
df_cached.unpersist()

start_time = time.time()
df_enriched.groupBy("country").agg(_sum("order_value")).collect()
print(f"Time for recompute without cache: {time.time() - start_time:.2f} seconds")

output_path = "/path/to/output/gold_data"

# Save the enriched DataFrame as Parquet with Snappy compression
output_path = "/Users/vamsydamekar/Desktop/Spark Project/output/gold_data"

df_enriched.write.mode("overwrite") \
    .option("compression", "snappy") \
    .parquet(output_path)

print(f"Data successfully saved to {output_path}")
