import 'package:flutter/material.dart';
import '../viewmodels/fines_viewmodel.dart';

class FinesProvider extends InheritedWidget {
  final FinesViewModel viewModel;
  const FinesProvider({
    Key? key,
    required this.viewModel,
    required Widget child,
  }) : super(key: key, child: child);
  static FinesProvider? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FinesProvider>();
  @override
  bool updateShouldNotify(FinesProvider oldWidget) =>
      viewModel != oldWidget.viewModel;
}
