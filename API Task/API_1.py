import requests
import pandas as pd

# API request
url = "https://api.open-meteo.com/v1/forecast"
params = {
    "latitude": 40.710335,
    "longitude": -73.99309,
    "hourly": "temperature_2m,relative_humidity_2m",
    "forecast_days": 3,
    "timezone": "auto"
}

response = requests.get(url, params=params)
data = response.json()

# Convert to DataFrame
df = pd.DataFrame({
    "time": data["hourly"]["time"],
    "temperature_C": data["hourly"]["temperature_2m"],
    "humidity_%": data["hourly"]["relative_humidity_2m"]
})

# Save CSV
df.to_csv("nyc_weather.csv", index=False)
print("Saved nyc_weather.csv")

# Find max & min temperatures
max_temp = df.loc[df["temperature_C"].idxmax()]
min_temp = df.loc[df["temperature_C"].idxmin()]

print("Max Temp:", max_temp["temperature_C"], "°C at", max_temp["time"])
print("Min Temp:", min_temp["temperature_C"], "°C at", min_temp["time"])

# ------------------------------
# Part A: Error handling test
# ------------------------------
params_error = {
    "latitude": 40.710335,
    "longitude": -73.99309,
    "hourly": "temprature_2m",  # <-- wrong spelling
    "forecast_days": 3,
    "timezone": "auto"
}

response_error = requests.get(url, params=params_error)
print("\n❌ Error Test")
print("Status Code:", response_error.status_code)
print("Response:", response_error.json())