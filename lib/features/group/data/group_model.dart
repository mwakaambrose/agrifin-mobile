// Group model for group profile feature
class Group {
  final String id;
  final String name;
  final String region;
  final String gps;
  final List<String> roles;

  Group({
    required this.id,
    required this.name,
    required this.region,
    required this.gps,
    required this.roles,
  });
}
