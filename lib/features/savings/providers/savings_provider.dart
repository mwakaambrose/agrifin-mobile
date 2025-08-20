import 'package:flutter/material.dart';
import '../viewmodels/savings_viewmodel.dart';

class SavingsProvider extends InheritedWidget {
  final SavingsViewModel viewModel;
  const SavingsProvider({
    Key? key,
    required this.viewModel,
    required Widget child,
  }) : super(key: key, child: child);
  static SavingsProvider? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SavingsProvider>();
  @override
  bool updateShouldNotify(SavingsProvider oldWidget) =>
      viewModel != oldWidget.viewModel;
}
