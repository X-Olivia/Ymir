import 'package:flutter/material.dart';

/// 响应式设计工具类
class ResponsiveUtils {
  /// 判断是否为平板设备
  static bool isTablet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final diagonal = MediaQuery.of(context).size.shortestSide;
    
    // 使用最短边判断，iPad通常最短边 > 600
    return diagonal >= 600;
  }
  
  /// 判断是否为iPad Pro等大屏平板
  static bool isLargeTablet(BuildContext context) {
    final diagonal = MediaQuery.of(context).size.shortestSide;
    return diagonal >= 800;
  }
  
  /// 判断是否为超大屏平板（如13英寸iPad Pro）
  static bool isExtraLargeTablet(BuildContext context) {
    final diagonal = MediaQuery.of(context).size.shortestSide;
    return diagonal >= 1000;
  }
  
  /// 获取响应式字体大小
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    if (isExtraLargeTablet(context)) {
      return baseFontSize * 1.6; // 13英寸iPad Pro使用更大的字体
    } else if (isLargeTablet(context)) {
      return baseFontSize * 1.4;
    } else if (isTablet(context)) {
      return baseFontSize * 1.2;
    }
    return baseFontSize;
  }
  
  /// 获取响应式间距
  static double getResponsivePadding(BuildContext context, double basePadding) {
    if (isExtraLargeTablet(context)) {
      return basePadding * 2.0; // 13英寸iPad Pro使用更大的间距
    } else if (isLargeTablet(context)) {
      return basePadding * 1.6;
    } else if (isTablet(context)) {
      return basePadding * 1.3;
    }
    return basePadding;
  }
  
  /// 获取响应式组件尺寸
  static Size getResponsiveSize(BuildContext context, Size baseSize) {
    if (isExtraLargeTablet(context)) {
      return Size(baseSize.width * 1.8, baseSize.height * 1.8); // 13英寸iPad Pro使用更大的组件
    } else if (isLargeTablet(context)) {
      return Size(baseSize.width * 1.5, baseSize.height * 1.5);
    } else if (isTablet(context)) {
      return Size(baseSize.width * 1.25, baseSize.height * 1.25);
    }
    return baseSize;
  }
  
  /// 获取响应式容器宽度比例
  static double getResponsiveWidthRatio(BuildContext context, double baseRatio) {
    if (isTablet(context)) {
      // iPad上减少宽度比例，避免内容过宽
      return (baseRatio * 0.75).clamp(0.5, 0.85);
    }
    return baseRatio;
  }
  
  /// 获取响应式列数（用于网格布局）
  static int getResponsiveColumns(BuildContext context, int baseColumns) {
    if (isExtraLargeTablet(context)) {
      return baseColumns + 3; // 13英寸iPad Pro可以显示更多列
    } else if (isLargeTablet(context)) {
      return baseColumns + 2;
    } else if (isTablet(context)) {
      return baseColumns + 1;
    }
    return baseColumns;
  }
  
  /// 获取响应式边距
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
  
  /// 获取iPad专用的主页面布局参数
  static Map<String, double> getIPadHomeLayoutParams(BuildContext context) {
    if (isExtraLargeTablet(context)) {
      // 13英寸iPad Pro的布局参数
      return {
        'titleTopPadding': 60.0,
        'titleToWaterGlassSpacing': 120.0,
        'waterGlassToSliderSpacing': 40.0,
        'horizontalPadding': 80.0,
        'navBarBottomPadding': 140.0,
      };
    } else if (isLargeTablet(context)) {
      // 11英寸iPad Pro等大屏平板的布局参数
      return {
        'titleTopPadding': 50.0,
        'titleToWaterGlassSpacing': 100.0,
        'waterGlassToSliderSpacing': 35.0,
        'horizontalPadding': 60.0,
        'navBarBottomPadding': 120.0,
      };
    } else if (isTablet(context)) {
      // 普通iPad的布局参数
      return {
        'titleTopPadding': 40.0,
        'titleToWaterGlassSpacing': 80.0,
        'waterGlassToSliderSpacing': 30.0,
        'horizontalPadding': 40.0,
        'navBarBottomPadding': 110.0,
      };
    }
    
    // 手机设备的默认参数（保持不变）
    return {
      'titleTopPadding': 30.0,
      'titleToWaterGlassSpacing': 69.0,
      'waterGlassToSliderSpacing': 14.0,
      'horizontalPadding': 20.0,
      'navBarBottomPadding': 100.0,
    };
  }
} 