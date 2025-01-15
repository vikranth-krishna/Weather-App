import 'package:flutter/material.dart'; // Flutter UI framework
import 'package:provider/provider.dart'; // State management using Provider
import 'package:weather/pages/weather_page.dart'; // Main weather page
import 'package:weather/providers/weather_provider.dart'; // Weather state management
import 'package:weather/services/weather_services.dart'; // Weather API service

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => WeatherProvider(
            weatherService: WeatherService('75be21016597ada10c0c971bf3bc221a'),
          )..loadLastCity(), // Load the last searched city or use current location on startup
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Hide debug banner
      home: const WeatherPage(), // Set the home screen to the WeatherPage
    );
  }
}
