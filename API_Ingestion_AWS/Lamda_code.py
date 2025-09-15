import json
import boto3
import base64
from datetime import datetime, timezone
import uuid

RAW_BUCKET = "weather-raw-bucket-<yourname>"
CURATED_BUCKET = "weather-curated-bucket-<yourname>"

s3 = boto3.client("s3")

def lambda_handler(event, context):
    for record in event['Records']:
        # Decode Kinesis payload
        payload = base64.b64decode(record['kinesis']['data']).decode('utf-8')
        data = json.loads(payload)

        # Timestamped key for raw S3
        ts = datetime.now(timezone.utc)
        raw_key = ts.strftime("date=%Y-%m-%d/hour=%H/") + f"{uuid.uuid4()}.json"

        # Save raw data
        s3.put_object(Bucket=RAW_BUCKET, Key=raw_key, Body=json.dumps(data))

        # Transform data
        curated_data = {
            "city": data["raw_weather"]["name"],
            "temperature": data["raw_weather"]["main"]["temp"],
            "humidity": data["raw_weather"]["main"]["humidity"],
            "weather": data["raw_weather"]["weather"][0]["description"],
            "timestamp": ts.isoformat()
        }

        curated_key = ts.strftime("date=%Y-%m-%d/hour=%H/") + f"{uuid.uuid4()}.json"
        s3.put_object(Bucket=CURATED_BUCKET, Key=curated_key, Body=json.dumps(curated_data))

    return {"status": "success", "records": len(event['Records'])}
