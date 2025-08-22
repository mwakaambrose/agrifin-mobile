// Unified Member data model
class Member {
  final int id;
  final String name;
  final String? phone;
  final String? address;
  final String? region;
  final String? district;
  final String? nationalId; // legacy/specific ID number if provided
  // New fields
  final String? gender; // 'male' | 'female' | 'other' | custom
  final String?
  maritalStatus; // 'single' | 'married' | 'divorced' | 'widowed' | other
  final bool? hasDisability; // true if member reports disability
  final String?
  idType; // 'national_id' | 'refugee_id' | 'passport' | 'driving_licence' | 'other'
  final String? idNumber; // ID number matching idType
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
    this.region,
    this.district,
    this.nationalId,
    this.gender,
    this.maritalStatus,
    this.hasDisability,
    this.idType,
    this.idNumber,
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
    String? region,
    String? district,
    String? nationalId,
    String? gender,
    String? maritalStatus,
    bool? hasDisability,
    String? idType,
    String? idNumber,
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
    region: region ?? this.region,
    district: district ?? this.district,
    nationalId: nationalId ?? this.nationalId,
    gender: gender ?? this.gender,
    maritalStatus: maritalStatus ?? this.maritalStatus,
    hasDisability: hasDisability ?? this.hasDisability,
    idType: idType ?? this.idType,
    idNumber: idNumber ?? this.idNumber,
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
      region: json['region'] as String?,
      district: json['district'] as String?,
      nationalId: json['national_id'] as String? ?? json['nid'] as String?,
      gender: json['gender'] as String?,
      maritalStatus: json['marital_status'] as String?,
      hasDisability:
          json['has_disability'] is bool
              ? json['has_disability'] as bool
              : (json['has_disability'] != null
                  ? (json['has_disability'].toString() == '1' ||
                      json['has_disability'].toString().toLowerCase() == 'true')
                  : null),
      idType: json['id_type'] as String?,
      idNumber: json['id_number'] as String? ?? json['national_id'] as String?,
      photoPath:
          json['photo_path'] as String? ??
          json['photo_url'] as String? ??
          json['photo'] as String?,
      joinedOn:
          json['joined_at'] != null
              ? DateTime.parse(json['joined_at'] as String)
              : DateTime.now(),
      active: json['active'] as bool? ?? true, // Parse active status
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'address': address,
    'region': region,
    'district': district,
    'national_id': nationalId,
    'gender': gender,
    'marital_status': maritalStatus,
    'has_disability': hasDisability,
    'id_type': idType,
    'id_number': idNumber ?? nationalId,
    'photo_path': photoPath,
    'joined_at': joinedOn.toIso8601String(),
    'roles': roles,
    'savings': savings,
    'loans': loans,
    'social_fund': socialFund,
    'active': active,
  };
}
