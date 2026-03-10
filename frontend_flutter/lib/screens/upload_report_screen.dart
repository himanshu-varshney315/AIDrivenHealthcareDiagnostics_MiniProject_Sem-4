import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  File? selectedFile;
  String result = "";
  bool isLoading = false;

  Future pickPDF() async {
    FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (picked != null && picked.files.single.path != null) {
      setState(() {
        selectedFile = File(picked.files.single.path!);
      });
    }
  }

  Future uploadReport() async {
    if (selectedFile == null) return;

    setState(() {
      isLoading = true;
      result = ""; // Clear previous results
    });

    try {
      // NOTE: If your ApiService requires an instance, change to:
      var response = await ApiService().uploadReport(selectedFile!);
     // var response = await ApiService.uploadReport(selectedFile!);

      setState(() {
        result = "Prediction: ${response["prediction"]}\n"
            "Risk: ${response["risk_percentage"]}%";
      });
    } catch (e) {
      setState(() {
        result = "Error: Could not analyze report.";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Medical Report"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickPDF,
              child: const Text("Select PDF Report"),
            ),
            const SizedBox(height: 20),
            if (selectedFile != null)
              Text(selectedFile!.uri.pathSegments.last,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: selectedFile == null ? null : uploadReport,
              child: const Text("Upload & Analyze"),
            ),
            const SizedBox(height: 30),
            if (isLoading) const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              result,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
