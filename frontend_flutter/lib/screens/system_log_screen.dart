import 'package:flutter/material.dart';

class SystemLogScreen extends StatefulWidget {
  const SystemLogScreen({super.key});

  @override
  State<SystemLogScreen> createState() => _SystemLogScreenState();
}

class _SystemLogScreenState extends State<SystemLogScreen> {
  String _selectedFilter = 'All';

  static const List<String> _filters = [
    'All',
    'Critical',
    'Warning',
    'Healthy',
  ];

  static const List<_LogEntry> _entries = [
    _LogEntry(
      title: 'Blood pressure spike detected',
      timestamp: 'Today, 08:42 AM',
      severity: 'Critical',
      description:
          'Systolic pressure crossed your configured threshold after medication was skipped.',
      icon: Icons.monitor_heart_rounded,
      color: Color(0xFFE45D72),
      background: Color(0xFFFFE6EB),
    ),
    _LogEntry(
      title: 'Hydration reminder acknowledged',
      timestamp: 'Today, 07:10 AM',
      severity: 'Healthy',
      description:
          'Daily hydration target is at 74%. Keep tracking fluid intake through the afternoon.',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF1D9ED8),
      background: Color(0xFFE1F5FF),
    ),
    _LogEntry(
      title: 'Sleep pattern irregular',
      timestamp: 'Yesterday, 11:48 PM',
      severity: 'Warning',
      description:
          'Sleep duration dropped below 6 hours for the second time this week.',
      icon: Icons.nightlight_round,
      color: Color(0xFF9B63E6),
      background: Color(0xFFF1E9FF),
    ),
    _LogEntry(
      title: 'Medication logged on time',
      timestamp: 'Yesterday, 09:00 PM',
      severity: 'Healthy',
      description:
          'Evening medication intake was recorded and synced successfully.',
      icon: Icons.medication_rounded,
      color: Color(0xFF2EBC73),
      background: Color(0xFFE2F8EB),
    ),
    _LogEntry(
      title: 'Heart rate trending upward',
      timestamp: 'Mar 08, 06:35 PM',
      severity: 'Warning',
      description:
          'Resting heart rate moved 11% above your weekly baseline after limited activity.',
      icon: Icons.favorite_rounded,
      color: Color(0xFFF19A38),
      background: Color(0xFFFFF0DB),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleEntries = _selectedFilter == 'All'
        ? _entries
        : _entries.where((entry) => entry.severity == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB7E6F8), Color(0xFFDCC8FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _RoundIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const _RoundBadge(
                        icon: Icons.sync_rounded,
                        label: 'Live',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'System Log',
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Monitor alerts, successful syncs, and daily health events in one timeline.',
                    style: TextStyle(fontSize: 16, height: 1.35),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: const [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Critical',
                          value: '01',
                          color: Color(0xFFE45D72),
                          icon: Icons.priority_high_rounded,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Today',
                          value: '03',
                          color: Color(0xFF4B73FF),
                          icon: Icons.today_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = filter == _selectedFilter;
                    return ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      showCheckmark: false,
                      onSelected: (_) {
                        setState(() => _selectedFilter = filter);
                      },
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF4A5572),
                        fontWeight: FontWeight.w600,
                      ),
                      selectedColor: const Color(0xFF4B73FF),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.transparent
                              : const Color(0xFFE1E6F0),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: visibleEntries.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2433),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: const [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Color(0xFF31384D),
                            child: Icon(
                              Icons.security_rounded,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'System health is stable. One critical alert still needs review.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final entry = visibleEntries[index - 1];
                  return _LogCard(entry: entry);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final _LogEntry entry;

  const _LogCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: entry.background,
            child: Icon(entry.icon, color: entry.color, size: 27),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _SeverityBadge(
                      label: entry.severity,
                      color: entry.color,
                      background: entry.background,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  entry.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF667085),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: Color(0xFF98A2B3),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.timestamp,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF98A2B3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _SeverityBadge({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: const Color(0xFF1F2433)),
        ),
      ),
    );
  }
}

class _RoundBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RoundBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1F2433)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _LogEntry {
  final String title;
  final String timestamp;
  final String severity;
  final String description;
  final IconData icon;
  final Color color;
  final Color background;

  const _LogEntry({
    required this.title,
    required this.timestamp,
    required this.severity,
    required this.description,
    required this.icon,
    required this.color,
    required this.background,
  });
}
