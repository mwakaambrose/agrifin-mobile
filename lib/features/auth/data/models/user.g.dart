// GENERATED CODE - PLACEHOLDER. Run build_runner to regenerate.
part of 'user.dart';

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
  id: json['id'] as int,
  name: json['name'] as String,
  phone: json['phone'] as String?,
  email: json['email'] as String?,
  avatar_url: json['avatarUrl'] as String?,
  group_id: json['group_id'] as int,
);

Map<String, dynamic> _$UserDtoToJson(UserDto instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'phone': instance.phone,
  'email': instance.email,
  'avatar_url': instance.avatar_url,
  'group_id': instance.group_id,
};
