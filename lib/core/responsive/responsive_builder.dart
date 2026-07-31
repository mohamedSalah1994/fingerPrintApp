import 'package:flutter/material.dart';
import 'package:fingerprint_app/core/responsive/breakpoints.dart';

enum ScreenType { mobile, tablet, desktop }

ScreenType screenTypeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (AppBreakpoints.isMobile(width)) return ScreenType.mobile;
  if (AppBreakpoints.isTablet(width)) return ScreenType.tablet;
  return ScreenType.desktop;
}

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    switch (screenTypeOf(context)) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}
