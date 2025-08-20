import 'package:flutter/material.dart';
import '../viewmodels/reports_viewmodel.dart';

class ReportsProvider extends InheritedWidget {
  final ReportsViewModel viewModel;
  const ReportsProvider({
    Key? key,
    required this.viewModel,
    required Widget child,
  }) : super(key: key, child: child);
  static ReportsProvider? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ReportsProvider>();
  @override
  bool updateShouldNotify(ReportsProvider oldWidget) =>
      viewModel != oldWidget.viewModel;
}
