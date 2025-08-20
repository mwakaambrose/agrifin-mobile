import 'package:flutter/material.dart';
import '../viewmodels/loan_viewmodel.dart';

class LoanProvider extends InheritedWidget {
  final LoanViewModel viewModel;
  const LoanProvider({Key? key, required this.viewModel, required Widget child})
    : super(key: key, child: child);
  static LoanProvider? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LoanProvider>();
  @override
  bool updateShouldNotify(LoanProvider oldWidget) =>
      viewModel != oldWidget.viewModel;
}
