import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class UserDto {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? avatar_url;
  final int group_id; // Added group_id property

  UserDto({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.avatar_url,
    required this.group_id,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}
