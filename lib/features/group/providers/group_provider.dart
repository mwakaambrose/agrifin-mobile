import 'package:flutter/material.dart';
import '../viewmodels/group_viewmodel.dart';

class GroupProvider extends InheritedWidget {
  final GroupViewModel viewModel;
  const GroupProvider({
    Key? key,
    required this.viewModel,
    required Widget child,
  }) : super(key: key, child: child);
  static GroupProvider? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GroupProvider>();
  @override
  bool updateShouldNotify(GroupProvider oldWidget) =>
      viewModel != oldWidget.viewModel;
}
