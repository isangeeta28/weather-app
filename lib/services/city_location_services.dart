// lib/services/city_suggestion_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class CitySuggestionService {
  final String _apiKey = 'd9f36003d430c2e150deb53eacdfda0a'; // Replace with your API key

  Future<List<String>> getSuggestions(String query) async {
    final response = await http.get(
      Uri.parse('https://api.openweathermap.org/geo/1.0/direct?q=$query&limit=5&appid=$_apiKey'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map<String>((city) => city['name'] as String).toList();
    } else {
      throw Exception('Failed to load city suggestions');
    }
  }
}
