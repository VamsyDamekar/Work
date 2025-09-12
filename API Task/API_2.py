from dotenv import load_dotenv
import os
import requests
import json

# Load .env file
load_dotenv()

# Get API key
api_key = os.getenv("OWM_KEY")
if not api_key:
    raise ValueError("API key not found. Check your .env file.")

# List of cities
cities = ["New York", "Los Angeles", "Chicago"]

# Store weather data
weather_data = {}

for city in cities:
    url = "http://api.openweathermap.org/data/2.5/weather"
    params = {
        "q": city,
        "appid": api_key,
        "units": "metric"  # use "imperial" for °F
    }
    
    response = requests.get(url, params=params)
    
    if response.status_code == 200:
        data = response.json()
        weather_data[city] = {
            "temperature_C": data["main"]["temp"],
            "weather": data["weather"][0]["description"]
        }
    else:
        weather_data[city] = {
            "error": f"{response.status_code} - {response.json().get('message')}"
        }

# Save to JSON file
with open("cities_weather.json", "w") as f:
    json.dump(weather_data, f, indent=4)

print("✅ Saved cities_weather.json")
print(weather_data)

# Compare temperatures
temps = {city: info["temperature_C"] for city, info in weather_data.items() if "temperature_C" in info}
if temps:
    hottest = max(temps, key=temps.get)
    coldest = min(temps, key=temps.get)
    print(f"\n🌡 Hottest city: {hottest} ({temps[hottest]} °C)")
    print(f"❄ Coldest city: {coldest} ({temps[coldest]} °C)")


