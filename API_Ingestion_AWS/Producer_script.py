import json
import time
import uuid
import requests
import boto3

# -----------------------------
# Configuration
# -----------------------------
STREAM_NAME = "weather-stream"
REGION = "us-east-2"  # must match the Kinesis stream region
API_KEY = "190e638d62a5649d8043e869dcbf4fa1"  # replace with your key
LAT = "40.71"
LON = "-74.01"

kinesis = boto3.client("kinesis", region_name=REGION)

# -----------------------------
# Fetch Weather Data
# -----------------------------
def fetch_weather():
    url = f"https://api.openweathermap.org/data/2.5/weather?lat={LAT}&lon={LON}&appid={API_KEY}&units=metric"
    resp = requests.get(url, timeout=10)
    resp.raise_for_status()
    return resp.json()

# -----------------------------
# Main Loop
# -----------------------------
def main():
    while True:
        try:
            weather = fetch_weather()
            record = {
                "event_id": str(uuid.uuid4()),
                "ts": int(time.time()),
                "raw_weather": weather
            }

            # Push to Kinesis
            kinesis.put_record(
                StreamName=STREAM_NAME,
                Data=json.dumps(record),
                PartitionKey="partition-1"
            )
            print("Pushed weather record to Kinesis")

        except requests.exceptions.HTTPError as e:
            print(f"HTTP Error: {e}")
        except Exception as e:
            print(f"Error: {e}")

        time.sleep(60)  # fetch every 60 seconds

# -----------------------------
# Entry Point
# -----------------------------
if __name__ == "__main__":
    main()
