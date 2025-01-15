import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:weather/providers/weather_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';  // Importing intl package for date formatting

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final TextEditingController _cityController = TextEditingController();
  List<String> _suggestions = [];
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();  // Load recent searches from shared preferences when the screen loads
  }

  // Load recent searches from shared preferences
  _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  // Save recent searches to shared preferences
  _saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('recent_searches', _recentSearches);
  }

  // Update the recent search list when a city is searched
  _updateRecentSearches(String cityName) {
    setState(() {
      if (!_recentSearches.contains(cityName)) {
        _recentSearches.insert(0, cityName);
        if (_recentSearches.length > 5) {
          _recentSearches.removeLast();
        }
      }
      _saveRecentSearches();
    });
  }

  // Return the Lottie animation asset based on weather condition
  String getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return 'assets/sunny.json';
    switch (mainCondition.toLowerCase()) {
      case 'clouds':
        return 'assets/cloud.json';
      case 'mist':
        return 'assets/mist.json';
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return 'assets/cloud.json';
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        return 'assets/rain.json';
      case 'thunderstorm':
        return 'assets/thunder.json';
      case 'clear':
        return 'assets/sunny.json';
      default:
        return 'assets/sunny.json';
    }
  }

  // Function to format date to DD-MM-YYYY using DateFormat
  String formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd-MM-yyyy').format(parsedDate);  // Format the date
    } catch (e) {
      return date;  // Return the original date in case of error
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.white70,
        title: Text(
          "Weather App",
          style: TextStyle(fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _cityController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Enter city name...",
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.white),
                  suffixIcon: _cityController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _cityController.clear();
                        _suggestions = [];
                      });
                    },
                  )
                      : null,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                textInputAction: TextInputAction.search,
                onChanged: _getCitySuggestions,  // Trigger suggestions on text input
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    weatherProvider.fetchWeather(value);  // Fetch weather for the city
                    _updateRecentSearches(value);  // Update recent searches
                    setState(() => _suggestions = []);  // Clear suggestions
                  }
                },
              ),
            ),
          ),
          SizedBox(height: 20),
          if (_suggestions.isNotEmpty)
            Flexible(
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        _suggestions[index],
                        style: TextStyle(color: Colors.black),
                      ),
                      onTap: () {
                        _cityController.text = _suggestions[index];
                        weatherProvider.fetchWeather(_suggestions[index]);
                        _updateRecentSearches(_suggestions[index]);
                        setState(() => _suggestions = []);  // Clear suggestions on city select
                      },
                    );
                  },
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Center(
                  child: weatherProvider.isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Display city name
                      Text(
                        weatherProvider.weather?.cityName ?? "...city",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      // Display Lottie animation based on weather condition
                      Lottie.asset(
                        getWeatherAnimation(weatherProvider.weather?.mainCondition),
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 20),
                      // Display temperature with unit (Celsius or Fahrenheit)
                      Text(
                        '${weatherProvider.getTemperatureInPreferredUnit(weatherProvider.weather?.temperature ?? 0).round()}°${weatherProvider.temperatureUnit == 'Celsius' ? 'C' : 'F'}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Display weather condition (Clear, Clouds, etc.)
                      Text(
                        weatherProvider.weather?.mainCondition ?? "",
                        style: TextStyle(color: Colors.white, fontSize: 22),
                      ),
                      SizedBox(height: 30),
                      // Button to fetch weather from current location
                      ElevatedButton.icon(
                        onPressed: () => weatherProvider.fetchWeatherFromLocation(),
                        icon: Icon(Icons.location_on),
                        label: Text("Use Current Location"),
                      ),
                      SizedBox(height: 30),
                      // Recent searches section
                      if (_recentSearches.isNotEmpty) ...[
                        Text(
                          "Recent Searches",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: _recentSearches.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(_recentSearches[index], style: TextStyle(color: Colors.white)),
                              onTap: () {
                                weatherProvider.fetchWeather(_recentSearches[index]);
                              },
                            );
                          },
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _recentSearches.clear();  // Clear recent search history
                            });
                            _saveRecentSearches();  // Save cleared list to preferences
                          },
                          child: Text("Clear History"),
                        ),
                      ],
                      SizedBox(height: 30),
                      // Forecast section
                      if (weatherProvider.forecast.isNotEmpty)
                        Text(
                          "3-Day Forecast",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      SizedBox(height: 20),
                      if (weatherProvider.forecast.isNotEmpty)
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: weatherProvider.forecast.length,
                            itemBuilder: (context, index) {
                              final forecast = weatherProvider.forecast[index];
                              return Card(
                                color: Colors.white70,
                                margin: EdgeInsets.symmetric(horizontal: 8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Display formatted date
                                    Text(
                                      formatDate(forecast.date),
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    // Display weather animation based on forecast condition
                                    Lottie.asset(
                                      getWeatherAnimation(forecast.mainCondition),
                                      width: 100,
                                      height: 100,
                                    ),
                                    // Display temperature for forecast
                                    Text(
                                      '${weatherProvider.getTemperatureInPreferredUnit(forecast.temperature).round()}°${weatherProvider.temperatureUnit == 'Celsius' ? 'C' : 'F'}',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // Floating action button for toggling between Celsius and Fahrenheit
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white70,
        onPressed: () {
          weatherProvider.toggleTemperatureUnit();  // Toggle temperature unit
        },
        child: Icon(
          weatherProvider.temperatureUnit == 'Celsius' ? Icons.thermostat_outlined : Icons.ac_unit,
          color: Colors.black,
        ),
      ),
    );
  }

  // Fetch city suggestions based on search query
  _getCitySuggestions(String query) async {
    if (query.length < 3) return;  // Only fetch suggestions if query length is 3 or more
    final apiKey = '75be21016597ada10c0c971bf3bc221a';
    final url = 'http://api.openweathermap.org/geo/1.0/direct?q=$query&limit=5&appid=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _suggestions = data.map((city) => city['name'].toString()).toList();  // Update suggestions list
        });
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
    }
  }
}
