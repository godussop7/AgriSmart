import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final int weatherCode;
  final String description;
  final String icon;

  const WeatherData({
    required this.temperature,
    required this.weatherCode,
    required this.description,
    required this.icon,
  });
}

class WeatherService {
  static const _regionCoords = <String, (double, double)>{
    'dakar': (14.6937, -17.4441),
    'thiès': (14.7910, -16.9359),
    'thies': (14.7910, -16.9359),
    'saint-louis': (16.0179, -16.4896),
    'kaolack': (14.1519, -16.0726),
    'ziguinchor': (12.5681, -16.2719),
    'touba': (14.8500, -15.8833),
    'default': (14.6937, -17.4441),
  };

  static Future<WeatherData> fetchWeather({String? regionName}) async {
    final key = (regionName ?? 'dakar').toLowerCase().trim();
    var coords = _regionCoords['default']!;
    for (final entry in _regionCoords.entries) {
      if (key.contains(entry.key)) {
        coords = entry.value;
        break;
      }
    }

    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=${coords.$1}&longitude=${coords.$2}'
        '&current=temperature_2m,weather_code&timezone=Africa%2FDakar',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final current = json['current'] as Map<String, dynamic>;
        final code = current['weather_code'] as int? ?? 0;
        final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 28.0;
        return WeatherData(
          temperature: temp,
          weatherCode: code,
          description: _weatherDescription(code),
          icon: _weatherIcon(code),
        );
      }
    } catch (_) {}

    return const WeatherData(
      temperature: 28,
      weatherCode: 1,
      description: 'Partiellement nuageux',
      icon: '⛅',
    );
  }

  static String _weatherDescription(int code) {
    if (code == 0) return 'Ensoleillé';
    if (code <= 3) return 'Partiellement nuageux';
    if (code <= 48) return 'Brumeux';
    if (code <= 67) return 'Pluie';
    if (code <= 77) return 'Neige / grêle';
    if (code <= 82) return 'Averses';
    return 'Orageux';
  }

  static String _weatherIcon(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 48) return '🌫️';
    if (code <= 67) return '🌧️';
    if (code <= 82) return '🌦️';
    return '⛈️';
  }
}
