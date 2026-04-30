import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../services/analysis_history_service.dart';
import '../services/api_service.dart';
import '../services/auth_exceptions.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/app_ui.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  static const int _maxFileBytes = 10 * 1024 * 1024;
  File? _file;
  bool _loading = false;
  String? _error;
  String? _status;
  Map<String, dynamic>? _result;

  Future<void> _pickFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'png', 'jpg', 'jpeg'],
    );
    if (picked == null || picked.files.single.path == null) return;
    final selectedFile = File(picked.files.single.path!);
    final extension = p
        .extension(selectedFile.path)
        .replaceFirst('.', '')
        .toLowerCase();
    if (!['pdf', 'txt', 'png', 'jpg', 'jpeg'].contains(extension)) {
      setState(() {
        _file = null;
        _error = 'Choose a PDF, TXT, PNG, JPG, or JPEG report.';
        _status = null;
        _result = null;
      });
      return;
    }
    if (await selectedFile.length() > _maxFileBytes) {
      setState(() {
        _file = selectedFile;
        _error = 'Selected file is larger than 10 MB. Choose a smaller report.';
        _status = null;
        _result = null;
      });
      return;
    }
    setState(() {
      _file = selectedFile;
      _error = null;
      _status = '${p.basename(selectedFile.path)} is ready to analyze.';
      _result = null;
    });
  }

  Future<void> _analyze() async {
    final file = _file;
    if (file == null) return;
    if (await file.length() > _maxFileBytes) {
      setState(() {
        _error = 'Selected file is larger than 10 MB. Choose a smaller report.';
        _status = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _status = 'Uploading ${p.basename(file.path)} for analysis...';
      _result = null;
    });

    await NotificationService().add(
      title: 'Report analysis started',
      body: '${p.basename(file.path)} is being processed.',
    );

    try {
      final response = await ApiService().uploadReport(file);
      if (!mounted) return;
      if ((response['status_code'] ?? 200) >= 400 ||
          response['prediction'] == null) {
        final message = response['message']?.toString() ?? 'Analysis failed.';
        setState(() {
          _error = message;
          _status = 'Analysis did not complete. You can retry this upload.';
        });
        await NotificationService().add(
          title: 'Report analysis needs attention',
          body: message,
          severity: 'Warning',
        );
        return;
      }

      final result = Map<String, dynamic>.from(response);
      await AnalysisHistoryService().saveLastAnalysis(result);
      if (!mounted) return;
      setState(() => _status = 'Analysis complete. Review the summary below.');
      await NotificationService().add(
        title: 'Report analysis complete',
        body:
            '${result['prediction']} guidance is ready with ${(((result['confidence'] ?? 0) as num).toDouble() * 100).toStringAsFixed(1)}% confidence.',
        severity: result['urgency']?.toString().toLowerCase() == 'high'
            ? 'Critical'
            : 'Healthy',
      );
      if (!mounted) return;
      setState(() => _result = result);
    } on ForbiddenException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _status = 'Analysis stopped.';
      });
    } on AuthException {
      if (!mounted) return;
      setState(() {
        _error = 'Please sign in again to upload reports.';
        _status = 'Your session needs attention.';
      });
    } catch (_) {
      setState(() {
        _error = 'Could not analyze this report right now.';
        _status = 'The report is still selected. You can retry.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = _file == null
        ? 'No file selected yet'
        : p.basename(_file!.path);

    return AppPage(
      bottomNavigationBar: const AppBottomBar(selectedItem: 'Reports'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            eyebrow: 'Reports',
            title: 'Clinical inbox',
            subtitle:
                'Upload a report, review the AI summary, and understand what to do next.',
            trailing: AppIconButton(
              icon: Icons.history_rounded,
              onTap: () => Navigator.pushNamed(context, '/system-log'),
            ),
          ),
          const SizedBox(height: 22),
          const _JourneyStrip(),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppTheme.scrub,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.cloud_upload_rounded,
                        size: 28,
                        color: AppTheme.clinicalGreen,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Step 1: Choose a report',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'PDF, TXT, PNG, JPG, and JPEG are supported. Keep files below 10 MB.',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                InkWell(
                  onTap: _pickFile,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.softSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.description_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            fileName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _file == null || _loading ? null : _analyze,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome_rounded),
                        label: Text(
                          _loading ? 'Analyzing report...' : 'Analyze report',
                        ),
                      ),
                    ),
                  ],
                ),
                if (_status != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _status!,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            AppCard(
              color: AppTheme.alertSoft,
              border: Border.all(color: AppTheme.coral.withValues(alpha: 0.18)),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: AppTheme.coral,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (_file != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _loading ? null : _analyze,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry analysis'),
              ),
            ],
          ],
          if (_result == null) ...[
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'What happens next',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.find_in_page_rounded,
                    title: 'We read the report content',
                    body:
                        'The app extracts text from your report and sends it for analysis.',
                  ),
                  SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.insights_rounded,
                    title: 'You get a confidence-based summary',
                    body:
                        'The result highlights likely findings, urgency, and explainable signals.',
                  ),
                  SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.checklist_rounded,
                    title: 'You see next steps',
                    body:
                        'Use the recommendations to decide whether to monitor, follow up, or seek care.',
                  ),
                ],
              ),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 22),
            _ResultView(result: _result!),
          ],
        ],
      ),
    );
  }
}

class _JourneyStrip extends StatelessWidget {
  const _JourneyStrip();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppTheme.softSurface,
      child: Row(
        children: const [
          Expanded(
            child: _JourneyStep(
              number: '1',
              title: 'Choose file',
              subtitle: 'Select a report',
            ),
          ),
          Expanded(
            child: _JourneyStep(
              number: '2',
              title: 'AI review',
              subtitle: 'Wait for analysis',
            ),
          ),
          Expanded(
            child: _JourneyStep(
              number: '3',
              title: 'Understand',
              subtitle: 'Read next steps',
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyStep extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;

  const _JourneyStep({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white,
          child: Text(
            number,
            style: const TextStyle(
              color: AppTheme.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(
                subtitle,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InfoRow({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppTheme.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(color: AppTheme.textMuted, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  final Map<String, dynamic> result;

  const _ResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    final confidence = ((result['confidence'] ?? 0) as num).toDouble();
    final urgency = result['urgency']?.toString().toLowerCase() ?? 'medium';
    final color = switch (urgency) {
      'high' => AppTheme.coral,
      'low' => AppTheme.aqua,
      _ => AppTheme.amber,
    };
    final recommendations =
        (result['recommendations'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList();
    final precautions = (result['precautions'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList();
    final medicines =
        (result['recommended_medicines'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList();
    final symptoms =
        (result['extracted_symptoms'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList();
    final entities = result['entities'] as Map<String, dynamic>? ?? const {};
    final seekCare = result['seek_care']?.toString() ?? '';
    final trendSummary =
        result['trend_summary'] as Map<String, dynamic>? ?? const {};
    final probabilities =
        (result['probabilities'] as Map<String, dynamic>? ?? const {}).entries
            .map(
              (entry) =>
                  MapEntry(entry.key, (entry.value as num?)?.toDouble() ?? 0),
            )
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Your report summary'),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(Icons.monitor_heart_rounded, color: color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result['prediction']?.toString() ?? 'Unknown',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        AppBadge(
                          text: '${urgency.toUpperCase()} urgency',
                          color: color,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: confidence.clamp(0.0, 1.0).toDouble(),
                  minHeight: 10,
                  backgroundColor: AppTheme.backgroundRaised,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Confidence ${(confidence * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              Text(
                result['explanation']?.toString() ??
                    'The model analyzed the report content.',
                style: const TextStyle(color: AppTheme.textMuted, height: 1.45),
              ),
            ],
          ),
        ),
        if (probabilities.isNotEmpty) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explainable signals',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                ...probabilities.take(4).map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MetricPill(
                      icon: Icons.insights_rounded,
                      label: entry.key,
                      value: '${(entry.value * 100).toStringAsFixed(1)}%',
                      color: AppTheme.blue,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        if (symptoms.isNotEmpty || entities.isNotEmpty) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Extracted details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                if (symptoms.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: symptoms
                        .map(
                          (item) => AppBadge(text: item, color: AppTheme.blue),
                        )
                        .toList(),
                  ),
                if ((entities['lab_values'] as List<dynamic>? ?? const [])
                    .isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Lab markers: ${(entities['lab_values'] as List<dynamic>).join(', ')}',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (recommendations.isNotEmpty) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recommended next steps',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                ...recommendations.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.aqua,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (precautions.isNotEmpty ||
            medicines.isNotEmpty ||
            seekCare.isNotEmpty) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Care guidance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                if (seekCare.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    seekCare,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                    ),
                  ),
                ],
                if (precautions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...precautions.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppTheme.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (medicines.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Medicine notes',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  ...medicines.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (trendSummary.isNotEmpty && trendSummary['message'] != null) ...[
          const SizedBox(height: 16),
          AppCard(
            color: AppTheme.softSurface,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.trending_up_rounded, color: AppTheme.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    trendSummary['message'].toString(),
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
