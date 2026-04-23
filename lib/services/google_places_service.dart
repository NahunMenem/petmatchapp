import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

class PlaceSuggestion {
  final String description;
  final String placeId;

  const PlaceSuggestion({
    required this.description,
    required this.placeId,
  });
}

class PlaceDetails {
  final String formattedAddress;
  final double latitude;
  final double longitude;

  const PlaceDetails({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });
}

class GooglePlacesService {
  GooglePlacesService({Dio? dio}) : _dio = dio ?? Dio();

  static const _apiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: 'AIzaSyDVv_barlVwHJTgLF66dP4ESUffCBuS3uA',
  );

  final Dio _dio;
  String? lastError;

  Future<List<PlaceSuggestion>> autocomplete(String input) async {
    final query = input.trim();
    if (query.length < 3) return const [];
    lastError = null;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': query,
          'key': _apiKey,
          'language': 'es',
          'components': 'country:ar',
          'types': 'geocode',
          'region': 'ar',
        },
      );

      final data = response.data ?? {};
      final status = data['status'] as String?;
      if (status == 'ZERO_RESULTS') {
        return _autocompleteFromGeocode(query);
      }
      if (status != 'OK') {
        lastError = data['error_message'] as String? ?? status;
        debugPrint('Google Places autocomplete error: $lastError');
        return _autocompleteFromGeocode(query);
      }

      final predictions = data['predictions'] as List<dynamic>? ?? [];
      final suggestions = predictions
          .map((item) => item as Map<String, dynamic>)
          .map(
            (item) => PlaceSuggestion(
              description: item['description'] as String? ?? '',
              placeId: item['place_id'] as String? ?? '',
            ),
          )
          .where(
              (item) => item.description.isNotEmpty && item.placeId.isNotEmpty)
          .toList();
      if (suggestions.isNotEmpty) return suggestions;
      return _autocompleteFromGeocode(query);
    } catch (error) {
      lastError = error.toString();
      debugPrint('Google Places autocomplete exception: $error');
      return _autocompleteFromGeocode(query);
    }
  }

  Future<List<PlaceSuggestion>> _autocompleteFromGeocode(String query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'address': query,
          'key': _apiKey,
          'language': 'es',
          'components': 'country:AR',
          'region': 'ar',
        },
      );

      final data = response.data ?? {};
      final status = data['status'] as String?;
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        lastError = data['error_message'] as String? ?? status;
        debugPrint('Google Geocoding fallback error: $lastError');
      }

      final results = data['results'] as List<dynamic>? ?? [];
      return results
          .take(5)
          .map((item) => item as Map<String, dynamic>)
          .map(
            (item) => PlaceSuggestion(
              description: item['formatted_address'] as String? ?? '',
              placeId: item['place_id'] as String? ?? '',
            ),
          )
          .where(
            (item) => item.description.isNotEmpty && item.placeId.isNotEmpty,
          )
          .toList();
    } catch (error) {
      debugPrint('Google Geocoding fallback exception: $error');
      return const [];
    }
  }

  Future<PlaceDetails?> getDetails(String placeId) async {
    if (placeId.isEmpty) return null;
    lastError = null;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'key': _apiKey,
          'language': 'es',
          'fields': 'formatted_address,geometry',
        },
      );

      final data = response.data ?? {};
      if (data['status'] != 'OK') {
        lastError =
            data['error_message'] as String? ?? data['status'] as String?;
        debugPrint('Google Places details error: $lastError');
        return null;
      }

      final result = data['result'] as Map<String, dynamic>? ?? {};
      final geometry = result['geometry'] as Map<String, dynamic>? ?? {};
      final location = geometry['location'] as Map<String, dynamic>? ?? {};
      final lat = (location['lat'] as num?)?.toDouble();
      final lng = (location['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;

      return PlaceDetails(
        formattedAddress: result['formatted_address'] as String? ?? '',
        latitude: lat,
        longitude: lng,
      );
    } catch (error) {
      lastError = error.toString();
      debugPrint('Google Places details exception: $error');
      return null;
    }
  }

  Future<PlaceDetails?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final marks = await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (marks.isEmpty) {
        return PlaceDetails(
          formattedAddress:
              '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
          latitude: latitude,
          longitude: longitude,
        );
      }

      final mark = marks.first;
      final parts = [
        mark.street,
        mark.subLocality,
        mark.locality,
        mark.administrativeArea,
      ].where((part) => part != null && part.trim().isNotEmpty).cast<String>();

      return PlaceDetails(
        formattedAddress: parts.join(', '),
        latitude: latitude,
        longitude: longitude,
      );
    } catch (error) {
      debugPrint('Native reverse geocode exception: $error');
      return null;
    }
  }

  Future<PlaceDetails?> forwardGeocode(String address) async {
    final query = address.trim();
    if (query.length < 3) return null;

    try {
      final locations = await geocoding.locationFromAddress(query);
      if (locations.isEmpty) return null;

      final location = locations.first;
      return PlaceDetails(
        formattedAddress: query,
        latitude: location.latitude,
        longitude: location.longitude,
      );
    } catch (error) {
      debugPrint('Native forward geocode exception: $error');
      return null;
    }
  }
}
