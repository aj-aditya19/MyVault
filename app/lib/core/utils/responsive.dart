import 'package:flutter/material.dart';

/// The three layout classes MyVault adapts to.
enum DeviceType { mobile, tablet, desktop }

/// Centralized breakpoints + helpers so every screen agrees on what counts
/// as mobile / tablet / desktop, instead of each widget guessing its own
/// width cutoffs.
class Responsive {
  Responsive._();

  static const double tabletBreakpoint = 700;
  static const double desktopBreakpoint = 1100;

  static DeviceType deviceTypeOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktopBreakpoint) return DeviceType.desktop;
    if (width >= tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  static bool isMobile(BuildContext context) =>
      deviceTypeOf(context) == DeviceType.mobile;

  static bool isTablet(BuildContext context) =>
      deviceTypeOf(context) == DeviceType.tablet;

  static bool isDesktop(BuildContext context) =>
      deviceTypeOf(context) == DeviceType.desktop;

  /// How many columns a stat/quick-action grid should use at this width.
  static int gridColumns(BuildContext context) {
    switch (deviceTypeOf(context)) {
      case DeviceType.mobile:
        return 2;
      case DeviceType.tablet:
        return 3;
      case DeviceType.desktop:
        return 4;
    }
  }

  /// Caps how wide page content grows on very large / desktop screens so
  /// text and cards don't stretch edge-to-edge forever.
  static double maxContentWidth(BuildContext context) {
    switch (deviceTypeOf(context)) {
      case DeviceType.mobile:
        return double.infinity;
      case DeviceType.tablet:
        return 980;
      case DeviceType.desktop:
        return 1280;
    }
  }

  /// Whether the primary navigation should render as a side rail instead
  /// of a bottom bar.
  static bool useSideNav(BuildContext context) =>
      deviceTypeOf(context) != DeviceType.mobile;
}

/// Wraps [child] in a centered, width-capped container - drop this around
/// any screen body to make it behave well on tablet/desktop without
/// touching the screen's internal layout code.
class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = Responsive.maxContentWidth(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
