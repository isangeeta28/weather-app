import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bloc/weather_bloc.dart';
import '../bloc/weather_event.dart';
import '../bloc/weather_state.dart';
import '../services/city_location_services.dart';

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _locationController = TextEditingController();
  late WeatherBloc _weatherBloc;
  final CitySuggestionService _citySuggestionService = CitySuggestionService();

  @override
  void initState() {
    super.initState();
    _weatherBloc = BlocProvider.of<WeatherBloc>(context);
    _loadLastLocation();
  }

  Future<void> _loadLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLocation = prefs.getString('last_location') ?? '';
    if (lastLocation.isNotEmpty) {
      _locationController.text = lastLocation;
      _weatherBloc.add(FetchWeather(lastLocation));
    }
  }

  Future<void> _fetchWeatherForCurrentLocation() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      Position position = await Geolocator.getCurrentPosition();
      String location = '${position.latitude},${position.longitude}'; // Use coordinates for API
      _weatherBloc.add(FetchWeather(location));
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Location Permission'),
          content: Text('Location permission is required to use this feature.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Weather App'),
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: _fetchWeatherForCurrentLocation,
          ),
        ],
      ),
      body: BlocBuilder<WeatherBloc, WeatherState>(
        builder: (context, state) {
          String backgroundImage = 'assets/default_background.jpg'; // Default background

          if (state is WeatherLoaded) {
            final condition = state.weatherData['weather'][0]['main'];
            backgroundImage = _getBackgroundImageForCondition(condition);
          }

          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(backgroundImage),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding:  EdgeInsets.only(top:MediaQuery.sizeOf(context).height*0.12, left: 16.0, right: 16.0, bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TypeAheadField<String>(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _locationController,
                      style: TextStyle(
                        color: Colors.black
                      ),
                      decoration: InputDecoration(
                        labelText: 'Enter city name',
                        suffixIcon: IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () {
                            final location = _locationController.text;
                            _weatherBloc.add(FetchWeather(location));
                          },
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.black
                          )
                        )
                      ),
                    ),
                    suggestionsCallback: (pattern) async {
                      if (pattern.isNotEmpty) {
                        return await _citySuggestionService.getSuggestions(pattern);
                      }
                      return [];
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        title: Text(suggestion),
                      );
                    },
                    onSuggestionSelected: (suggestion) {
                      _locationController.text = suggestion;
                      _weatherBloc.add(FetchWeather(suggestion));
                    },
                  ),
                  SizedBox(height: 20),
                  if (state is WeatherInitial)
                    Center(
                      child: Text(
                        'Enter a location to get the weather.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )
                  else if (state is WeatherLoading)
                    Center(
                      child: CircularProgressIndicator(),
                    )
                  else if (state is WeatherLoaded)
                      WeatherInfo(weatherData: state.weatherData)
                    else if (state is WeatherError)
                        Center(
                          child: Text(
                            state.message,
                            style: TextStyle(color: Colors.red, fontSize: 16),
                          ),
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getBackgroundImageForCondition(String condition) {
    switch (condition) {
      case 'Clear':
        return 'assets/sunny_background.png';
      case 'Rain':
        return 'assets/rainy_background.jpg';
      case 'Clouds':
        return 'assets/cloudy_background.png';
      case 'Snow':
        return 'assets/snowy_background.jpg';
      default:
        return 'assets/default_background.png';
    }
  }
}

class WeatherInfo extends StatelessWidget {
  final Map<String, dynamic> weatherData;

  WeatherInfo({required this.weatherData});

  @override
  Widget build(BuildContext context) {
    final temperature = weatherData['main']['temp'];
    final humidity = weatherData['main']['humidity'];
    final windSpeed = weatherData['wind']['speed'];
    final condition = weatherData['weather'][0]['description'];
    final iconCode = weatherData['weather'][0]['icon'];

    return Card(
      color: Colors.white.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.network(
                  'http://openweathermap.org/img/wn/$iconCode.png',
                  width: 80,
                  height: 80,
                ),
                SizedBox(width: 16),
                Text(
                  '$temperature°C',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Humidity: $humidity%',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              'Wind Speed: $windSpeed m/s',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              'Condition: $condition',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}