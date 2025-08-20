import 'package:flutter/material.dart';
import '../viewmodels/notifications_viewmodel.dart';

class NotificationsProvider extends InheritedWidget {
  final NotificationsViewModel viewModel;
  const NotificationsProvider({
    Key? key,
    required this.viewModel,
    required Widget child,
  }) : super(key: key, child: child);
  static NotificationsProvider? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NotificationsProvider>();
  @override
  bool updateShouldNotify(NotificationsProvider oldWidget) =>
      viewModel != oldWidget.viewModel;
}
