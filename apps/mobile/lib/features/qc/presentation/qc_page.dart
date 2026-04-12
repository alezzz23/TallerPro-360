import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_state.dart';
import '../application/qc_controller.dart';
import '../application/qc_providers.dart';
import '../domain/qc_models.dart';
import '../domain/qc_state.dart';
import 'widgets/fluid_comparison_row.dart';

class QcPage extends ConsumerStatefulWidget {
  const QcPage({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<QcPage> createState() => _QcPageState();
}

class _QcPageState extends ConsumerState<QcPage> {
  final _kmController = TextEditingController();
  bool _kmSyncedFromState = false;

  @override
  void dispose() {
    _kmController.dispose();
    super.dispose();
  }

  QcController get _controller =>
      ref.read(qcControllerProvider(widget.orderId).notifier);

  String get _shortId =>
      widget.orderId.length >= 8 ? widget.orderId.substring(0, 8) : widget.orderId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qcControllerProvider(widget.orderId));
    final authState = ref.watch(authStateProvider);
    final rol = authState.rol;
    final isManager = rol == 'JEFE_TALLER' || rol == 'ADMIN';
    final isApproved = state.savedQc?.aprobado == true;

    // Sync km field from state once (handles pre-fill from existing QC).
    if (!_kmSyncedFromState && !state.isLoading) {
      _kmSyncedFromState = true;
      final km = state.kilometrajeSalida;
      _kmController.text = km != null ? km.toString() : '';
    }

    // Show errors and approval snackbar.
    ref.listen(qcControllerProvider(widget.orderId), (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      if (previous?.savedQc?.aprobado == false &&
          next.savedQc?.aprobado == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QC aprobado. Vehículo pasa a ENTREGA.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Control de Calidad — Orden #$_shortId'),
        actions: [
          if (state.isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save_outlined),
              tooltip: 'Guardar borrador',
              onPressed: isApproved ? null : () => _saveDraft(authState),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ComparisonSection(
                  state: state,
                  kmController: _kmController,
                  readOnly: isApproved,
                  onKmChanged: (val) {
                    final parsed = int.tryParse(val);
                    _controller.setKmSalida(parsed);
                  },
                  onAceiteChanged:
                      isApproved ? null : _controller.setNivelAceite,
                  onRefrigeranteChanged:
                      isApproved ? null : _controller.setNivelRefrigerante,
                  onFrenosChanged:
                      isApproved ? null : _controller.setNivelFrenos,
                ),
                const SizedBox(height: 16),
                _ChecklistSection(
                  state: state,
                  readOnly: isApproved,
                  onToggle: isApproved ? null : _controller.toggleItem,
                ),
                const SizedBox(height: 16),
                _FluidExitSection(
                  state: state,
                  readOnly: isApproved,
                  onAceiteChanged:
                      isApproved ? null : _controller.setNivelAceite,
                  onRefrigeranteChanged:
                      isApproved ? null : _controller.setNivelRefrigerante,
                  onFrenosChanged:
                      isApproved ? null : _controller.setNivelFrenos,
                ),
                const SizedBox(height: 24),
              ],
            ),
      bottomNavigationBar:
          isManager ? _ApproveBar(state: state, onApprove: _approve) : null,
    );
  }

  Future<void> _saveDraft(AuthState authState) async {
    final userId = authState.userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se pudo identificar al inspector.')),
      );
      return;
    }
    await _controller.saveProgress(userId);
  }

  Future<void> _approve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar aprobación'),
        content: const Text(
            '¿Confirmar aprobación? El vehículo pasará a ENTREGA.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _controller.approveQc();
    }
  }
}

// ─── Comparison Section ───────────────────────────────────────────────────────

class _ComparisonSection extends StatelessWidget {
  const _ComparisonSection({
    required this.state,
    required this.kmController,
    required this.readOnly,
    required this.onKmChanged,
    required this.onAceiteChanged,
    required this.onRefrigeranteChanged,
    required this.onFrenosChanged,
  });

  final QcState state;
  final TextEditingController kmController;
  final bool readOnly;
  final ValueChanged<String> onKmChanged;
  final ValueChanged<String?>? onAceiteChanged;
  final ValueChanged<String?>? onRefrigeranteChanged;
  final ValueChanged<String?>? onFrenosChanged;

  @override
  Widget build(BuildContext context) {
    final snapshot = state.snapshot;
    final kmDelta = state.savedQc?.kmDelta;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Kilometraje card ─────────────────────────────────────────────

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kilometraje',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ingreso',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            snapshot?.kmIngreso != null
                                ? '${snapshot!.kmIngreso} km'
                                : '—',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: kmController,
                        readOnly: readOnly,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Salida (km)',
                          suffixText: 'km',
                        ),
                        onChanged: onKmChanged,
                      ),
                    ),
                  ],
                ),
                if (kmDelta != null) ...[
                  const SizedBox(height: 8),
                  _KmDeltaBadge(delta: kmDelta),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Fluidos comparison card ──────────────────────────────────────

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fluidos — Comparación',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                FluidComparisonRow(
                  label: 'Aceite',
                  ingressValue: snapshot?.nivelAceiteIngreso,
                  exitValue: state.nivelAceiteSalida,
                  onChanged: onAceiteChanged,
                  readOnly: readOnly,
                ),
                FluidComparisonRow(
                  label: 'Refrigerante',
                  ingressValue: snapshot?.nivelRefrigeranteIngreso,
                  exitValue: state.nivelRefrigeranteSalida,
                  onChanged: onRefrigeranteChanged,
                  readOnly: readOnly,
                ),
                FluidComparisonRow(
                  label: 'Frenos',
                  ingressValue: snapshot?.nivelFrenosIngreso,
                  exitValue: state.nivelFrenosSalida,
                  onChanged: onFrenosChanged,
                  readOnly: readOnly,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _KmDeltaBadge extends StatelessWidget {
  const _KmDeltaBadge({required this.delta});

  final int delta;

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (delta <= 50) {
      color = Colors.green;
    } else if (delta <= 200) {
      color = Colors.amber.shade700;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Delta: +$delta km',
        style: TextStyle(
            color: color, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}

// ─── Checklist Section ────────────────────────────────────────────────────────

class _ChecklistSection extends StatelessWidget {
  const _ChecklistSection({
    required this.state,
    required this.readOnly,
    required this.onToggle,
  });

  final QcState state;
  final bool readOnly;
  final void Function(String itemId)? onToggle;

  @override
  Widget build(BuildContext context) {
    final items = state.checklistItems;
    final checkedCount = items.where((i) => i.checked).length;
    final total = items.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ítems Verificados (aprobados por cliente)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (total > 0)
                  Text(
                    '$checkedCount / $total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'Sin ítems de cotización aprobada.\nAgrega ítems manualmente.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ),
              )
            else ...[
              ...items.map(
                (item) => CheckboxListTile(
                  value: item.checked,
                  title: Text(item.descripcion),
                  contentPadding: EdgeInsets.zero,
                  onChanged:
                      readOnly ? null : (_) => onToggle?.call(item.id),
                ),
              ),
              if (state.allItemsChecked && total > 0) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green.shade700, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Todos los ítems verificados',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Fluid Exit Section ───────────────────────────────────────────────────────

class _FluidExitSection extends StatelessWidget {
  const _FluidExitSection({
    required this.state,
    required this.readOnly,
    required this.onAceiteChanged,
    required this.onRefrigeranteChanged,
    required this.onFrenosChanged,
  });

  final QcState state;
  final bool readOnly;
  final ValueChanged<String?>? onAceiteChanged;
  final ValueChanged<String?>? onRefrigeranteChanged;
  final ValueChanged<String?>? onFrenosChanged;

  static final _options = QcFluidLevel.values
      .map((l) =>
          DropdownMenuItem<String>(value: l.value, child: Text(l.label)))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Niveles de Salida',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _FluidDropdownField(
              label: 'Aceite de Motor (salida)',
              value: state.nivelAceiteSalida,
              options: _options,
              onChanged: readOnly ? null : onAceiteChanged,
            ),
            const SizedBox(height: 12),
            _FluidDropdownField(
              label: 'Refrigerante (salida)',
              value: state.nivelRefrigeranteSalida,
              options: _options,
              onChanged: readOnly ? null : onRefrigeranteChanged,
            ),
            const SizedBox(height: 12),
            _FluidDropdownField(
              label: 'Frenos (salida)',
              value: state.nivelFrenosSalida,
              options: _options,
              onChanged: readOnly ? null : onFrenosChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _FluidDropdownField extends StatelessWidget {
  const _FluidDropdownField({
    required this.label,
    this.value,
    required this.options,
    this.onChanged,
  });

  final String label;
  final String? value;
  final List<DropdownMenuItem<String>> options;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: options,
      onChanged: onChanged,
    );
  }
}

// ─── Approve Bar ──────────────────────────────────────────────────────────────

class _ApproveBar extends StatelessWidget {
  const _ApproveBar({required this.state, required this.onApprove});

  final QcState state;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    final isApproved = state.savedQc?.aprobado == true;

    if (isApproved) {
      return SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.green.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                '✓ QC Aprobado — Vehículo listo para entrega',
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final canApprove = state.allItemsChecked &&
        state.kilometrajeSalida != null &&
        !state.isSaving;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: canApprove ? onApprove : null,
            child: const Text('Aprobar Control de Calidad'),
          ),
        ),
      ),
    );
  }
}
