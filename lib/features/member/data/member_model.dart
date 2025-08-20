// Unified Member data model
class Member {
  final int id;
  final String name;
  final String? phone;
  final String? address;
  final String? nationalId;
  final String? photoPath;
  final DateTime joinedOn;
  final List<String> roles; // primary role first
  final double savings;
  final double loans;
  final double socialFund;
  final bool active; // Added active property

  const Member({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.nationalId,
    this.photoPath,
    required this.joinedOn,
    this.roles = const [],
    this.savings = 0,
    this.loans = 0,
    this.socialFund = 0,
    this.active = true, // Default to active
  });

  Member copyWith({
    String? name,
    String? phone,
    String? address,
    String? nationalId,
    String? photoPath,
    DateTime? joinedOn,
    List<String>? roles,
    double? savings,
    double? loans,
    double? socialFund,
    bool? active,
  }) => Member(
    id: id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    nationalId: nationalId ?? this.nationalId,
    photoPath: photoPath ?? this.photoPath,
    joinedOn: joinedOn ?? this.joinedOn,
    roles: roles ?? this.roles,
    savings: savings ?? this.savings,
    loans: loans ?? this.loans,
    socialFund: socialFund ?? this.socialFund,
    active: active ?? this.active,
  );

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      nationalId: json['national_id'] as String?,
      joinedOn:
          json['joined_at'] != null
              ? DateTime.parse(json['joined_at'] as String)
              : DateTime.now(),
      active: json['active'] as bool? ?? true, // Parse active status
    );
  }
}
