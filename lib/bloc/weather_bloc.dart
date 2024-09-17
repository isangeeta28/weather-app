import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/weather_services.dart';
import 'weather_event.dart';
import 'weather_state.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  final WeatherService _weatherService;

  WeatherBloc(this._weatherService) : super(WeatherInitial()) {
    on<FetchWeather>((event, emit) async {
      emit(WeatherLoading());
      try {
        final weatherData = await _weatherService.fetchWeather(event.location);
        emit(WeatherLoaded(weatherData));
      } catch (e) {
        emit(WeatherError('Unable to fetch weather data. Please try again.'));
      }
    });
  }
}
