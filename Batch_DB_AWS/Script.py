
import os
import pandas as pd
import mysql.connector
import boto3
from datetime import datetime, timedelta , timezone

# -----------------------------
# Database connection variables
# (Replace with your MySQL Workbench connection details)
# -----------------------------
DB_HOST = "127.0.0.1"
DB_NAME = "test_db"
DB_USER = "root"
DB_PASS = "8888"
DB_PORT = 3306   # 3306 if MySQL           # default MySQL port

# -----------------------------
# AWS S3 configuration
# -----------------------------
# AWS S3 config
S3_BUCKET = "rawbt1"
S3_RAW_PATH = "rawbt1/" 
# -----------------------------
# Connect to MySQL
# -----------------------------
conn = mysql.connector.connect(
    host=DB_HOST,
    database=DB_NAME,
    user=DB_USER,
    password=DB_PASS,
    port=DB_PORT
)
cursor = conn.cursor()
# -----------------------------
# Query: Extract records from last 15 minutes (UTC)
# -----------------------------
time_threshold = datetime.now(timezone.utc) - timedelta(minutes=15)

query = """
    SELECT * FROM orders
    WHERE order_date >= %s
"""
cursor.execute(query, (time_threshold,))
rows = cursor.fetchall()

# Get column names
colnames = [desc[0] for desc in cursor.description]

if rows:
    df = pd.DataFrame(rows, columns=colnames)

    file_name = f"orders_{datetime.utcnow().strftime('%Y%m%d%H%M%S')}.csv"
    df.to_csv(file_name, index=False)

    # -----------------------------
    # Upload CSV to S3
    # -----------------------------
    s3 = boto3.client("s3")
    s3.upload_file(file_name, S3_BUCKET, S3_RAW_PATH + file_name)

    print(f"✅ Uploaded {file_name} to s3://{S3_BUCKET}/{S3_RAW_PATH}{file_name}")
else:
    print("⚠️ No new records found in the last 15 minutes.")

# -----------------------------
# Cleanup
# -----------------------------
cursor.close()
conn.close()
