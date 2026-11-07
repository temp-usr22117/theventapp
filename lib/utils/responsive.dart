import 'package:flutter/material.dart';

/// Helper utility for responsive breakpoints across Web, Tablet, and Mobile.
class Responsive {
  static const double mobileMaxWidth = 768.0;
  static const double tabletMaxWidth = 1024.0;
  static const double feedMaxWidth = 700.0;
  static const double authMaxWidth = 440.0;
  static const double modalMaxWidth = 600.0;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletMaxWidth;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileMaxWidth && width < tabletMaxWidth;
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMaxWidth;

  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileMaxWidth;
}
