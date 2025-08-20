import 'package:flutter/material.dart';
import '../viewmodels/cycle_viewmodel.dart';

class CycleProvider extends InheritedWidget {
  final CycleViewModel viewModel;
  const CycleProvider({
    Key? key,
    required this.viewModel,
    required Widget child,
  }) : super(key: key, child: child);
  static CycleProvider? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CycleProvider>();
  @override
  bool updateShouldNotify(CycleProvider oldWidget) =>
      viewModel != oldWidget.viewModel;
}
