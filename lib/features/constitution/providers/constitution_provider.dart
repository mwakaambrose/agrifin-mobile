import 'package:flutter/material.dart';
import '../viewmodels/constitution_viewmodel.dart';
import '../data/constitution_repository.dart';

class ConstitutionProvider extends InheritedWidget {
  final ConstitutionViewModel viewModel;
  ConstitutionProvider._({
    Key? key,
    required this.viewModel,
    required Widget child,
  }) : super(key: key, child: child);

  factory ConstitutionProvider({Key? key, required Widget child}) {
    final repo = ConstitutionRepository();
    final vm = ConstitutionViewModel(repo);
    return ConstitutionProvider._(key: key, viewModel: vm, child: child);
  }

  static ConstitutionViewModel of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ConstitutionProvider>()!
          .viewModel;

  @override
  bool updateShouldNotify(ConstitutionProvider oldWidget) =>
      viewModel != oldWidget.viewModel;
}
