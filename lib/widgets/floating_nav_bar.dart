import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;
import '../utils/responsive_utils.dart';

/// 浮动导航栏组件，支持双状态交互（预选和激活）
class FloatingNavBar extends StatelessWidget {
  final int activeIndex;     // 当前激活的页面索引
  final int selectedIndex;   // 当前视觉高亮的索引
  final Function(int) onTap;
  final Color themeColor;
  
  const FloatingNavBar({
    super.key,
    required this.activeIndex,
    required this.selectedIndex,
    required this.onTap,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    // 获取响应式参数
    final responsivePadding = ResponsiveUtils.getResponsivePadding(context, 24);
    final navBarHeight = ResponsiveUtils.isExtraLargeTablet(context) ? 140.0 : 
                        (ResponsiveUtils.isLargeTablet(context) ? 130.0 : 
                        (ResponsiveUtils.isTablet(context) ? 120.0 : 100.0));
    final iconSize = ResponsiveUtils.isExtraLargeTablet(context) ? 32.0 : 
                    (ResponsiveUtils.isLargeTablet(context) ? 30.0 : 
                    (ResponsiveUtils.isTablet(context) ? 28.0 : 24.0));
    final fontSize = ResponsiveUtils.getResponsiveFontSize(context, 14);
    
    // SECTION: 导航栏容器布局参数
    return Padding(
      // 外边距 - 调整导航栏与屏幕边缘的距离
      padding: EdgeInsets.only(
        bottom: responsivePadding, 
        left: responsivePadding, 
        right: responsivePadding
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 底层带圆角的容器
          Positioned.fill(
            child: ClipPath(
              clipper: NavBarNotchClipper(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: navBarHeight,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // 导航项布局
          Container(
            height: navBarHeight,
            child: Row(
              // 布局方式 - 控制导航项的水平分布
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 导航项配置 - 修改图标路径和标签文字
                _buildNavItem(context, 0, 'assets/images/Icon/home-alt.svg', '首页', iconSize, fontSize),
                _buildNavItem(context, 1, 'assets/images/Icon/image-select.svg', '图片', iconSize, fontSize),
                _buildNavItem(context, 2, 'assets/images/Icon/message-text.svg', '文案', iconSize, fontSize),
                _buildNavItem(context, 3, 'assets/images/Icon/ai-select.svg', '好友', iconSize, fontSize),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建单个导航项
  /// [index] 导航项索引
  /// [iconPath] SVG图标路径
  /// [label] 导航项标签文字
  /// [iconSize] 图标尺寸
  /// [fontSize] 字体大小
  Widget _buildNavItem(BuildContext context, int index, String iconPath, String label, double iconSize, double fontSize) {
    // 导航项状态
    final isSelected = selectedIndex == index;  // 是否为视觉选中状态
    final isActive = activeIndex == index;      // 是否为实际激活状态
    
    // 响应式容器尺寸 - 针对不同iPad尺寸优化
    final selectedWidth = ResponsiveUtils.isExtraLargeTablet(context) ? 160.0 : 
                         (ResponsiveUtils.isLargeTablet(context) ? 145.0 : 
                         (ResponsiveUtils.isTablet(context) ? 130.0 : 110.0));
    final unselectedWidth = ResponsiveUtils.isExtraLargeTablet(context) ? 90.0 : 
                           (ResponsiveUtils.isLargeTablet(context) ? 80.0 : 
                           (ResponsiveUtils.isTablet(context) ? 70.0 : 60.0));
    final containerHeight = ResponsiveUtils.isExtraLargeTablet(context) ? 100.0 : 
                           (ResponsiveUtils.isLargeTablet(context) ? 90.0 : 
                           (ResponsiveUtils.isTablet(context) ? 80.0 : 70.0));
    
    return GestureDetector(
      onTap: () => onTap(index),
      // 根据选中状态决定是使用横向布局（Row）还是纵向布局（Column）
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        // 容器宽度 - 选中时宽度更大以容纳文字
        width: isSelected ? selectedWidth : unselectedWidth, 
        height: isSelected ? containerHeight : unselectedWidth,
        // 椭圆形边框
        decoration: BoxDecoration(
          // 容器形状 - 圆角矩形（椭圆形效果）
          borderRadius: BorderRadius.circular(50),
          // 背景颜色 - 调整选中和未选中状态的背景色
          color: isSelected ? themeColor : themeColor.withOpacity(0.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标
            SvgPicture.asset(
              iconPath,
              width: iconSize,
              height: iconSize,
              colorFilter: ColorFilter.mode(
                isSelected ? Colors.white : themeColor,
                BlendMode.srcIn,
              ),
            ),
            // 文字标签 - 使用AnimatedSize来处理文字显示过渡
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              // 延迟显示文字，确保容器已经展开
              child: isSelected
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 图标和文字之间的间距
                        SizedBox(width: ResponsiveUtils.isExtraLargeTablet(context) ? 12 : 
                                       (ResponsiveUtils.isLargeTablet(context) ? 11 : 
                                       (ResponsiveUtils.isTablet(context) ? 10 : 8))),
                        // 文字标签
                        AnimatedOpacity(
                          // 设置稍长一点的延迟，确保容器已完全展开
                          duration: const Duration(milliseconds: 350),
                          // 延迟展开后再显示文字
                          curve: const Interval(0.4, 1.0),
                          opacity: isSelected ? 1.0 : 0.0,
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 仅用于创建顶部小圆切口的裁剪器
class NavBarNotchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // 创建路径
    final path = Path();
    
    // 定义缺口参数
    final width = size.width;
    final height = size.height;
    final notchRadius = 40.0; // 缺口半径
    final notchDepth = 5.0;  // 缺口深度
    
    // 使用矩形填充整个区域
    path.addRect(Rect.fromLTWH(0, 0, width, height));
    
    // 绘制缺口 - 使用二次贝塞尔曲线创建平缓的缺口
    final notchCenter = width / 2;
    final notchStart = notchCenter - notchRadius;
    final notchEnd = notchCenter + notchRadius;
    
    // 控制缺口高度的参数
    final controlPointOffset = 15.0;
    
    // 创建切口路径
    final notchPath = Path();
    notchPath.moveTo(notchStart, 0);
    notchPath.quadraticBezierTo(
      notchCenter, notchDepth + controlPointOffset,
      notchEnd, 0
    );
    notchPath.lineTo(notchStart, 0);
    notchPath.close();
    
    // 从主路径中减去切口路径
    final result = Path.combine(PathOperation.difference, path, notchPath);
    
    return result;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
} 