/// Page-level geometry. Features must not duplicate viewport or dock offsets.
abstract final class AppLayout {
  static const double tabletBreakpoint = 600;
  static const double maxContentWidth = 920;
  static const double brandTop = 58;
  static const double headerGap = 24;
  static const double dockHeight = 72;
  static const double bottomGap = 16;

  static double horizontalPadding(double viewportWidth) =>
      viewportWidth >= tabletBreakpoint ? 48 : 32;
}
