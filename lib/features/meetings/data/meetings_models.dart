class Meeting {
  Meeting copyWith({
    int? id,
    int? cycleId,
    String? name,
    String? scheduledAt,
    String? meetingDate,
    String? status,
    bool? active,
    bool? isOpen,
    String? currentStep,
    String? notes,
    String? closingNotes,
  }) {
    return Meeting(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      name: name ?? this.name,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      meetingDate: meetingDate ?? this.meetingDate,
      status: status ?? this.status,
      active: active ?? this.active,
      isOpen: isOpen ?? this.isOpen,
      currentStep: currentStep,
      closingNotes: closingNotes ?? this.closingNotes,
    );
  }

  final int id;
  final int cycleId;
  // New optional fields from API
  final String? name; // 'name'
  final String? scheduledAt; // existing UI field
  final String? meetingDate; // 'meeting_date'
  final String? status; // 'status'
  final bool? active; // existing UI flag
  final bool? isOpen; // 'is_open'
  final String? currentStep; // 'current_step'
  final String? closingNotes; // 'closing_notes'

  Meeting({
    required this.id,
    required this.cycleId,
    this.name,
    required this.scheduledAt,
    this.meetingDate,
    this.status,
    this.active = false,
    this.isOpen,
    this.currentStep,
    this.closingNotes,
  });
}

class AttendanceRecord {
  AttendanceRecord copyWith({
    int? id,
    int? meetingId,
    int? memberId,
    bool? present,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      memberId: memberId ?? this.memberId,
      present: present ?? this.present,
    );
  }

  final int id;
  final int meetingId;
  final int memberId;
  final bool present;
  AttendanceRecord({
    required this.id,
    required this.meetingId,
    required this.memberId,
    required this.present,
  });
}
