import 'package:flutter/material.dart';

class BillingPage extends StatelessWidget {
  final String orderId;

  const BillingPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Facturación')),
    body: Center(child: Text('Facturación — Fase 5.8 — Order: $orderId')),
  );
}
