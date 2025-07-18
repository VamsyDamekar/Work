import boto3
import pandas as pd
import io

# Create S3 client
s3 = boto3.client('s3')

# === Read from rawbt ===
bucket_in = 'rawbt'
key_in = 'salaries.csv'

response = s3.get_object(Bucket=bucket_in, Key=key_in)
df = pd.read_csv(io.BytesIO(response['Body'].read()))

# === Transform Data ===
df.columns = [col.strip().lower().replace(" ", "_") for col in df.columns]
df = df[df['employment_type'] == 'FT'].drop_duplicates()

# === Write to stagingbt ===
bucket_out = 'stagingbt'
key_out = 'salaries_stage1.csv'

csv_buffer = io.StringIO()
df.to_csv(csv_buffer, index=False)
s3.put_object(Bucket=bucket_out, Key=key_out, Body=csv_buffer.getvalue())

print(f"✅ File saved to s3://{bucket_out}/{key_out}")
