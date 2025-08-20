// Cycle model for cycle management
class Cycle {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  Cycle({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  Cycle copyWith({
    int? id, // Changed from String? to int?
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? status,
  }) {
    return Cycle(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }
}
