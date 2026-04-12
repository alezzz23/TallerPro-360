import 'package:flutter/material.dart';

class DiagnosisPage extends StatelessWidget {
  final String orderId;

  const DiagnosisPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Diagnóstico')),
    body: Center(child: Text('Diagnóstico — Fase 5.5 — Order: $orderId')),
  );
}
