import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/app_ui.dart';

const _googleMapsApiKey = String.fromEnvironment('MAPS_RUNTIME_KEY');

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
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  static const List<String> _filters = <String>[
    'All',
    'General',
    'Cardio',
    'Dental',
    'Pediatrics',
  ];

  @override
  void initState() {
    super.initState();
    _loadNearbyClinics();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
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
    } catch (_) {
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

    for (final clinic in _visibleClinics) {
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

  List<_ClinicPlace> get _visibleClinics {
    final query = _searchController.text.trim().toLowerCase();
    return _clinics.where((clinic) {
      final matchesFilter =
          _selectedFilter == 'All' || clinic.category == _selectedFilter;
      final matchesQuery =
          query.isEmpty ||
          clinic.name.toLowerCase().contains(query) ||
          clinic.address.toLowerCase().contains(query) ||
          clinic.category.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
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
    final visibleClinics = _visibleClinics;

    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: const AppBottomBar(selectedItem: 'Clinics'),
      body: RefreshIndicator(
        onRefresh: _loadNearbyClinics,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            AppHeader(
              eyebrow: 'Clinics',
              title: 'Care nearby',
              subtitle:
                  'Search clinics, view the map, and open directions from one place.',
              trailing: AppIconButton(
                icon: Icons.my_location_rounded,
                onTap: _isLoading ? null : _loadNearbyClinics,
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppTheme.heroGradient,
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppBadge(
                    text: 'Unified care finder',
                    color: Colors.white,
                    backgroundColor: Color(0x29FFFFFF),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Find the right place faster',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Search by clinic name, area, or specialty, then compare nearby options without leaving the screen.',
                    style: TextStyle(
                      color: Colors.white,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search clinic, specialty, or area',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  return ChoiceChip(
                    label: Text(filter),
                    selected: filter == _selectedFilter,
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemCount: _filters.length,
              ),
            ),
            const SizedBox(height: 18),
            AppCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 320,
                  child: _googleMapsApiKey.isEmpty
                      ? Container(
                          color: AppTheme.backgroundRaised,
                          padding: const EdgeInsets.all(24),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map_outlined,
                                size: 48,
                                color: AppTheme.violet,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Map preview is disabled until a Google Maps API key is configured.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.45,
                                  color: AppTheme.textMuted,
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
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              AppCard(
                color: AppTheme.softSurface,
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            AppCard(
              color: AppTheme.sand,
              border: Border.all(color: AppTheme.amber.withValues(alpha: 0.2)),
              child: const Row(
                children: [
                  Icon(Icons.local_hospital_rounded, color: AppTheme.amber),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'If symptoms feel severe or suddenly worse, call before traveling and seek urgent in-person care.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionTitle(
              title: 'Nearby options',
              action: visibleClinics.isEmpty
                  ? null
                  : '${visibleClinics.length} found',
            ),
            const SizedBox(height: 12),
            if (visibleClinics.isEmpty && !_isLoading)
              const AppCard(
                child: Text(
                  'No nearby clinics match the current search. Try another specialty or refresh your location.',
                  style: TextStyle(color: AppTheme.textMuted, height: 1.45),
                ),
              ),
            for (final clinic in visibleClinics) ...[
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.scrub,
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      clinic.address,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              AppBadge(text: clinic.category, color: AppTheme.blue),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoPill(icon: Icons.route_rounded, label: clinic.distanceLabel),
              if (clinic.rating != null)
                _InfoPill(
                  icon: Icons.star_rounded,
                  label: clinic.rating!.toStringAsFixed(1),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDirectionsTap,
                  icon: const Icon(Icons.directions_rounded),
                  label: const Text('Open directions'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDirectionsTap,
                  icon: const Icon(Icons.navigation_rounded),
                  label: const Text('Go now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.softSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
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

  String get category {
    final text = '$name $address'.toLowerCase();
    if (text.contains('card')) return 'Cardio';
    if (text.contains('dental')) return 'Dental';
    if (text.contains('child') || text.contains('pediatric')) {
      return 'Pediatrics';
    }
    return 'General';
  }

  String get distanceLabel => 'Nearby';
}
