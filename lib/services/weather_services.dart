import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather/model/weather_model.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  static const BASE_URL = "http://api.openweathermap.org/data/2.5/weather";
  static const FORECAST_URL = "http://api.openweathermap.org/data/2.5/forecast";
  final String api_key;

  WeatherService(this.api_key);

  Future<Weather> getWeather(String cityName) async {
    final response = await http.get(Uri.parse('$BASE_URL?q=$cityName&appid=$api_key&units=metric'));

    if (response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error while fetching the data');
    }
  }

  Future<List<Forecast>> getForecast(String cityName) async {
    final response = await http.get(Uri.parse('$FORECAST_URL?q=$cityName&appid=$api_key&units=metric'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['list'];
      return data.map((forecast) => Forecast.fromJson(forecast)).toList();
    } else {
      throw Exception('Error while fetching the forecast data');
    }
  }

  Future<String> getCurrentCity() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

    String? city = placemarks[0].locality;
    return city ?? "";
  }
}
