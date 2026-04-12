import 'package:flutter/material.dart';

class QcPage extends StatelessWidget {
  final String orderId;

  const QcPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Control de Calidad')),
    body: Center(child: Text('QC — Fase 5.7 — Order: $orderId')),
  );
}
