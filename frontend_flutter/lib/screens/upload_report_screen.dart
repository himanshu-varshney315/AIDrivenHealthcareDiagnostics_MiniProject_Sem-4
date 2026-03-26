import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../services/analysis_history_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_bar.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  static const int _maxFileBytes = 10 * 1024 * 1024;
  File? selectedFile;
  bool isLoading = false;
  Map<String, dynamic>? analysisResult;
  String? errorMessage;

  Future pickPDF() async {
    FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (picked != null && picked.files.single.path != null) {
      setState(() {
        selectedFile = File(picked.files.single.path!);
        analysisResult = null;
        errorMessage = null;
      });
    }
  }

  Future uploadReport() async {
    if (selectedFile == null) return;
    final fileSize = await selectedFile!.length();
    if (fileSize > _maxFileBytes) {
      setState(() {
        errorMessage = 'Selected file is larger than 10 MB.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      analysisResult = null;
      errorMessage = null;
    });

    try {
      var response = await ApiService().uploadReport(selectedFile!);

      setState(() {
        if ((response["status_code"] ?? 200) >= 400 ||
            response["prediction"] == null) {
          errorMessage = response["message"]?.toString() ?? "Analysis failed.";
          return;
        }
        analysisResult = Map<String, dynamic>.from(response);
      });
      if (analysisResult != null) {
        await AnalysisHistoryService().saveLastAnalysis(analysisResult!);
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: Could not analyze report.";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = selectedFile == null
        ? null
        : p.basename(selectedFile!.path);
    final fileExtension = fileName == null ? null : p.extension(fileName).toUpperCase();
    final confidence = ((analysisResult?["confidence"] ?? 0) as num).toDouble();
    final symptoms =
        (analysisResult?["extracted_symptoms"] as List<dynamic>? ?? [])
            .map((item) => item.toString())
            .toList();
    final explanation = analysisResult?["explanation"]?.toString() ?? "";
    final urgency = analysisResult?["urgency"]?.toString().toLowerCase() ?? "";
    final recommendations =
        (analysisResult?["recommendations"] as List<dynamic>? ?? [])
            .map((item) => item.toString())
            .toList();
    final precautions = (analysisResult?["precautions"] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();
    final medicines =
        (analysisResult?["recommended_medicines"] as List<dynamic>? ?? [])
            .map((item) => item.toString())
            .toList();
    final seekCare = analysisResult?["seek_care"]?.toString() ?? "";
    final trendSummary =
        analysisResult?["trend_summary"] as Map<String, dynamic>?;
    final probabilityEntries =
        (analysisResult?["probabilities"] as Map<String, dynamic>? ?? const {})
            .entries
            .map(
              (entry) => MapEntry(
                entry.key,
                (entry.value as num?)?.toDouble() ?? 0.0,
              ),
            )
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      bottomNavigationBar: const AppBottomBar(selectedItem: 'Reports'),
      body: Stack(
        children: [
          const _ReportBackdrop(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _RoundIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Reports",
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontSize: 28),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Upload and review AI-ready medical files.",
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEAF7FF), Color(0xFFF5EDFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 20,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            color: Color(0xFF5169D6),
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "Clinical report analysis",
                          style: TextStyle(fontSize: 25, height: 1.1, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Turn a report into a structured summary with symptoms, urgency, and next-step guidance.",
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.35,
                            color: Colors.black.withValues(alpha: 0.68),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: const [
                            _InfoChip(
                              icon: Icons.picture_as_pdf_outlined,
                              label: "PDF reports",
                            ),
                            _InfoChip(
                              icon: Icons.psychology_alt_outlined,
                              label: "AI summary",
                            ),
                            _InfoChip(
                              icon: Icons.monitor_heart_outlined,
                              label: "Urgency flag",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Choose file",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Use a readable medical PDF. Files up to 10 MB are supported.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF667083),
                          ),
                        ),
                        const SizedBox(height: 18),
                        InkWell(
                          onTap: pickPDF,
                          borderRadius: BorderRadius.circular(24),
                          child: Ink(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F9FD),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFD9E1F2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEEF0),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.upload_file_rounded,
                                    color: Color(0xFFE56E7A),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fileName ?? "Select PDF Report",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        fileName == null
                                            ? "Tap to browse from device storage"
                                            : "Ready to analyze",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF6B7380),
                                        ),
                                      ),
                                      if (fileExtension != null) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF4FF),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            fileExtension.replaceFirst('.', ''),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.blue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFF7C8390),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: selectedFile == null || isLoading
                                ? null
                                : uploadReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF243148),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              disabledBackgroundColor: const Color(0xFFB8C0D0),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text("Analyze report", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9FD),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lock_outline_rounded,
                                color: AppTheme.navy,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Reports are analyzed securely and your latest result stays available in the dashboard.",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (analysisResult != null) ...[
                    const SizedBox(height: 16),
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Analysis Result",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _MetricTile(
                                  icon: Icons.biotech_outlined,
                                  title: "Prediction",
                                  value:
                                      analysisResult?["prediction"]
                                          ?.toString() ??
                                      "-",
                                  accentColor: const Color(0xFF5C86F3),
                                  backgroundColor: const Color(0xFFEFF4FF),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _MetricTile(
                                  icon: Icons.verified_outlined,
                                  title: "Confidence",
                                  value:
                                      "${(confidence * 100).toStringAsFixed(1)}%",
                                  accentColor: const Color(0xFF9B6AE4),
                                  backgroundColor: const Color(0xFFF4EEFF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _RiskBanner(urgency: urgency, confidence: confidence),
                          const SizedBox(height: 16),
                          _ResultBlock(
                            title: "Detected Symptoms",
                            icon: Icons.monitor_heart_outlined,
                            child: symptoms.isEmpty
                                ? const Text(
                                    "No symptoms were extracted from this report.",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF626B78),
                                    ),
                                  )
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: symptoms
                                        .map(
                                          (symptom) =>
                                              _SymptomChip(label: symptom),
                                        )
                                        .toList(),
                                  ),
                          ),
                          const SizedBox(height: 14),
                          _ResultBlock(
                            title: "Explanation",
                            icon: Icons.auto_awesome_outlined,
                            child: Text(
                              explanation,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.45,
                                color: Color(0xFF4F5664),
                              ),
                            ),
                          ),
                          if (probabilityEntries.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _ResultBlock(
                              title: "Explainable AI View",
                              icon: Icons.insights_outlined,
                              child: Column(
                                children: probabilityEntries
                                    .take(4)
                                    .map(
                                      (entry) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _ProbabilityRow(
                                          label: entry.key,
                                          value: entry.value,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                          if (trendSummary != null) ...[
                            const SizedBox(height: 14),
                            _ResultBlock(
                              title: "Trend Summary",
                              icon: Icons.timeline_rounded,
                              child: _TrendSummaryCard(
                                trendSummary: trendSummary,
                              ),
                            ),
                          ],
                          if (recommendations.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _ResultBlock(
                              title: "Recommendations",
                              icon: Icons.fact_check_outlined,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: recommendations
                                    .map(
                                      (item) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: _AdviceRow(text: item),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                          if (medicines.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _ResultBlock(
                              title: "Medication Guidance",
                              icon: Icons.medication_outlined,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: medicines
                                    .map(
                                      (item) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: _AdviceRow(text: item),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                          if (precautions.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _ResultBlock(
                              title: "Precautions",
                              icon: Icons.health_and_safety_outlined,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: precautions
                                    .map(
                                      (item) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: _AdviceRow(text: item),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                          if (seekCare.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _ResultBlock(
                              title: "When To Seek Care",
                              icon: Icons.local_hospital_outlined,
                              child: Text(
                                seekCare,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.45,
                                  color: Color(0xFF4F5664),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _ErrorCard(message: errorMessage!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportBackdrop extends StatelessWidget {
  const _ReportBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEAF6FF), Color(0xFFF6F0FF), Color(0xFFF8FAFD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        const Positioned(
          top: -30,
          right: -10,
          child: _GlowBubble(size: 170, color: Color(0x80DDD4FF)),
        ),
        const Positioned(
          top: 120,
          left: -30,
          child: _GlowBubble(size: 130, color: Color(0x809CE6FF)),
        ),
        const Positioned(
          bottom: 80,
          right: -20,
          child: _GlowBubble(size: 150, color: Color(0x80FFE3C6)),
        ),
      ],
    );
  }
}

class _GlowBubble extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBubble({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0.0)],
          ),
        ),
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
      color: Colors.white.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(width: 52, height: 52, child: Icon(icon, size: 20)),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF5267D4)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color accentColor;
  final Color backgroundColor;

  const _MetricTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.accentColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: Color(0xFF646B78)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _RiskBanner extends StatelessWidget {
  final String urgency;
  final double confidence;

  const _RiskBanner({required this.urgency, required this.confidence});

  @override
  Widget build(BuildContext context) {
    final color = switch (urgency) {
      'high' => const Color(0xFFE46B78),
      'low' => const Color(0xFF44A775),
      _ => const Color(0xFFF0A247),
    };
    final label = urgency.isEmpty
        ? 'Analysis ready'
        : '${urgency[0].toUpperCase()}${urgency.substring(1)} urgency';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: confidence.clamp(0, 1),
              minHeight: 10,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _ResultBlock({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF5E84ED)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SymptomChip extends StatelessWidget {
  final String label;

  const _SymptomChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF456ACF),
        ),
      ),
    );
  }
}

class _AdviceRow extends StatelessWidget {
  final String text;

  const _AdviceRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: Icon(Icons.circle, size: 8, color: Color(0xFF5E84ED)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.35,
              color: Color(0xFF4F5664),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProbabilityRow extends StatelessWidget {
  final String label;
  final double value;

  const _ProbabilityRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final percent = (value.clamp(0, 1) * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5D6674),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 9,
            backgroundColor: const Color(0xFFE7ECF5),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5E84ED)),
          ),
        ),
      ],
    );
  }
}

class _TrendSummaryCard extends StatelessWidget {
  final Map<String, dynamic> trendSummary;

  const _TrendSummaryCard({required this.trendSummary});

  @override
  Widget build(BuildContext context) {
    final direction = (trendSummary["direction"]?.toString() ?? "stable")
        .toLowerCase();
    final averageConfidence =
        ((trendSummary["average_confidence"] ?? 0) as num).toDouble();
    final highUrgencyCount =
        ((trendSummary["high_urgency_count"] ?? 0) as num).toInt();
    final badgeColor = switch (direction) {
      "improving" => const Color(0xFF44A775),
      "worsening" => const Color(0xFFE46B78),
      "changed" => const Color(0xFF5E84ED),
      _ => const Color(0xFFF0A247),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                direction.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: badgeColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Avg confidence ${(averageConfidence * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5D6674),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          trendSummary["message"]?.toString() ??
              "Keep uploading reports to unlock stronger comparisons over time.",
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Color(0xFF4F5664),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$highUrgencyCount recent high-urgency analyses detected.',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF677182),
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEF0),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFE46B78),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF6B4850),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
