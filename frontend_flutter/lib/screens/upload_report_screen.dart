import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../services/api_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
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
    final confidence = ((analysisResult?["confidence"] ?? 0) as num).toDouble();
    final symptoms =
        (analysisResult?["extracted_symptoms"] as List<dynamic>? ?? [])
            .map((item) => item.toString())
            .toList();
    final explanation = analysisResult?["explanation"]?.toString() ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
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
                      const Text(
                        "Upload Report",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
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
                          "Medical Report Analysis",
                          style: TextStyle(
                            fontSize: 25,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Upload a PDF report and let the AI extract findings, detect symptoms, and estimate the most likely disease category.",
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
                              label: "PDF only",
                            ),
                            _InfoChip(
                              icon: Icons.psychology_alt_outlined,
                              label: "AI summary",
                            ),
                            _InfoChip(
                              icon: Icons.monitor_heart_outlined,
                              label: "Symptom extraction",
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
                          "Choose File",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Use a text-based or OCR-readable medical PDF for the best results.",
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
                                            : "Ready for analysis",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF6B7380),
                                        ),
                                      ),
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
                                : const Text(
                                    "Upload & Analyze",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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
