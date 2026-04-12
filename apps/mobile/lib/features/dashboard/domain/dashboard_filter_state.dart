class DashboardFilterState {
  const DashboardFilterState({
    this.advisorId,
    this.technicianId,
    this.selectedDate,
  });

  static const Object _unset = Object();

  final String? advisorId;
  final String? technicianId;
  final DateTime? selectedDate;

  bool get hasActiveFilters {
    return advisorId != null || technicianId != null || selectedDate != null;
  }

  DashboardFilterState copyWith({
    Object? advisorId = _unset,
    Object? technicianId = _unset,
    Object? selectedDate = _unset,
  }) {
    return DashboardFilterState(
      advisorId: identical(advisorId, _unset) ? this.advisorId : advisorId as String?,
      technicianId: identical(technicianId, _unset)
          ? this.technicianId
          : technicianId as String?,
      selectedDate: identical(selectedDate, _unset)
          ? this.selectedDate
          : selectedDate as DateTime?,
    );
  }
}