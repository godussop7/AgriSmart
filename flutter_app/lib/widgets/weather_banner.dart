import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/weather_service.dart';
import '../utils/constants.dart';

class WeatherBanner extends StatefulWidget {
  final String? regionName;

  const WeatherBanner({super.key, this.regionName});

  @override
  State<WeatherBanner> createState() => _WeatherBannerState();
}

class _WeatherBannerState extends State<WeatherBanner> {
  WeatherData? _weather;
  String? _advice;
  bool _loading = true;
  bool _fromBackend = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(WeatherBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.regionName != widget.regionName) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final backend = await ApiService.getBackendWeather();
    if (backend != null && backend['weather'] != null) {
      final w = backend['weather'] as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _weather = WeatherData(
            temperature: (w['temperature'] as num?)?.toDouble() ?? 28,
            weatherCode: 0,
            description: w['description']?.toString() ?? '—',
            icon: _iconFromDescription(w['description']?.toString() ?? ''),
          );
          _advice = backend['advice']?.toString();
          _fromBackend = true;
          _loading = false;
        });
      }
      return;
    }

    final data =
        await WeatherService.fetchWeather(regionName: widget.regionName);
    if (mounted) {
      setState(() {
        _weather = data;
        _advice = null;
        _fromBackend = false;
        _loading = false;
      });
    }
  }

  String _iconFromDescription(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('pluie')) return '🌧️';
    if (d.contains('nuage')) return '⛅';
    if (d.contains('soleil') || d.contains('clair')) return '☀️';
    if (d.contains('orage')) return '⛈️';
    return '⛅';
  }

  @override
  Widget build(BuildContext context) {
    final region = widget.regionName ??
        context.watch<AuthProvider>().user?.regionName ??
        'Sénégal';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0EA5E9).withValues(alpha: 0.12),
            AppColors.primary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.2)),
      ),
      child: _loading
          ? const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Chargement météo...',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_weather!.icon, style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_weather!.temperature.round()}°C • ${_weather!.description}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              fontFamily: 'Outfit',
                            ),
                          ),
                          Text(
                            region,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded,
                          color: Color(0xFF0EA5E9), size: 22),
                    ),
                  ],
                ),
                if (_advice != null && _advice!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _advice!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
                if (!_fromBackend)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Source: Open-Meteo',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textTertiary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
