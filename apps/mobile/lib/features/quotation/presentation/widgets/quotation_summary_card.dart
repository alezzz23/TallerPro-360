import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class QuotationSummaryCard extends StatelessWidget {
  const QuotationSummaryCard({
    super.key,
    required this.subtotal,
    required this.shopSupplies,
    required this.impuestos,
    required this.descuento,
    required this.total,
  });

  final double subtotal;
  final double shopSupplies;
  final double impuestos;
  final double descuento;
  final double total;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SummaryRow(
              label: 'Subtotal',
              value: '₡ ${fmt.format(subtotal)}',
            ),
            _SummaryRow(
              label: 'Shop Supplies',
              value: '₡ ${fmt.format(shopSupplies)}',
            ),
            _SummaryRow(
              label: 'IVA (16%)',
              value: '₡ ${fmt.format(impuestos)}',
            ),
            if (descuento > 0)
              _SummaryRow(
                label: 'Descuento',
                value: '-₡ ${fmt.format(descuento)}',
                valueStyle: TextStyle(color: Colors.red[700]),
              ),
            const Divider(height: 16),
            _SummaryRow(
              label: 'TOTAL',
              value: '₡ ${fmt.format(total)}',
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              valueStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
