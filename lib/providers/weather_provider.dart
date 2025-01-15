import 'package:flutter/material.dart';
import 'package:weather/services/weather_services.dart';
import 'package:weather/model/weather_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService weatherService;
  Weather? weather;
  bool isLoading = false;
  bool isFetchingLocation = false;
  List<Forecast> forecast = [];
  String temperatureUnit = 'Celsius';  // Default unit is Celsius

  WeatherProvider({required this.weatherService});

  // Load the last city and unit from preferences
  Future<void> loadLastCity() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCity = prefs.getString('last_city');
    temperatureUnit = prefs.getString('temperature_unit') ?? 'Celsius';

    if (lastCity != null && lastCity.isNotEmpty) {
      fetchWeather(lastCity);
    } else {
      fetchWeatherFromLocation();
    }
  }

  // Fetch weather by city name
  Future<void> fetchWeather(String cityName) async {
    if (cityName.isEmpty) return;

    isLoading = true;
    notifyListeners();

    try {
      weather = await weatherService.getWeather(cityName);
      forecast = await weatherService.getForecast(cityName);
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('last_city', cityName);  // Save the city for future use
    } catch (e) {
      print('Error fetching weather for $cityName: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Fetch weather based on current location
  Future<void> fetchWeatherFromLocation() async {
    if (isFetchingLocation) return;
    isFetchingLocation = true;
    notifyListeners();

    try {
      final city = await weatherService.getCurrentCity();
      if (city.isNotEmpty) {
        fetchWeather(city);
      }
    } catch (e) {
      print('Error fetching location: $e');
    } finally {
      isFetchingLocation = false;
      notifyListeners();
    }
  }

  // Switch temperature unit between Celsius and Fahrenheit
  void toggleTemperatureUnit() async {
    temperatureUnit = temperatureUnit == 'Celsius' ? 'Fahrenheit' : 'Celsius';
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('temperature_unit', temperatureUnit);
    notifyListeners();
  }

  // Convert temperature based on the selected unit
  double getTemperatureInPreferredUnit(double temperatureInCelsius) {
    return temperatureUnit == 'Celsius'
        ? temperatureInCelsius
        : (temperatureInCelsius * 9/5) + 32;
  }
}
