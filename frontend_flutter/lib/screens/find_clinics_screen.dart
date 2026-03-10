import 'package:flutter/material.dart';

class FindClinicsScreen extends StatefulWidget {
  const FindClinicsScreen({super.key});

  @override
  State<FindClinicsScreen> createState() => _FindClinicsScreenState();
}

class _FindClinicsScreenState extends State<FindClinicsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  static const List<String> _filters = <String>[
    'All',
    'General',
    'Cardio',
    'Dental',
    'Pediatrics',
  ];

  static const List<_Clinic> _clinics = <_Clinic>[
    _Clinic(
      name: 'CityCare Multispecialty Clinic',
      type: 'General',
      distance: '1.2 km',
      rating: '4.8',
      eta: '8 min',
      address: 'Civil Lines, near District Hospital',
      accentColor: Color(0xFF4E7BFF),
    ),
    _Clinic(
      name: 'HeartBeat Cardiac Center',
      type: 'Cardio',
      distance: '2.8 km',
      rating: '4.7',
      eta: '14 min',
      address: 'MG Road, Sector 4',
      accentColor: Color(0xFFE46B74),
    ),
    _Clinic(
      name: 'BrightSmiles Dental Studio',
      type: 'Dental',
      distance: '3.1 km',
      rating: '4.6',
      eta: '16 min',
      address: 'Gol Market, main plaza',
      accentColor: Color(0xFFF0A247),
    ),
    _Clinic(
      name: 'LittleSteps Child Clinic',
      type: 'Pediatrics',
      distance: '4.4 km',
      rating: '4.9',
      eta: '19 min',
      address: 'Shastri Nagar, Block B',
      accentColor: Color(0xFF2BC57B),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String query = _searchController.text.trim().toLowerCase();
    final List<_Clinic> visibleClinics = _clinics.where((clinic) {
      final bool matchesFilter =
          _selectedFilter == 'All' || clinic.type == _selectedFilter;
      final bool matchesQuery =
          query.isEmpty ||
          clinic.name.toLowerCase().contains(query) ||
          clinic.address.toLowerCase().contains(query) ||
          clinic.type.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB3E6F5), Color(0xFF99B8FF), Color(0xFFD9D7FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(42),
                  bottomRight: Radius.circular(42),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TopIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Find Clinics',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const _TopIconButton(icon: Icons.tune_rounded),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Nearby healthcare centers for quick appointments and consultation.',
                    style: TextStyle(fontSize: 15, height: 1.35),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search clinic, specialty, or area',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final String filter = _filters[index];
                        final bool isSelected = filter == _selectedFilter;
                        return ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedFilter = filter),
                          selectedColor: const Color(0xFF4567F9),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF4E5B74),
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: Colors.white,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) => const SizedBox(width: 10),
                      itemCount: _filters.length,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: visibleClinics.isEmpty
                  ? const Center(
                      child: Text(
                        'No clinics match your search.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      children: [
                        const _EmergencyBanner(),
                        const SizedBox(height: 18),
                        ...visibleClinics.map((clinic) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _ClinicCard(clinic: clinic),
                            )),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _TopIconButton({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.84),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: const Color(0xFF364056)),
      ),
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  const _EmergencyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF263A74), Color(0xFF4C6FE8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need urgent help?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Choose the nearest clinic below and call before visiting.',
                  style: TextStyle(color: Colors.white70, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicCard extends StatelessWidget {
  final _Clinic clinic;

  const _ClinicCard({required this.clinic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x15000000), blurRadius: 18, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: clinic.accentColor.withValues(alpha: 0.14),
                child: Icon(Icons.add_location_alt_rounded, color: clinic.accentColor, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinic.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      clinic.address,
                      style: const TextStyle(color: Color(0xFF69758D), height: 1.25),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  clinic.type,
                  style: const TextStyle(
                    color: Color(0xFF4567F9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoPill(icon: Icons.route_rounded, label: clinic.distance),
              _InfoPill(icon: Icons.star_rounded, label: clinic.rating),
              _InfoPill(icon: Icons.schedule_rounded, label: clinic.eta),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Call ${clinic.name}')),
                    );
                  },
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF364056),
                    side: const BorderSide(color: Color(0xFFDCE3F4)),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Open directions to ${clinic.name}')),
                    );
                  },
                  icon: const Icon(Icons.directions_rounded),
                  label: const Text('Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: clinic.accentColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
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

  const _InfoPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF5D6B84)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF5D6B84),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Clinic {
  final String name;
  final String type;
  final String distance;
  final String rating;
  final String eta;
  final String address;
  final Color accentColor;

  const _Clinic({
    required this.name,
    required this.type,
    required this.distance,
    required this.rating,
    required this.eta,
    required this.address,
    required this.accentColor,
  });
}
