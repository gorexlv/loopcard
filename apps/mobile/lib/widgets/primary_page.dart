import 'package:flutter/material.dart';

import 'app_page.dart';
import 'app_layout.dart';

/// The same branded frame is used before and after authentication.
class PrimaryPage extends StatelessWidget {
  const PrimaryPage({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => AppPage(
    branded: true,
    // AppPage already reserves its standard bottom gap.
    bottomClearance: AppLayout.dockHeight,
    child: child,
  );
}
