import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/domain/auth_state.dart';
import '../application/quotation_controller.dart';
import '../application/quotation_providers.dart';
import '../domain/quotation_models.dart';
import '../domain/quotation_state.dart';
import 'widgets/finding_cost_editor.dart';
import 'widgets/quotation_item_row.dart';
import 'widgets/quotation_summary_card.dart';

class QuotationPage extends ConsumerStatefulWidget {
  const QuotationPage({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<QuotationPage> createState() => _QuotationPageState();
}

class _QuotationPageState extends ConsumerState<QuotationPage> {
  final _scrollController = ScrollController();

  String get _shortId => widget.orderId.length >= 8
      ? widget.orderId.substring(0, 8)
      : widget.orderId;

  bool _canAct(String? rol) =>
      rol == 'ASESOR' || rol == 'JEFE_TALLER' || rol == 'ADMIN';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quotationControllerProvider(widget.orderId));
    final notifier =
        ref.read(quotationControllerProvider(widget.orderId).notifier);
    final authState = ref.watch(authStateProvider);
    final canAct = _canAct(authState.rol);

    // Show action errors as snackbars.
    ref.listen<QuotationState>(
      quotationControllerProvider(widget.orderId),
      (prev, next) {
        if (next.errorMessage != null &&
            next.errorMessage != prev?.errorMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.errorMessage!)),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Cotización — Orden #$_shortId'),
      ),
      body: _buildBody(state, notifier, canAct),
      bottomNavigationBar: _buildActionBar(state, notifier, canAct),
    );
  }

  // ─── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody(
    QuotationState state,
    QuotationController notifier,
    bool canAct,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.findings.isEmpty &&
        state.quotation == null &&
        state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: notifier.reload,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!canAct) const _ReadOnlyBanner(),
          if (state.quotation == null)
            _BuilderView(
              state: state,
              notifier: notifier,
            )
          else
            _QuotationDetailView(
              quotation: state.quotation!,
              safetyLog: state.safetyLog,
            ),
        ],
      ),
    );
  }

  // ─── Bottom action bar ────────────────────────────────────────────────────

  Widget? _buildActionBar(
    QuotationState state,
    QuotationController notifier,
    bool canAct,
  ) {
    if (!canAct || state.isLoading) return null;

    final quotation = state.quotation;
    if (quotation == null) return null;

    switch (quotation.estado) {
      case QuotationEstado.pendiente:
        if (quotation.fechaEnvio == null) {
          return _ActionBarContainer(
            child: FilledButton(
              onPressed:
                  state.isSaving ? null : notifier.sendQuotation,
              child: state.isSaving
                  ? const _SpinnerButton()
                  : const Text('Enviar Cotización'),
            ),
          );
        } else {
          return _ActionBarContainer(
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.green[700]),
                    onPressed: state.isSaving
                        ? null
                        : () => _confirmApprove(notifier),
                    child: state.isSaving
                        ? const _SpinnerButton()
                        : const Text('Aprobar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      side: BorderSide(color: Colors.red[700]!),
                    ),
                    onPressed: state.isSaving
                        ? null
                        : () => _showRejectDialog(notifier),
                    child: const Text('Rechazar'),
                  ),
                ),
              ],
            ),
          );
        }

      case QuotationEstado.rechazada:
        return _ActionBarContainer(
          child: FilledButton(
            onPressed: state.isSaving
                ? null
                : () => _showDiscountDialog(notifier),
            child: state.isSaving
                ? const _SpinnerButton()
                : const Text('Aplicar Descuento y Reenviar'),
          ),
        );

      case QuotationEstado.aprobada:
        return Container(
          color: Colors.green[50],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green[700]),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Cotización Aprobada — Orden en Reparación',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────

  Future<void> _confirmApprove(QuotationController notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aprobar Cotización'),
        content: const Text(
            '¿Confirmar aprobación? La orden pasará a Reparación.'),
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
    if (confirmed != true || !mounted) return;
    await notifier.approveQuotation();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cotización aprobada — Orden pasa a Reparación'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _showRejectDialog(QuotationController notifier) async {
    final razonController = TextEditingController();
    String? razon;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar Cotización'),
        content: TextFormField(
          controller: razonController,
          decoration:
              const InputDecoration(labelText: 'Razón (opcional)'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () {
              final text = razonController.text.trim();
              razon = text.isEmpty ? null : text;
              Navigator.pop(ctx);
            },
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    razonController.dispose();

    if (!mounted) return;
    await notifier.rejectQuotation(razon: razon);
    if (!mounted) return;

    final safetyLog =
        ref.read(quotationControllerProvider(widget.orderId)).safetyLog;
    if (safetyLog != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('⚠️ Advertencia de seguridad crítica: $safetyLog'),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  Future<void> _showDiscountDialog(QuotationController notifier) async {
    final amountController = TextEditingController();
    double? amount;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aplicar Descuento'),
        content: TextFormField(
          controller: amountController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Descuento (₡)',
            prefixText: '₡ ',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              amount = double.tryParse(amountController.text);
              Navigator.pop(ctx);
            },
            child: const Text('Aplicar y Reenviar'),
          ),
        ],
      ),
    );
    amountController.dispose();

    if (!mounted || amount == null) return;
    await notifier.applyDiscountAndResend(amount!);
  }
}

// ─── Private widgets ──────────────────────────────────────────────────────────

class _ReadOnlyBanner extends StatelessWidget {
  const _ReadOnlyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.visibility, size: 16, color: Colors.grey),
          SizedBox(width: 8),
          Text('Solo lectura', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _BuilderView extends StatelessWidget {
  const _BuilderView({
    required this.state,
    required this.notifier,
  });

  final QuotationState state;
  final QuotationController notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Hallazgos del Diagnóstico',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...state.findings.map((finding) {
          final lineItem = state.lineItems[finding.id];
          if (lineItem == null) return const SizedBox.shrink();
          return FindingCostEditor(
            finding: finding,
            lineItem: lineItem,
            onLaborChanged: (manoObra) =>
                notifier.updateLineItemLabor(finding.id, manoObra),
            onPartChanged: (partId, costo) =>
                notifier.updateLineItemPart(finding.id, partId, costo),
          );
        }),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: state.descuento > 0
              ? state.descuento.toStringAsFixed(2)
              : '',
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Descuento (₡)',
            prefixText: '₡ ',
          ),
          onChanged: (v) {
            final val = double.tryParse(v) ?? 0.0;
            notifier.updateDescuento(val);
          },
        ),
        const SizedBox(height: 16),
        QuotationSummaryCard(
          subtotal: state.previewSubtotal,
          shopSupplies: state.previewShopSupplies,
          impuestos: state.previewImpuestos,
          descuento: state.descuento,
          total: state.previewTotal,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed:
              state.isSaving ? null : notifier.generateQuotation,
          child: state.isSaving
              ? const _SpinnerButton()
              : const Text('Generar Cotización'),
        ),
      ],
    );
  }
}

class _QuotationDetailView extends StatelessWidget {
  const _QuotationDetailView({
    required this.quotation,
    this.safetyLog,
  });

  final QuotationModel quotation;
  final String? safetyLog;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _EstadoChip(estado: quotation.estado),
            if (quotation.fechaEnvio != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Enviada el ${DateFormat('dd/MM/yyyy HH:mm').format(quotation.fechaEnvio!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
        if (safetyLog != null) ...[
          const SizedBox(height: 12),
          _SafetyLogBanner(safetyLog: safetyLog!),
        ],
        const SizedBox(height: 16),
        ...quotation.items.map((item) => QuotationItemRow(item: item)),
        const Divider(height: 32),
        QuotationSummaryCard(
          subtotal: quotation.subtotal,
          shopSupplies: quotation.shopSupplies,
          impuestos: quotation.impuestos,
          descuento: quotation.descuento,
          total: quotation.total,
        ),
      ],
    );
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.estado});

  final QuotationEstado estado;

  Color get _color => switch (estado) {
        QuotationEstado.pendiente => Colors.amber[700]!,
        QuotationEstado.aprobada => Colors.green[700]!,
        QuotationEstado.rechazada => Colors.red[700]!,
      };

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(estado.label),
      labelStyle: TextStyle(color: _color, fontWeight: FontWeight.bold),
      backgroundColor: _color.withValues(alpha: 0.1),
      side: BorderSide(color: _color),
    );
  }
}

class _SafetyLogBanner extends StatelessWidget {
  const _SafetyLogBanner({required this.safetyLog});

  final String safetyLog;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[700]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Advertencia de Seguridad',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  safetyLog,
                  style: TextStyle(color: Colors.red[800]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBarContainer extends StatelessWidget {
  const _ActionBarContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(child: child),
    );
  }
}

class _SpinnerButton extends StatelessWidget {
  const _SpinnerButton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Colors.white,
      ),
    );
  }
}
