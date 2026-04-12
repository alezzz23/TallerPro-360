import 'package:flutter/material.dart';

import '../../domain/qc_models.dart';

final _fluidOptions = QcFluidLevel.values
    .map((l) => DropdownMenuItem<String>(value: l.value, child: Text(l.label)))
    .toList();

class FluidComparisonRow extends StatelessWidget {
  const FluidComparisonRow({
    super.key,
    required this.label,
    this.ingressValue,
    this.exitValue,
    this.onChanged,
    this.readOnly = false,
  });

  final String label;
  final String? ingressValue;
  final String? exitValue;
  final ValueChanged<String?>? onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
          ),
          Expanded(
            flex: 3,
            child: _FluidChip(value: ingressValue, prefix: 'Ingreso'),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: readOnly
                ? _FluidChip(value: exitValue, prefix: 'Salida')
                : _FluidDropdown(
                    value: exitValue,
                    onChanged: onChanged,
                  ),
          ),
        ],
      ),
    );
  }
}

class _FluidChip extends StatelessWidget {
  const _FluidChip({this.value, required this.prefix});

  final String? value;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final color = _fluidColor(value);
    final displayLabel = value != null
        ? (QcFluidLevel.fromString(value)?.label ?? value!)
        : '—';

    return Chip(
      label: Text(
        '$prefix: $displayLabel',
        style: const TextStyle(fontSize: 11, color: Colors.white),
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _FluidDropdown extends StatelessWidget {
  const _FluidDropdown({this.value, this.onChanged});

  final String? value;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Salida',
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
      ),
      items: _fluidOptions,
      onChanged: onChanged,
    );
  }
}

Color _fluidColor(String? level) {
  switch (level) {
    case 'correcto':
      return Colors.green;
    case 'bajo':
      return Colors.amber.shade700;
    case 'critico':
      return Colors.red;
    default:
      return Colors.grey;
  }
}
