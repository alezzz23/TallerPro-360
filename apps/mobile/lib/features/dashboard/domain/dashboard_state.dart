import 'dashboard_filter_state.dart';
import 'dashboard_order.dart';

class DashboardActorOption {
  const DashboardActorOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class DashboardState {
  DashboardState({
    required List<DashboardOrder> allOrders,
    required List<DashboardActorOption> advisors,
    required List<DashboardActorOption> technicians,
    this.filters = const DashboardFilterState(),
    DateTime? refreshedAt,
  }) : allOrders = List.unmodifiable(allOrders),
       advisors = List.unmodifiable(advisors),
       technicians = List.unmodifiable(technicians),
       refreshedAt = refreshedAt ?? DateTime.now();

  factory DashboardState.fromOrders(List<DashboardOrder> orders) {
    final sortedOrders = [...orders]..sort(_sortOrders);
    return DashboardState(
      allOrders: sortedOrders,
      advisors: _buildAdvisorOptions(sortedOrders),
      technicians: _buildTechnicianOptions(sortedOrders),
    );
  }

  final List<DashboardOrder> allOrders;
  final List<DashboardActorOption> advisors;
  final List<DashboardActorOption> technicians;
  final DashboardFilterState filters;
  final DateTime refreshedAt;

  DashboardState copyWith({
    List<DashboardOrder>? allOrders,
    List<DashboardActorOption>? advisors,
    List<DashboardActorOption>? technicians,
    DashboardFilterState? filters,
    DateTime? refreshedAt,
  }) {
    return DashboardState(
      allOrders: allOrders ?? this.allOrders,
      advisors: advisors ?? this.advisors,
      technicians: technicians ?? this.technicians,
      filters: filters ?? this.filters,
      refreshedAt: refreshedAt ?? this.refreshedAt,
    );
  }

  DashboardState withFilters(DashboardFilterState nextFilters) {
    return copyWith(filters: nextFilters);
  }

  List<DashboardOrder> get visibleOrders {
    return _applyFilters(allOrders, filters);
  }

  bool get isEmpty => visibleOrders.isEmpty;

  Map<DashboardStatus, List<DashboardOrder>> get columns {
    return {
      for (final status in DashboardStatus.boardColumns)
        status: List.unmodifiable(
          visibleOrders.where((order) => order.status == status).toList()
            ..sort(_sortOrders),
        ),
    };
  }

  static List<DashboardOrder> _applyFilters(
    List<DashboardOrder> orders,
    DashboardFilterState filters,
  ) {
    return orders.where((order) {
      if (filters.advisorId != null && order.advisorId != filters.advisorId) {
        return false;
      }
      if (filters.technicianId != null &&
          !order.technicianIds.contains(filters.technicianId)) {
        return false;
      }
      if (filters.selectedDate != null &&
          !_isSameDate(order.fechaIngreso.toLocal(), filters.selectedDate!.toLocal())) {
        return false;
      }
      return true;
    }).toList(growable: false)
      ..sort(_sortOrders);
  }

  static List<DashboardActorOption> _buildAdvisorOptions(List<DashboardOrder> orders) {
    final advisorIds = <String>{
      for (final order in orders)
        if (order.advisorId.trim().isNotEmpty) order.advisorId.trim(),
    };

    final options = advisorIds
        .map(
          (advisorId) => DashboardActorOption(
            id: advisorId,
            label: 'Asesor ${_shortId(advisorId)}',
          ),
        )
        .toList(growable: false);

    options.sort((left, right) => left.label.compareTo(right.label));
    return options;
  }

  static List<DashboardActorOption> _buildTechnicianOptions(List<DashboardOrder> orders) {
    final technicianIds = <String>{
      for (final order in orders) ...order.technicianIds,
    };

    final options = technicianIds
        .map(
          (technicianId) => DashboardActorOption(
            id: technicianId,
            label: 'Técnico ${_shortId(technicianId)}',
          ),
        )
        .toList(growable: false);

    options.sort((left, right) => left.label.compareTo(right.label));
    return options;
  }

  static bool _isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  static int _sortOrders(DashboardOrder left, DashboardOrder right) {
    return left.fechaIngreso.compareTo(right.fechaIngreso);
  }

  static String _shortId(String value) {
    final token = value.split('-').first;
    return token.length > 8 ? token.substring(0, 8).toUpperCase() : token.toUpperCase();
  }
}