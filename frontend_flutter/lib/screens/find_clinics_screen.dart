import 'package:flutter/material.dart';

import 'clinics_screen.dart';

class FindClinicsScreen extends StatefulWidget {
  const FindClinicsScreen({super.key});

  @override
  State<FindClinicsScreen> createState() => _FindClinicsScreenState();
}

class _FindClinicsScreenState extends State<FindClinicsScreen> {
  @override
  Widget build(BuildContext context) {
    return const ClinicsScreen();
  }
}
