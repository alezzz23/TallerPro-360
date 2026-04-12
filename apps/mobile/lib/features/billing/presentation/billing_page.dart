import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/domain/auth_state.dart';
import '../application/billing_providers.dart';
import '../domain/billing_models.dart';
import '../domain/billing_state.dart';
import 'widgets/nps_score_slider.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

final _currencyFmt = NumberFormat('#,##0.00', 'es_CR');
final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

String _fmt(double v) => '₡\u00a0${_currencyFmt.format(v)}';

const _advisorRoles = {'ASESOR', 'JEFE_TALLER', 'ADMIN'};

// ─── BillingPage ─────────────────────────────────────────────────────────────

class BillingPage extends ConsumerStatefulWidget {
  const BillingPage({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends ConsumerState<BillingPage> {
  late final TextEditingController _saldoCtrl;
  late final TextEditingController _comentariosCtrl;

  @override
  void initState() {
    super.initState();
    _saldoCtrl = TextEditingController();
    _comentariosCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _saldoCtrl.dispose();
    _comentariosCtrl.dispose();
    super.dispose();
  }

  String get _shortId => widget.orderId.length >= 8
      ? widget.orderId.substring(0, 8)
      : widget.orderId;

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(billingControllerProvider(widget.orderId));
    final authState = ref.watch(authStateProvider);
    final isAdvisor = _advisorRoles.contains(authState.rol?.toUpperCase());

    // Listen for errors → SnackBar
    ref.listen<BillingState>(
      billingControllerProvider(widget.orderId),
      (prev, next) {
        if (next.errorMessage != null &&
            next.errorMessage != prev?.errorMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Facturación — Orden #$_shortId'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _OrderSummarySection(quotation: state.quotation),
                const SizedBox(height: 16),
                _InvoiceSection(
                  state: state,
                  isAdvisor: isAdvisor,
                  saldoCtrl: _saldoCtrl,
                  onMetodoPago: (m) => ref
                      .read(billingControllerProvider(widget.orderId).notifier)
                      .setMetodoPago(m),
                  onEsCredito: (v) => ref
                      .read(billingControllerProvider(widget.orderId).notifier)
                      .setEsCredito(v),
                  onSaldoChanged: (v) => ref
                      .read(billingControllerProvider(widget.orderId).notifier)
                      .setSaldoPendiente(v),
                  onCreateInvoice: () => ref
                      .read(billingControllerProvider(widget.orderId).notifier)
                      .createInvoice(),
                ),
                const SizedBox(height: 16),
                _NpsSurveySection(
                  state: state,
                  comentariosCtrl: _comentariosCtrl,
                  onScore: (cat, val) => ref
                      .read(billingControllerProvider(widget.orderId).notifier)
                      .setNpsScore(cat, val),
                  onComentarios: (text) => ref
                      .read(billingControllerProvider(widget.orderId).notifier)
                      .setNpsComentarios(text),
                  onSubmitNps: () => ref
                      .read(billingControllerProvider(widget.orderId).notifier)
                      .submitNps(),
                ),
                const SizedBox(height: 80),
              ],
            ),
      bottomNavigationBar: isAdvisor
          ? _CloseOrderBar(
              state: state,
              onClose: () => _confirmClose(context, widget.orderId),
            )
          : null,
    );
  }

  Future<void> _confirmClose(BuildContext context, String orderId) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Orden'),
        content:
            const Text('¿Cerrar orden? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Cerrar Orden'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(billingControllerProvider(orderId).notifier)
          .closeOrder();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Orden cerrada exitosamente')),
      );
    }
  }
}

// ─── _OrderSummarySection ─────────────────────────────────────────────────────

class _OrderSummarySection extends StatelessWidget {
  const _OrderSummarySection({required this.quotation});

  final QuotationSummary? quotation;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen de la Orden',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 12),
            if (quotation == null)
              const Center(
                child: Text(
                  'Sin cotización aprobada',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else ...[
              _SummaryRow(
                  label: 'Subtotal', value: _fmt(quotation!.subtotal)),
              _SummaryRow(
                  label: 'Shop Supplies',
                  value: _fmt(quotation!.shopSupplies)),
              _SummaryRow(label: 'IVA', value: _fmt(quotation!.impuestos)),
              if (quotation!.descuento > 0)
                _SummaryRow(
                  label: 'Descuento',
                  value: '-${_fmt(quotation!.descuento)}',
                  valueColor: Colors.red.shade700,
                ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    _fmt(quotation!.total),
                    style:
                        Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                ],
              ),
            ],
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
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w500,
                  )),
        ],
      ),
    );
  }
}

// ─── _InvoiceSection ─────────────────────────────────────────────────────────

class _InvoiceSection extends StatelessWidget {
  const _InvoiceSection({
    required this.state,
    required this.isAdvisor,
    required this.saldoCtrl,
    required this.onMetodoPago,
    required this.onEsCredito,
    required this.onSaldoChanged,
    required this.onCreateInvoice,
  });

  final BillingState state;
  final bool isAdvisor;
  final TextEditingController saldoCtrl;
  final ValueChanged<MetodoPago> onMetodoPago;
  final ValueChanged<bool> onEsCredito;
  final ValueChanged<double> onSaldoChanged;
  final VoidCallback onCreateInvoice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Factura',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 12),
            if (state.invoice != null)
              _InvoiceDetails(invoice: state.invoice!)
            else if (isAdvisor)
              _InvoiceForm(
                state: state,
                saldoCtrl: saldoCtrl,
                onMetodoPago: onMetodoPago,
                onEsCredito: onEsCredito,
                onSaldoChanged: onSaldoChanged,
                onCreateInvoice: onCreateInvoice,
              )
            else
              const Text(
                'Sin factura generada.',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceForm extends StatelessWidget {
  const _InvoiceForm({
    required this.state,
    required this.saldoCtrl,
    required this.onMetodoPago,
    required this.onEsCredito,
    required this.onSaldoChanged,
    required this.onCreateInvoice,
  });

  final BillingState state;
  final TextEditingController saldoCtrl;
  final ValueChanged<MetodoPago> onMetodoPago;
  final ValueChanged<bool> onEsCredito;
  final ValueChanged<double> onSaldoChanged;
  final VoidCallback onCreateInvoice;

  @override
  Widget build(BuildContext context) {
    final canCreate = state.canCreateInvoice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Método de Pago',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                )),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MetodoPago.values
              .map((m) => MetodoPagoTile(
                    metodo: m,
                    selected: state.selectedMetodoPago == m,
                    onTap: () => onMetodoPago(m),
                  ))
              .toList(),
        ),
        if (state.esCredito) ...[
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Venta a Crédito'),
            value: state.esCredito,
            onChanged: onEsCredito,
            activeColor: AppColors.primary,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: saldoCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Saldo Pendiente (₡)',
              prefixText: '₡ ',
            ),
            onChanged: (v) {
              final parsed = double.tryParse(v);
              if (parsed != null) onSaldoChanged(parsed);
            },
          ),
        ],
        const SizedBox(height: 16),
        if (!canCreate && state.orderEstado != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'La orden debe estar en estado ENTREGA',
              style:
                  TextStyle(color: Colors.orange.shade700, fontSize: 12),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (canCreate && !state.isSaving) ? onCreateInvoice : null,
            icon: state.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.receipt_long),
            label: const Text('Generar Factura'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ],
    );
  }
}

class _InvoiceDetails extends StatelessWidget {
  const _InvoiceDetails({required this.invoice});

  final InvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Text('Factura Generada',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    )),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryRow(label: 'Monto Total', value: _fmt(invoice.montoTotal)),
        _SummaryRow(
            label: 'Método de Pago', value: invoice.metodoPago.label),
        if (invoice.esCredito)
          _SummaryRow(
              label: 'Saldo Pendiente',
              value: _fmt(invoice.saldoPendiente)),
        _SummaryRow(label: 'Fecha', value: _dateFmt.format(invoice.fecha)),
      ],
    );
  }
}

// ─── _NpsSurveySection ────────────────────────────────────────────────────────

class _NpsSurveySection extends StatelessWidget {
  const _NpsSurveySection({
    required this.state,
    required this.comentariosCtrl,
    required this.onScore,
    required this.onComentarios,
    required this.onSubmitNps,
  });

  final BillingState state;
  final TextEditingController comentariosCtrl;
  final void Function(String category, int value) onScore;
  final ValueChanged<String?> onComentarios;
  final VoidCallback onSubmitNps;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Encuesta de Satisfacción (NPS)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 12),
            if (state.nps != null)
              _NpsCompleted(nps: state.nps!)
            else
              _NpsForm(
                state: state,
                comentariosCtrl: comentariosCtrl,
                onScore: onScore,
                onComentarios: onComentarios,
                onSubmitNps: onSubmitNps,
              ),
          ],
        ),
      ),
    );
  }
}

class _NpsForm extends StatelessWidget {
  const _NpsForm({
    required this.state,
    required this.comentariosCtrl,
    required this.onScore,
    required this.onComentarios,
    required this.onSubmitNps,
  });

  final BillingState state;
  final TextEditingController comentariosCtrl;
  final void Function(String category, int value) onScore;
  final ValueChanged<String?> onComentarios;
  final VoidCallback onSubmitNps;

  @override
  Widget build(BuildContext context) {
    final canSubmit = state.invoice != null && state.canSubmitNps;

    return Column(
      children: [
        NpsScoreSlider(
          label: 'Atención al Cliente',
          value: state.npsAtencion,
          onChanged: (v) => onScore('atencion', v),
        ),
        NpsScoreSlider(
          label: 'Instalaciones',
          value: state.npsInstalaciones,
          onChanged: (v) => onScore('instalaciones', v),
        ),
        NpsScoreSlider(
          label: 'Tiempos de Entrega',
          value: state.npsTiempos,
          onChanged: (v) => onScore('tiempos', v),
        ),
        NpsScoreSlider(
          label: 'Precios',
          value: state.npsPrecios,
          onChanged: (v) => onScore('precios', v),
        ),
        NpsScoreSlider(
          label: '¿Nos Recomendarías? (NPS)',
          value: state.npsRecomendacion,
          isNpsSlider: true,
          onChanged: (v) => onScore('recomendacion', v),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: comentariosCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Comentarios adicionales (opcional)',
            alignLabelWithHint: true,
          ),
          onChanged: (v) => onComentarios(v.isEmpty ? null : v),
        ),
        const SizedBox(height: 16),
        if (state.invoice == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'La factura debe generarse primero',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (canSubmit && !state.isSaving) ? onSubmitNps : null,
            icon: state.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send),
            label: const Text('Enviar Encuesta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ],
    );
  }
}

class _NpsCompleted extends StatelessWidget {
  const _NpsCompleted({required this.nps});

  final NpsModel nps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Text('Encuesta Enviada',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    )),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            NpsScoreChip(label: 'Atención', value: nps.atencion),
            NpsScoreChip(label: 'Instalaciones', value: nps.instalaciones),
            NpsScoreChip(label: 'Tiempos', value: nps.tiempos),
            NpsScoreChip(label: 'Precios', value: nps.precios),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: NpsScoreChip(
            label: 'NPS',
            value: nps.recomendacion,
            isNps: true,
          ),
        ),
        if (nps.comentarios != null && nps.comentarios!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            nps.comentarios!,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );
  }
}

// ─── _CloseOrderBar ───────────────────────────────────────────────────────────

class _CloseOrderBar extends StatelessWidget {
  const _CloseOrderBar({
    required this.state,
    required this.onClose,
  });

  final BillingState state;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    if (state.orderClosed || state.orderEstado == 'CERRADA') {
      return Container(
        width: double.infinity,
        color: Colors.green.shade600,
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              '✓ Orden Cerrada — Servicio completado',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final canClose = state.canCloseOrder && !state.isSaving;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Tooltip(
          message: canClose ? '' : 'Se requiere factura y encuesta NPS',
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canClose ? onClose : null,
              icon: state.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.lock),
              label: const Text('Cerrar Orden'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
