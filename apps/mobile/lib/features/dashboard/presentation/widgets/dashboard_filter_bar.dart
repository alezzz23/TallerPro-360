import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';
import '../../domain/dashboard_state.dart';

class DashboardFilterBar extends StatelessWidget {
  const DashboardFilterBar({
    super.key,
    required this.state,
    required this.onAdvisorChanged,
    required this.onTechnicianChanged,
    required this.onPickDate,
    required this.onClearDate,
    required this.onClearFilters,
  });

  final DashboardState state;
  final ValueChanged<String?> onAdvisorChanged;
  final ValueChanged<String?> onTechnicianChanged;
  final Future<void> Function() onPickDate;
  final VoidCallback onClearDate;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final filters = state.filters;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                value: filters.advisorId,
                isExpanded: true,
                items: _buildItems(
                  emptyLabel: 'Todos los asesores',
                  options: state.advisors,
                  selectedValue: filters.advisorId,
                ),
                onChanged: onAdvisorChanged,
                decoration: const InputDecoration(
                  labelText: 'Asesor',
                  isDense: true,
                  prefixIcon: Icon(Icons.support_agent_rounded),
                ),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                value: filters.technicianId,
                isExpanded: true,
                items: _buildItems(
                  emptyLabel: 'Todos los técnicos',
                  options: state.technicians,
                  selectedValue: filters.technicianId,
                ),
                onChanged: onTechnicianChanged,
                decoration: const InputDecoration(
                  labelText: 'Técnico',
                  isDense: true,
                  prefixIcon: Icon(Icons.engineering_rounded),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => onPickDate(),
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(
                filters.selectedDate == null
                    ? 'Filtrar fecha'
                    : filters.selectedDate!.toLocal().toDisplayDate(),
              ),
            ),
            if (filters.selectedDate != null)
              IconButton(
                onPressed: onClearDate,
                tooltip: 'Limpiar fecha',
                icon: const Icon(Icons.clear_rounded),
              ),
            Semantics(
              label: 'Limpiar todos los filtros activos',
              child: TextButton.icon(
                onPressed: filters.hasActiveFilters ? onClearFilters : null,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Limpiar filtros'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildItems({
    required String emptyLabel,
    required List<DashboardActorOption> options,
    required String? selectedValue,
  }) {
    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem<String>(value: null, child: Text(emptyLabel)),
      ...options.map(
        (option) => DropdownMenuItem<String>(
          value: option.id,
          child: Text(option.label),
        ),
      ),
    ];

    if (selectedValue != null &&
        options.every((option) => option.id != selectedValue)) {
      final shortId = selectedValue.split('-').first.toUpperCase();
      items.add(
        DropdownMenuItem<String>(
          value: selectedValue,
          child: Text('Seleccionado $shortId'),
        ),
      );
    }

    return items;
  }
}