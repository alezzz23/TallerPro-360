import 'package:flutter/material.dart';

class QuotationPage extends StatelessWidget {
  final String orderId;

  const QuotationPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cotización')),
    body: Center(child: Text('Cotización — Fase 5.6 — Order: $orderId')),
  );
}
