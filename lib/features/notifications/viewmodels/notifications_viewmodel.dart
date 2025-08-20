import '../data/notification_model.dart';
import '../../common/viewmodels/base_viewmodel.dart';
import '../data/api/notifications_api_repository.dart';

class NotificationsViewModel extends BaseViewModel {
  final NotificationsApiRepository _api;
  NotificationsViewModel({NotificationsApiRepository? api})
    : _api = api ?? NotificationsApiRepository();

  List<AppNotification> _notifications = [];
  final Set<String> _readIds = <String>{};
  int? _lastGroupId;

  List<AppNotification> get notifications => _notifications;
  Set<String> get readIds => _readIds;
  bool get isEmpty => _notifications.isEmpty;

  Future<void> load(int groupId, {String? status}) async {
    if (busy) return;
    setBusy(true);
    setError(null);
    try {
      _lastGroupId = groupId;
      final res = await _api.list(group_id: groupId, status: status);
      _notifications =
          res.data
              .map(
                (dto) => AppNotification(
                  id: dto.id.toString(),
                  title: dto.title,
                  message: dto.body ?? '',
                  dateTime: dto.createdAt,
                ),
              )
              .toList();
      _readIds
        ..clear()
        ..addAll(
          res.data.where((d) => d.readAt != null).map((d) => d.id.toString()),
        );
    } catch (e) {
      setError(e.toString());
    } finally {
      setBusy(false);
    }
  }

  Future<void> markAsRead(String id) async {
    _readIds.add(id);
    notifyListeners();
    if (_lastGroupId == null) return;
    try {
      await _api.markRead(
        group_id: _lastGroupId!,
        notificationId: int.parse(id),
      );
    } catch (e) {
      // revert on failure
      _readIds.remove(id);
      setError(e.toString());
      notifyListeners();
    }
  }

  Future<void> dismissNotification(String id) async {
    final prev = List<AppNotification>.from(_notifications);
    _notifications.removeWhere((n) => n.id == id);
    _readIds.remove(id);
    notifyListeners();
    if (_lastGroupId == null) return;
    try {
      await _api.dismiss(
        group_id: _lastGroupId!,
        notificationId: int.parse(id),
      );
    } catch (e) {
      // revert on failure
      _notifications = prev;
      setError(e.toString());
      notifyListeners();
    }
  }

  bool isNotificationRead(String id) {
    return _readIds.contains(id);
  }

  String formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} min${diff.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> markAllAsRead() async {
    if (_notifications.isEmpty) return;
    setBusy(true);
    setError(null);
    try {
      for (final notification in _notifications) {
        if (!_readIds.contains(notification.id)) {
          _readIds.add(notification.id);
          if (_lastGroupId != null) {
            await _api.markRead(
              group_id: _lastGroupId!,
              notificationId: int.parse(notification.id),
            );
          }
        }
      }
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    } finally {
      setBusy(false);
    }
  }

  void clearAllNotifications() {
    _notifications.clear();
    _readIds.clear();
    notifyListeners();
  }

  int get unreadCount =>
      _notifications.where((n) => !_readIds.contains(n.id)).length;
}
