import 'package:flutter/material.dart';

/// Responsive design utilities
class ResponsiveUtils {
  /// Determines whether the device is a tablet
  static bool isTablet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final diagonal = MediaQuery.of(context).size.shortestSide;
    
    // Uses the shortest side; an iPad typically has a shortest side over 600
    return diagonal >= 600;
  }
  
  /// Determines whether the device is a large tablet such as an iPad Pro
  static bool isLargeTablet(BuildContext context) {
    final diagonal = MediaQuery.of(context).size.shortestSide;
    return diagonal >= 800;
  }
  
  /// Determines whether the device is an extra-large tablet (such as a 13-inch iPad Pro)
  static bool isExtraLargeTablet(BuildContext context) {
    final diagonal = MediaQuery.of(context).size.shortestSide;
    return diagonal >= 1000;
  }
  
  /// Gets a responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    if (isExtraLargeTablet(context)) {
      return baseFontSize * 1.6; // A 13-inch iPad Pro uses larger fonts
    } else if (isLargeTablet(context)) {
      return baseFontSize * 1.4;
    } else if (isTablet(context)) {
      return baseFontSize * 1.2;
    }
    return baseFontSize;
  }
  
  /// Gets responsive spacing
  static double getResponsivePadding(BuildContext context, double basePadding) {
    if (isExtraLargeTablet(context)) {
      return basePadding * 2.0; // A 13-inch iPad Pro uses larger spacing
    } else if (isLargeTablet(context)) {
      return basePadding * 1.6;
    } else if (isTablet(context)) {
      return basePadding * 1.3;
    }
    return basePadding;
  }
  
  /// Gets responsive component dimensions
  static Size getResponsiveSize(BuildContext context, Size baseSize) {
    if (isExtraLargeTablet(context)) {
      return Size(baseSize.width * 1.8, baseSize.height * 1.8); // A 13-inch iPad Pro uses larger components
    } else if (isLargeTablet(context)) {
      return Size(baseSize.width * 1.5, baseSize.height * 1.5);
    } else if (isTablet(context)) {
      return Size(baseSize.width * 1.25, baseSize.height * 1.25);
    }
    return baseSize;
  }
  
  /// Gets a responsive container width ratio
  static double getResponsiveWidthRatio(BuildContext context, double baseRatio) {
    if (isTablet(context)) {
      // Reduce width on iPad to avoid over-wide content
      return (baseRatio * 0.75).clamp(0.5, 0.85);
    }
    return baseRatio;
  }
  
  /// Gets the responsive column count for a grid layout
  static int getResponsiveColumns(BuildContext context, int baseColumns) {
    if (isExtraLargeTablet(context)) {
      return baseColumns + 3; // A 13-inch iPad Pro can display more columns
    } else if (isLargeTablet(context)) {
      return baseColumns + 2;
    } else if (isTablet(context)) {
      return baseColumns + 1;
    }
    return baseColumns;
  }
  
  /// Gets responsive margins
  static EdgeInsets getResponsiveMargin(BuildContext context, EdgeInsets baseMargin) {
    final multiplier = isExtraLargeTablet(context) ? 2.0 : 
                     (isLargeTablet(context) ? 1.6 : 
                     (isTablet(context) ? 1.3 : 1.0));
    return EdgeInsets.only(
      left: baseMargin.left * multiplier,
      top: baseMargin.top * multiplier,
      right: baseMargin.right * multiplier,
      bottom: baseMargin.bottom * multiplier,
    );
  }
  
  /// Gets iPad-specific home page layout parameters
  static Map<String, double> getIPadHomeLayoutParams(BuildContext context) {
    if (isExtraLargeTablet(context)) {
      // Layout parameters for a 13-inch iPad Pro
      return {
        'titleTopPadding': 60.0,
        'titleToWaterGlassSpacing': 120.0,
        'waterGlassToSliderSpacing': 40.0,
        'horizontalPadding': 80.0,
        'navBarBottomPadding': 140.0,
      };
    } else if (isLargeTablet(context)) {
      // Layout parameters for a large tablet such as an 11-inch iPad Pro
      return {
        'titleTopPadding': 50.0,
        'titleToWaterGlassSpacing': 100.0,
        'waterGlassToSliderSpacing': 35.0,
        'horizontalPadding': 60.0,
        'navBarBottomPadding': 120.0,
      };
    } else if (isTablet(context)) {
      // Layout parameters for a standard iPad
      return {
        'titleTopPadding': 40.0,
        'titleToWaterGlassSpacing': 80.0,
        'waterGlassToSliderSpacing': 30.0,
        'horizontalPadding': 40.0,
        'navBarBottomPadding': 110.0,
      };
    }
    
    // Default parameters for phones (unchanged)
    return {
      'titleTopPadding': 30.0,
      'titleToWaterGlassSpacing': 69.0,
      'waterGlassToSliderSpacing': 14.0,
      'horizontalPadding': 20.0,
      'navBarBottomPadding': 100.0,
    };
  }
} 