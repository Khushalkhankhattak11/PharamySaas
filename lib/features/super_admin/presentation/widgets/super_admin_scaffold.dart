import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_scaffold.dart';

class SuperAdminScaffold extends StatelessWidget {
  final Widget child;

  const SuperAdminScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(child: child);
  }
}
