import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/quotation_models.dart';

class FindingCostEditor extends StatefulWidget {
  const FindingCostEditor({
    super.key,
    required this.finding,
    required this.lineItem,
    required this.onLaborChanged,
    required this.onPartChanged,
  });

  final QuotationFindingModel finding;
  final QuotationLineItem lineItem;
  final void Function(double manoObra) onLaborChanged;
  final void Function(String? partId, double costoRepuesto) onPartChanged;

  @override
  State<FindingCostEditor> createState() => _FindingCostEditorState();
}

class _FindingCostEditorState extends State<FindingCostEditor> {
  bool _expanded = false;
  late final TextEditingController _laborController;
  late final TextEditingController _manualCostController;
  String? _selectedPartId;

  @override
  void initState() {
    super.initState();
    _laborController = TextEditingController(
      text: widget.lineItem.manoObra > 0
          ? widget.lineItem.manoObra.toStringAsFixed(2)
          : '',
    );
    _manualCostController = TextEditingController(
      text: widget.lineItem.costoRepuesto > 0
          ? widget.lineItem.costoRepuesto.toStringAsFixed(2)
          : '',
    );
    _selectedPartId = widget.lineItem.partId;
  }

  @override
  void dispose() {
    _laborController.dispose();
    _manualCostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final finding = widget.finding;
    final lineItem = widget.lineItem;
    final fmt = NumberFormat('#,##0.00');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (finding.esHallazgoAdicional ||
                            finding.esCriticoSeguridad)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Wrap(
                              spacing: 4,
                              children: [
                                if (finding.esHallazgoAdicional)
                                  _BadgeChip(
                                    label: 'Hallazgo adicional',
                                    color: AppColors.accent,
                                  ),
                                if (finding.esCriticoSeguridad)
                                  _BadgeChip(
                                    label: '⚠️ Crítico',
                                    color: Colors.red[700]!,
                                  ),
                              ],
                            ),
                          ),
                        Text(
                          finding.esHallazgoAdicional
                              ? 'Hallazgo adicional'
                              : finding.motivo,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₡ ${fmt.format(lineItem.costoTotal)}',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded content ─────────────────────────────────────────────
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Mano de obra
                  TextFormField(
                    controller: _laborController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Mano de Obra (₡)',
                      prefixText: '₡ ',
                    ),
                    onChanged: (v) {
                      final val = double.tryParse(v) ?? 0.0;
                      widget.onLaborChanged(val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Part selector OR manual cost entry
                  if (finding.parts.isNotEmpty)
                    DropdownButtonFormField<String?>(
                      value: _selectedPartId,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Repuesto'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Sin repuesto'),
                        ),
                        ...finding.parts.map(
                          (part) => DropdownMenuItem<String?>(
                            value: part.id,
                            child: Text(
                              '${part.nombre} — ₡${NumberFormat('#,##0').format(part.precioVenta)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (partId) {
                        setState(() => _selectedPartId = partId);
                        final costo = partId == null
                            ? 0.0
                            : finding.parts
                                .firstWhere((p) => p.id == partId)
                                .precioVenta;
                        widget.onPartChanged(partId, costo);
                      },
                    )
                  else
                    TextFormField(
                      controller: _manualCostController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Costo de Repuesto (₡)',
                        prefixText: '₡ ',
                      ),
                      onChanged: (v) {
                        final val = double.tryParse(v) ?? 0.0;
                        widget.onPartChanged(null, val);
                      },
                    ),

                  const SizedBox(height: 12),

                  // Subtotal row
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Subtotal: ₡ ${fmt.format(lineItem.costoTotal)}',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
