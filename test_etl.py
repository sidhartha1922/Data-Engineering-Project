import requests 
import pandas as pd 
import json 
import os 
from dotenv import load_dotenv
from datetime import datetime
import logging 

load_dotenv()
API_KEY = os.getenv("OPENWEATHER_API_KEY")
BASE_URL = "http://api.openweathermap.org/data/2.5/weather?"
city_lst = ["London", "Tokyo", "Delhi", "Sydney"]

def fetch_weather_data(city_name):
    complete_url = f"{BASE_URL}q={city_name}&appid={API_KEY}&units=metric"
    response = requests.get(complete_url)
    if response.status_code == 200:
        data = response.json()
        weather_type = data['weather'][0]['main']
        weather_desc = data['weather'][0]['description']
        main = data['main']
        temp = main['temp']
        feels_like = main['feels_like']
        humidity = main['humidity']
        pressure = main['pressure']
        wind_speed = data['wind']['speed']
        temp_boundary = (main['temp_min'], main['temp_max'])
        weather_data = {
                'city': city_name,
                'temperature': temp,
                'feels_like': feels_like,
                'type_of_weather': weather_type,
                'temp_min': temp_boundary[0],
                'temp_max': temp_boundary[1],
                'humidity': humidity,
                'pressure': pressure,
                'wind_speed': wind_speed,
                'description': weather_desc,
                'date': datetime.now().date()
            }
        
        return weather_data
    
def store_datain_csv(fullfilepath):
        data_list = []
        for city in city_lst:
            data = fetch_weather_data(city)
            try :
                if data:
                    data_list.append(data)
                    logging.info(f"Data fetched for {city}")
            except Exception as e:
                logging.error(f"Error fetching data for {city}: {e}")
                raise 
                

        df = pd.DataFrame(data_list)
        df.to_csv(fullfilepath, index=False)
        logging.info(f"Data stored in {fullfilepath}")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
    file_name = input("Enter the file name to store data (with .csv extension): ")
    file_path = input("Enter the directory path to store the file: ")
    fullfilepath = os.path.join(file_path, file_name)
    store_datain_csv(fullfilepath)
    

    logging.info("ETL process completed successfully.")