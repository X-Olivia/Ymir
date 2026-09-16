import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;
import '../utils/responsive_utils.dart';

/// Floating navigation column components to support dual-state interaction (preselection and activation)
class FloatingNavBar extends StatelessWidget {
  final int activeIndex;     // Current Active Page Index
  final int selectedIndex;   // Current High Visual Index
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
    // Get Response Parameters
    final responsivePadding = ResponsiveUtils.getResponsivePadding(context, 24);
    final navBarHeight = ResponsiveUtils.isExtraLargeTablet(context) ? 140.0 : 
                        (ResponsiveUtils.isLargeTablet(context) ? 130.0 : 
                        (ResponsiveUtils.isTablet(context) ? 120.0 : 100.0));
    final iconSize = ResponsiveUtils.isExtraLargeTablet(context) ? 32.0 : 
                    (ResponsiveUtils.isLargeTablet(context) ? 30.0 : 
                    (ResponsiveUtils.isTablet(context) ? 28.0 : 24.0));
    final fontSize = ResponsiveUtils.getResponsiveFontSize(context, 14);
    
    // SECTION: Navigation column container layout parameters
    return Padding(
      // Margin - Adjust the distance between the navigation bar and the edge of the screen
      padding: EdgeInsets.only(
        bottom: responsivePadding, 
        left: responsivePadding, 
        right: responsivePadding
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Base container with rounded corners
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
          
          // Navigation Item Layout
          Container(
            height: navBarHeight,
            child: Row(
              // Layout - Control the horizontal distribution of navigation items
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Navigation Item Configuration - Modify Icon Path and Tab Text
                _buildNavItem(context, 0, 'assets/images/Icon/home-alt.svg', 'Home', iconSize, fontSize),
                _buildNavItem(context, 1, 'assets/images/Icon/image-select.svg', 'Images', iconSize, fontSize),
                _buildNavItem(context, 2, 'assets/images/Icon/message-text.svg', 'Captions', iconSize, fontSize),
                _buildNavItem(context, 3, 'assets/images/Icon/ai-select.svg', 'Friends', iconSize, fontSize),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build Single Navigator
  /// [index] Navigator index
  /// [iconPath] SVG icon path
  /// [label] Navigation entry label text
  /// [iconSize] Icon Size
  /// [fontSize] Font size
  Widget _buildNavItem(BuildContext context, int index, String iconPath, String label, double iconSize, double fontSize) {
    // Navigator Status
    final isSelected = selectedIndex == index;  // Whether to select the visual status
    final isActive = activeIndex == index;      // Whether or not to be actually activated
    
    // Responsive container size optimized for different iPad sizes
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
      // Whether to use a horizontal layout (Row) or a vertical layout (Column) according to the selected status
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        // Container width expands to fit the label when selected
        width: isSelected ? selectedWidth : unselectedWidth, 
        height: isSelected ? containerHeight : unselectedWidth,
        // Ellipse Border
        decoration: BoxDecoration(
          // Container shape - rounded rectangles (ellipse effect)
          borderRadius: BorderRadius.circular(50),
          // Background Colour - Adjusts the background of the selected and unselected status Colour
          color: isSelected ? themeColor : themeColor.withOpacity(0.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            SvgPicture.asset(
              iconPath,
              width: iconSize,
              height: iconSize,
              colorFilter: ColorFilter.mode(
                isSelected ? Colors.white : themeColor,
                BlendMode.srcIn,
              ),
            ),
            // Text Label - Use AnimatedSize to process text to show transition
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              // Delay displaying text to make sure the container is active
              child: isSelected
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Space between icons and text
                        SizedBox(width: ResponsiveUtils.isExtraLargeTablet(context) ? 12 : 
                                       (ResponsiveUtils.isLargeTablet(context) ? 11 : 
                                       (ResponsiveUtils.isTablet(context) ? 10 : 8))),
                        // Text Label
                        AnimatedOpacity(
                          // Set a slightly longer delay to ensure that the container is fully expanded
                          duration: const Duration(milliseconds: 350),
                          // Show text after delay in expanding
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

/// Clipper used only to create the small circular notch at the top
class NavBarNotchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // Create Path
    final path = Path();
    
    // Define gap parameters
    final width = size.width;
    final height = size.height;
    final notchRadius = 40.0; // Gap Radius
    final notchDepth = 5.0;  // Gap depth
    
    // Use a rectangle to fill the entire area
    path.addRect(Rect.fromLTWH(0, 0, width, height));
    
    // Draw a gap - Create a flat gap using a secondary Bézier curve
    final notchCenter = width / 2;
    final notchStart = notchCenter - notchRadius;
    final notchEnd = notchCenter + notchRadius;
    
    // Parameters to control the height of the gap
    final controlPointOffset = 15.0;
    
    // Create a cut path
    final notchPath = Path();
    notchPath.moveTo(notchStart, 0);
    notchPath.quadraticBezierTo(
      notchCenter, notchDepth + controlPointOffset,
      notchEnd, 0
    );
    notchPath.lineTo(notchStart, 0);
    notchPath.close();
    
    // Deleting the cut path from the main path
    final result = Path.combine(PathOperation.difference, path, notchPath);
    
    return result;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
} 