// Report model for financial reports
class Report {
  final String id;
  final String type;
  final String cycleId;
  final String content;

  Report({
    required this.id,
    required this.type,
    required this.cycleId,
    required this.content,
  });
}
