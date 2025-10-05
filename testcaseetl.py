import pytest 
import os 
import pandas as pd 
from src.weather_data_fetch import fetch_weather_data, store_datain_csv
from unittest.mock import patch, MagicMock

@pytest.fixture
def mock_weather_data():
    return {
        'city': 'London',
        'temperature': 25,
        'feels_like': 27,
        'type_of_weather': 'Clear',
        'temp_min': 20,
        'temp_max': 30,
        'humidity': 50,
        'pressure': 1012,
        'wind_speed': 5,
        'description': 'clear sky',
        'date': pd.to_datetime('2023-10-01').date()
    }

@patch('src.weather_data_fetch.fetch_weather_data')
@patch('src.weather_data_fetch.pd.DataFrame')
def test_store_datain_csv(mock_df,mock_fetch):
    mock_fetch.return_value = {'city': 'London',
        'temperature': 20,
        'feels_like': 19,
        'type_of_weather': 'Clear',
        'temp_min': 18,
        'temp_max': 22,
        'humidity': 60,
        'pressure': 1012,
        'wind_speed': 5,
        'description': 'clear sky',
        'date': '2025-09-26'
    }
    mock_df.return_value = MagicMock()
    fullfilepath = 'test_weather_data.csv'
    store_datain_csv(fullfilepath)
    mock_df.assert_called_once()
    mock_df.return_value.to_csv.assert_called_once_with(fullfilepath, index=False)
    
    
@patch('src.weather_data_fetch.fetch_weather_data')
@patch('src.weather_data_fetch.pd.DataFrame')
def test_store_datain_csv_exception(mock_fetch,mock_df):
    #mock fetch weather data to raise an exception
    def side_effect(city):
        raise Exception("API Error")
    mock_fetch.side_effect = side_effect
    mock_df.return_value = MagicMock()
    fullfilepath = 'test_weather_data.csv'
    with pytest.raises(Exception) as excinfo:
        store_datain_csv(fullfilepath)
    assert "API Error" in str(excinfo.value)
    #mock_df.assert_called_with([])  # Ensure DataFrame is called with empty list
    #mock_df.return_value.to_csv.assert_called_once_with(fullfilepath, index=False)




