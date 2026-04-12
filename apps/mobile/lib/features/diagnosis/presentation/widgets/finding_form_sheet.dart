import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/diagnosis_models.dart';

/// Bottom sheet for creating a new finding or editing an existing one.
///
/// Returns `true` on success, `false`/`null` otherwise.
class FindingFormSheet extends StatefulWidget {
  const FindingFormSheet({
    super.key,
    this.finding,
    required this.isSaving,
    required this.onCreate,
    required this.onEdit,
    required this.onAddPart,
  });

  /// If null → CREATE mode. If set → EDIT mode.
  final DiagnosisFinding? finding;
  final bool isSaving;

  final Future<bool> Function({
    required String motivoIngreso,
    String? descripcion,
    double? tiempoEstimado,
    bool esHallazgoAdicional,
    bool esCriticoSeguridad,
  }) onCreate;

  final Future<bool> Function({
    String? descripcion,
    double? tiempoEstimado,
    bool? esCriticoSeguridad,
  }) onEdit;

  final Future<bool> Function({
    required String nombre,
    required String origen,
    required double costo,
    required double margen,
    String? proveedor,
  }) onAddPart;

  @override
  State<FindingFormSheet> createState() => _FindingFormSheetState();
}

class _FindingFormSheetState extends State<FindingFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _motivoCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _tiempoCtrl;
  bool _esCritico = false;
  bool _esAdicional = false;

  // Part form state
  bool _showPartForm = false;
  final _partNombreCtrl = TextEditingController();
  final _partCostoCtrl = TextEditingController();
  final _partMargenCtrl = TextEditingController();
  final _partProveedorCtrl = TextEditingController();
  String _partOrigen = 'STOCK';
  double _precioVentaPreview = 0.0;

  bool get _isEditMode => widget.finding != null;

  @override
  void initState() {
    super.initState();
    final f = widget.finding;
    _motivoCtrl = TextEditingController(text: f?.motivoIngreso ?? '');
    _descripcionCtrl = TextEditingController(text: f?.descripcion ?? '');
    _tiempoCtrl = TextEditingController(
        text: f?.tiempoEstimado != null
            ? f!.tiempoEstimado!.toStringAsFixed(1)
            : '');
    _esCritico = f?.esCriticoSeguridad ?? false;
    _esAdicional = f?.esHallazgoAdicional ?? false;

    _partCostoCtrl.addListener(_updatePrecioVenta);
    _partMargenCtrl.addListener(_updatePrecioVenta);
  }

  @override
  void dispose() {
    _motivoCtrl.dispose();
    _descripcionCtrl.dispose();
    _tiempoCtrl.dispose();
    _partNombreCtrl.dispose();
    _partCostoCtrl.dispose();
    _partMargenCtrl.dispose();
    _partProveedorCtrl.dispose();
    super.dispose();
  }

  void _updatePrecioVenta() {
    final costo = double.tryParse(_partCostoCtrl.text) ?? 0.0;
    final margenPct = double.tryParse(_partMargenCtrl.text) ?? 0.0;
    final margen = margenPct / 100.0;
    setState(() {
      _precioVentaPreview = DiagnosisPart.computePrecioVenta(costo, margen);
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final descripcion = _descripcionCtrl.text.trim().isEmpty
        ? null
        : _descripcionCtrl.text.trim();
    final tiempoEstimado =
        double.tryParse(_tiempoCtrl.text.trim().replaceAll(',', '.'));

    bool success;
    if (_isEditMode) {
      success = await widget.onEdit(
        descripcion: descripcion,
        tiempoEstimado: tiempoEstimado,
        esCriticoSeguridad: _esCritico,
      );
    } else {
      success = await widget.onCreate(
        motivoIngreso: _motivoCtrl.text.trim(),
        descripcion: descripcion,
        tiempoEstimado: tiempoEstimado,
        esHallazgoAdicional: _esAdicional,
        esCriticoSeguridad: _esCritico,
      );
    }

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _submitPart() async {
    final nombre = _partNombreCtrl.text.trim();
    final costoText = _partCostoCtrl.text.trim().replaceAll(',', '.');
    final margenText = _partMargenCtrl.text.trim().replaceAll(',', '.');
    final costo = double.tryParse(costoText);
    final margenPct = double.tryParse(margenText);

    if (nombre.isEmpty || costo == null || margenPct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Completa nombre, costo y margen del repuesto.')),
      );
      return;
    }
    if (margenPct < 0 || margenPct >= 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El margen debe estar entre 0 y 99 %.')),
      );
      return;
    }

    final success = await widget.onAddPart(
      nombre: nombre,
      origen: _partOrigen,
      costo: costo,
      margen: margenPct / 100.0,
      proveedor: _partProveedorCtrl.text.trim().isEmpty
          ? null
          : _partProveedorCtrl.text.trim(),
    );

    if (success && mounted) {
      setState(() {
        _showPartForm = false;
        _partNombreCtrl.clear();
        _partCostoCtrl.clear();
        _partMargenCtrl.clear();
        _partProveedorCtrl.clear();
        _partOrigen = 'STOCK';
        _precioVentaPreview = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollCtrl) {
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                _SheetHandle(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Text(
                    _isEditMode
                        ? 'Editar Hallazgo'
                        : 'Reportar Hallazgo Adicional',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Motivo (read-only in edit mode)
                          if (!_isEditMode) ...[
                            TextFormField(
                              controller: _motivoCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Motivo de ingreso *',
                                hintText: 'Ej. Ruido al frenar',
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Requerido'
                                  : null,
                              textCapitalization:
                                  TextCapitalization.sentences,
                            ),
                            const SizedBox(height: 12),
                          ] else ...[
                            _ReadOnlyField(
                              label: 'Motivo de ingreso',
                              value: widget.finding!.motivoIngreso,
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Descripción
                          TextFormField(
                            controller: _descripcionCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Descripción del hallazgo',
                              hintText: 'Detalle técnico del problema...',
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                          const SizedBox(height: 12),

                          // Tiempo estimado
                          TextFormField(
                            controller: _tiempoCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Tiempo estimado (horas)',
                              hintText: '0.0',
                              suffixText: 'h',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d.,]')),
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final parsed = double.tryParse(
                                  v.trim().replaceAll(',', '.'));
                              if (parsed == null || parsed < 0) {
                                return 'Valor inválido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Crítico de seguridad
                          SwitchListTile.adaptive(
                            value: _esCritico,
                            onChanged: (v) => setState(() => _esCritico = v),
                            title: const Text('Crítico de seguridad'),
                            subtitle: const Text(
                                'Activa alerta de advertencia en el hallazgo'),
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppColors.statusRejected,
                          ),

                          if (!_isEditMode)
                            SwitchListTile.adaptive(
                              value: _esAdicional,
                              onChanged: (v) =>
                                  setState(() => _esAdicional = v),
                              title: const Text('Hallazgo adicional'),
                              subtitle: const Text(
                                  'No incluido en motivos originales'),
                              contentPadding: EdgeInsets.zero,
                              activeColor: AppColors.accent,
                            ),

                          // Parts section (only in edit mode)
                          if (_isEditMode) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Repuestos',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary),
                                ),
                                TextButton.icon(
                                  onPressed: () => setState(
                                      () => _showPartForm = !_showPartForm),
                                  icon: Icon(_showPartForm
                                      ? Icons.remove
                                      : Icons.add),
                                  label: const Text('Agregar Repuesto'),
                                ),
                              ],
                            ),
                            // Parts list
                            ...widget.finding!.parts.map(
                              (part) => _PartSummaryRow(part: part),
                            ),
                            if (_showPartForm) _buildPartForm(),
                          ],

                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: widget.isSaving ? null : _submit,
                            child: widget.isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(_isEditMode ? 'Guardar cambios' : 'Crear hallazgo'),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPartForm() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _partNombreCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre del repuesto *',
              hintText: 'Ej. Pastillas de freno',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _partOrigen,
            decoration: const InputDecoration(labelText: 'Origen'),
            items: const [
              DropdownMenuItem(value: 'STOCK', child: Text('STOCK')),
              DropdownMenuItem(value: 'PEDIDO', child: Text('PEDIDO')),
            ],
            onChanged: (v) => setState(() => _partOrigen = v ?? 'STOCK'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _partCostoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Costo *',
                    prefixText: '\$ ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _partMargenCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Margen *',
                    suffixText: '%',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Precio venta: \$${_precioVentaPreview.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _partProveedorCtrl,
            decoration: const InputDecoration(
              labelText: 'Proveedor (opcional)',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: widget.isSaving ? null : _submitPart,
            child: widget.isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Agregar repuesto'),
          ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _PartSummaryRow extends StatelessWidget {
  const _PartSummaryRow({required this.part});

  final DiagnosisPart part;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.build_outlined, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(part.nombre,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis),
          ),
          Text(
            '\$${part.precioVenta.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
          ),
        ],
      ),
    );
  }
}
