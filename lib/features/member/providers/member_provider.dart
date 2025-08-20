import 'package:flutter/material.dart';
import '../viewmodels/member_viewmodel.dart';

class MemberProvider extends InheritedWidget {
  final MemberViewModel viewModel;
  const MemberProvider({
    Key? key,
    required this.viewModel,
    required Widget child,
  }) : super(key: key, child: child);
  static MemberProvider? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MemberProvider>();
  @override
  bool updateShouldNotify(MemberProvider oldWidget) =>
      viewModel != oldWidget.viewModel;
}
