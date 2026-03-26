import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../widgets/app_bottom_bar.dart';

const _googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

class ClinicsScreen extends StatefulWidget {
  const ClinicsScreen({super.key});

  @override
  State<ClinicsScreen> createState() => _ClinicsScreenState();
}

class _ClinicsScreenState extends State<ClinicsScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<_ClinicPlace> _clinics = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNearbyClinics();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadNearbyClinics() async {
    if (_googleMapsApiKey.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Google Maps is not configured yet. Add your API key before using Clinics.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final permission = await _ensureLocationAccess();
      if (!permission) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Location permission is required to find clinics near you.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final clinics = await _fetchClinics(position);

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _clinics = clinics;
        _isLoading = false;
        if (clinics.isEmpty) {
          _errorMessage =
              'No clinics found nearby. Try again from another area.';
        }
      });

      if (clinics.isNotEmpty) {
        await _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(_buildBounds(position, clinics), 56),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load nearby clinics right now.';
      });
    }
  }

  Future<bool> _ensureLocationAccess() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<List<_ClinicPlace>> _fetchClinics(Position position) async {
    final uri = Uri.parse('https://places.googleapis.com/v1/places:searchText');
    final response = await http.post(
      uri,
      headers:
          const {
              'Content-Type': 'application/json',
              'X-Goog-FieldMask':
                  'places.id,places.displayName,places.formattedAddress,places.location,places.googleMapsUri,places.rating,places.userRatingCount',
            }.map((key, value) => MapEntry(key, value)).cast<String, String>()
            ..['X-Goog-Api-Key'] = _googleMapsApiKey,
      body: jsonEncode({
        'textQuery': 'medical clinic',
        'maxResultCount': 8,
        'rankPreference': 'DISTANCE',
        'locationBias': {
          'circle': {
            'center': {
              'latitude': position.latitude,
              'longitude': position.longitude,
            },
            'radius': 5000.0,
          },
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Places API returned ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final places = (data['places'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();

    return places
        .map(_ClinicPlace.fromJson)
        .where((place) => place.latitude != null && place.longitude != null)
        .toList();
  }

  LatLngBounds _buildBounds(Position origin, List<_ClinicPlace> clinics) {
    final latitudes = <double>[origin.latitude];
    final longitudes = <double>[origin.longitude];

    for (final clinic in clinics) {
      latitudes.add(clinic.latitude!);
      longitudes.add(clinic.longitude!);
    }

    final southwest = LatLng(
      latitudes.reduce((a, b) => a < b ? a : b),
      longitudes.reduce((a, b) => a < b ? a : b),
    );
    final northeast = LatLng(
      latitudes.reduce((a, b) => a > b ? a : b),
      longitudes.reduce((a, b) => a > b ? a : b),
    );

    return LatLngBounds(southwest: southwest, northeast: northeast);
  }

  Set<Marker> _markers() {
    final markers = <Marker>{};
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current-location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(title: 'You are here'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    for (final clinic in _clinics) {
      markers.add(
        Marker(
          markerId: MarkerId(clinic.id),
          position: LatLng(clinic.latitude!, clinic.longitude!),
          infoWindow: InfoWindow(title: clinic.name, snippet: clinic.address),
        ),
      );
    }
    return markers;
  }

  Future<void> _openDirections(_ClinicPlace clinic) async {
    final uri = Uri.tryParse(clinic.googleMapsUri ?? '');
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Google Maps directions.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = _currentPosition;
    final initialTarget = LatLng(
      position?.latitude ?? 28.6139,
      position?.longitude ?? 77.2090,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: const AppBottomBar(selectedItem: 'Clinics'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Care Nearby',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadNearbyClinics,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF4FBFD), Color(0xFFEDF7FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFDDE8EE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find care close to you',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _googleMapsApiKey.isEmpty
                        ? 'Add your Google Maps API key to activate live nearby clinic search.'
                        : 'Using your current location to show nearby clinics, map pins, and quick directions.',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: SizedBox(
                height: 320,
                child: _googleMapsApiKey.isEmpty
                    ? Container(
                        color: const Color(0xFFEFF3FA),
                        padding: const EdgeInsets.all(24),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 48,
                              color: Color(0xFF6D7A8F),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Map preview is disabled until a Google Maps API key is configured.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: Color(0xFF5B6270),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: initialTarget,
                              zoom: position == null ? 11 : 13.5,
                            ),
                            myLocationEnabled: position != null,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            markers: _markers(),
                            onMapCreated: (controller) {
                              _mapController = controller;
                            },
                          ),
                          if (_isLoading)
                            const Positioned.fill(
                              child: ColoredBox(
                                color: Color(0xA6FFFFFF),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _loadNearbyClinics,
                    icon: const Icon(Icons.my_location_rounded),
                    label: const Text('Refresh Nearby'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppTheme.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFD),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDDE7ED)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Closest options',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (_clinics.isEmpty && !_isLoading)
              const Text(
                'No nearby clinics to show yet.',
                style: TextStyle(color: Color(0xFF6B7483)),
              ),
            for (final clinic in _clinics) ...[
              _ClinicCard(
                clinic: clinic,
                onDirectionsTap: () => _openDirections(clinic),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _ClinicCard extends StatelessWidget {
  final _ClinicPlace clinic;
  final VoidCallback onDirectionsTap;

  const _ClinicCard({required this.clinic, required this.onDirectionsTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: AppTheme.aqua,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinic.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      clinic.address,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Color(0xFF66707F),
                      ),
                    ),
                  ],
                ),
              ),
              if (clinic.rating != null)
                Text(
                  '${clinic.rating!.toStringAsFixed(1)}★',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2A2F39),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onDirectionsTap,
            icon: const Icon(Icons.directions_rounded),
            label: const Text('Open Directions'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111827),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicPlace {
  final String id;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final String? googleMapsUri;

  const _ClinicPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.googleMapsUri,
  });

  factory _ClinicPlace.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? const {};
    final displayName =
        json['displayName'] as Map<String, dynamic>? ?? const {};

    return _ClinicPlace(
      id: json['id'] as String? ?? UniqueKey().toString(),
      name: displayName['text'] as String? ?? 'Nearby clinic',
      address: json['formattedAddress'] as String? ?? 'Address unavailable',
      latitude: (location['latitude'] as num?)?.toDouble(),
      longitude: (location['longitude'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      googleMapsUri: json['googleMapsUri'] as String?,
    );
  }
}
