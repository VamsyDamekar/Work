# part_d_nws.py
import requests
import json

# --- Step 1: Define location ---
latitude = 40.71
longitude = -74.01

# --- Step 2: Required User-Agent header ---
headers = {
    "User-Agent": "vamsydamekar@example.com"
}

# --- Step 3: Get grid info ---
points_url = f"https://api.weather.gov/points/{latitude},{longitude}"
response = requests.get(points_url, headers=headers)

if response.status_code != 200:
    print("Error fetching grid info:", response.status_code)
    print(response.text)
    exit()

grid_data = response.json()
forecast_url = grid_data["properties"]["forecast"]
print(f"Forecast URL: {forecast_url}")

# --- Step 4: Fetch forecast ---
forecast_response = requests.get(forecast_url, headers=headers)
if forecast_response.status_code != 200:
    print("Error fetching forecast:", forecast_response.status_code)
    print(forecast_response.text)
    exit()

forecast_data = forecast_response.json()

# --- Step 5: Save forecast to JSON ---
with open("nws_forecast.json", "w") as f:
    json.dump(forecast_data, f, indent=4)

print("✅ Saved nws_forecast.json")

# --- Step 6: Test missing User-Agent ---
response_no_header = requests.get(forecast_url)
print("\nMissing User-Agent Test:")
print("Status Code:", response_no_header.status_code)
print("Message:", response_no_header.text[:200])
