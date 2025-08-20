import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/api/group_api_repository.dart';

class GroupInfo {
  final String id;
  String name;
  int memberCount;
  String meetingFrequency; // e.g. 'Bi-weekly', 'Weekly'
  double totalSavings; // aggregate savings
  double outstandingLoans; // current outstanding balance
  DateTime createdAt;

  GroupInfo({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.meetingFrequency,
    required this.totalSavings,
    required this.outstandingLoans,
    required this.createdAt,
  });

  GroupInfo copyWith({
    String? name,
    int? memberCount,
    String? meetingFrequency,
    double? totalSavings,
    double? outstandingLoans,
  }) => GroupInfo(
    id: id,
    name: name ?? this.name,
    memberCount: memberCount ?? this.memberCount,
    meetingFrequency: meetingFrequency ?? this.meetingFrequency,
    totalSavings: totalSavings ?? this.totalSavings,
    outstandingLoans: outstandingLoans ?? this.outstandingLoans,
    createdAt: createdAt,
  );
}

class GroupViewModel extends ChangeNotifier {
  GroupViewModel() {
    // Kick off initial load
    refresh();
  }

  GroupInfo _group = GroupInfo(
    id: '-',
    name: 'Loading…',
    memberCount: 0,
    meetingFrequency: '—',
    totalSavings: 0,
    outstandingLoans: 0,
    createdAt: DateTime.now(),
  );

  bool _loading = false;
  String? _error;

  GroupInfo get group => _group;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Pull group id from Hive box
      final box = await Hive.openBox('user_data');
      final dynamic groupIdRaw = box.get('group_id');
      final int? groupId =
          groupIdRaw is int
              ? groupIdRaw
              : int.tryParse(groupIdRaw?.toString() ?? '');
      if (groupId == null) {
        throw Exception('No group selected');
      }

      // Fetch profile from API
      final dto = await GroupApiRepository().getProfile(groupId);
      _group = _mapDtoToGroupInfo(dto.data);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void updateName(String name) {
    _group = _group.copyWith(name: name);
    notifyListeners();
  }

  void incrementMembers([int by = 1]) {
    _group = _group.copyWith(memberCount: _group.memberCount + by);
    notifyListeners();
  }

  void setMeetingFrequency(String freq) {
    _group = _group.copyWith(meetingFrequency: freq);
    notifyListeners();
  }

  void updateFinancials({double? totalSavings, double? outstandingLoans}) {
    _group = _group.copyWith(
      totalSavings: totalSavings,
      outstandingLoans: outstandingLoans,
    );
    notifyListeners();
  }

  // For demo: add savings
  void addSavings(double amount) {
    _group = _group.copyWith(totalSavings: _group.totalSavings + amount);
    notifyListeners();
  }

  void adjustOutstandingLoans(double delta) {
    _group = _group.copyWith(
      outstandingLoans: (_group.outstandingLoans + delta).clamp(
        0,
        double.infinity,
      ),
    );
    notifyListeners();
  }

  GroupInfo _mapDtoToGroupInfo(Map<String, dynamic> data) {
    final stats = (data['stats'] as Map?)?.cast<String, dynamic>() ?? {};
    final createdAtStr = data['created_at'] as String?;
    final createdAt = _safeParseDateTime(createdAtStr) ?? DateTime.now();
    final recentMeetings =
        (stats['recent_meetings'] as List?)
            ?.cast<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList() ??
        const <Map<String, dynamic>>[];

    return GroupInfo(
      id: (data['id'] ?? '-').toString(),
      name: (data['name'] as String?) ?? '-',
      memberCount: (stats['member_count'] as int?) ?? 0,
      meetingFrequency: _inferMeetingFrequency(recentMeetings),
      totalSavings: ((stats['total_savings'] as num?)?.toDouble()) ?? 0.0,
      outstandingLoans:
          ((stats['loans_outstanding_balance'] as num?)?.toDouble()) ?? 0.0,
      createdAt: createdAt,
    );
  }

  DateTime? _safeParseDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      // Support both ISO and "yyyy-MM-dd HH:mm:ss"
      final normalized =
          value.contains('T') ? value : value.replaceFirst(' ', 'T');
      return DateTime.parse(normalized).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _inferMeetingFrequency(List<Map<String, dynamic>> meetings) {
    if (meetings.length < 2) return '—';
    // Sort by scheduled_date desc
    meetings.sort((a, b) {
      final ad =
          _safeParseDateTime((a['scheduled_date'] as String?)) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bd =
          _safeParseDateTime((b['scheduled_date'] as String?)) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    final d1 = _safeParseDateTime(meetings[0]['scheduled_date'] as String?);
    final d2 = _safeParseDateTime(meetings[1]['scheduled_date'] as String?);
    if (d1 == null || d2 == null) return '—';
    final days = (d1.difference(d2).inDays).abs();
    if (days <= 8) return 'Weekly';
    if (days <= 17) return 'Bi-weekly';
    if (days <= 45) return 'Monthly';
    return 'Ad-hoc';
  }
}
