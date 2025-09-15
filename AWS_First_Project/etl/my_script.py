from pyspark.sql import SparkSession
from pyspark.sql.functions import col, when, count, round

def main():
    spark = SparkSession.builder.appName("GlueETLJob").getOrCreate()

    # S3 bucket base path
    bucket = "aws-s3-etl-demo-repo"
    base_path = f"s3://{bucket}/data/"

    # Load CSV files with header and infer schema for better data typing
    customer_df = spark.read.option("header", True).option("inferSchema", True).csv(base_path + "customer.csv")
    account_df = spark.read.option("header", True).option("inferSchema", True).csv(base_path + "account.csv")
    transaction_df = spark.read.option("header", True).option("inferSchema", True).csv(base_path + "transaction.csv")

    # Cast join keys as string (to avoid join type mismatch)
    customer_df = customer_df.withColumn("customer_id", col("customer_id").cast("string"))
    account_df = account_df.withColumn("customer_id", col("customer_id").cast("string")) \
                           .withColumn("account_id", col("account_id").cast("string"))
    transaction_df = transaction_df.withColumn("account_id", col("account_id").cast("string"))

    # Join customer -> account -> transaction
    cust_acc_df = customer_df.join(account_df, on="customer_id", how="inner")
    full_df = cust_acc_df.join(transaction_df, on="account_id", how="inner")

    # Null count report (optional, for debugging)
    null_counts = full_df.select([count(when(col(c).isNull(), c)).alias(c) for c in full_df.columns])
    null_counts.show(truncate=False)

    # Fill missing emails with placeholder
    full_df = full_df.fillna({"email": "unknown@example.com"})

    # Derive amount in dollars (from cents), rounding to 2 decimals
    full_df = full_df.withColumn("amount_dollars", round(col("amount_cents") / 100, 2))

    # Drop PII columns - example: email and customer_name (customize as needed)
    curated_df = full_df.drop("email", "customer_name")

    # Write transformed data as partitioned Parquet (partition by, e.g., transaction_date)
    output_path = f"s3://{bucket}/curated/"

    curated_df.write.mode("overwrite").partitionBy("transaction_date").parquet(output_path)

    spark.stop()

if __name__ == "__main__":
    main()


