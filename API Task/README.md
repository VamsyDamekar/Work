Problem Statement: 

A real-time pipeline that collects external weather data from public APIs, processes and filters it, and stores the refined data for 
analytics and alerting. I designed and implemented this to demonstrate proper error handling, secure API key usage, and standardized data 
storage for multiple weather sources.

Target State: 

The goal is to design and implement a fully automated data pipeline that ingests weather data from Open-Meteo, OpenWeatherMap, 
and the National Weather Service, transforms it, and stores it in a structured format for analysis, testing both normal and erroneous scenarios.

Project Overview: 

This project demonstrates an end-to-end pipeline that fetches hourly temperature and humidity from Open-Meteo, current weather for multiple 
cities from OpenWeatherMap, and forecast data from the National Weather Service. It saves Open-Meteo data as a CSV and computes maximum and 
minimum temperatures for the next three days while demonstrating error handling for misspelled parameters. OpenWeatherMap results are 
stored as JSON, with secure API key usage, tests for invalid keys, and comparison between metric and imperial units. 
National Weather Service data is saved as JSON, requiring a custom User-Agent header, with demonstrations of what happens when the header 
is missing. The pipeline outputs both structured files and terminal logs for insights, error handling, and verification of data correctness.

Architecture: 

Part A (Open-Meteo): Fetches hourly temperature and humidity, saves openmeteo_weather.csv, computes max/min temperatures, and demonstrates 
error handling for invalid parameters. 
Part B (OpenWeatherMap): Fetches current weather for multiple cities, stores API key securely in .env, 
saves results as openweather_cities.json, tests invalid API keys, and compares metric vs imperial units. 
Part D (National Weather Service): Fetches forecast data for a location, requires a custom User-Agent header, saves results 
as nws_forecast.json, and demonstrates missing header behavior.

Outputs: Open-Meteo CSV (openmeteo_weather.csv) and terminal prints for max/min temperatures and error handling. 
OpenWeatherMap JSON (openweather_cities.json) and terminal prints for weather data, invalid API key tests, and hottest/coldest city. 
National Weather Service JSON (nws_forecast.json) and terminal prints for forecast URL and missing User-Agent test (status code + snippet)
