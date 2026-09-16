import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Glass water cup color display component
class WaterGlassWidget extends StatefulWidget {
  final Animation<double> waveAnimation;
  final Animation<double> colorChangeAnimation;
  final Color themeColor;
  final Size size;

  const WaterGlassWidget({
    super.key,
    required this.waveAnimation,
    required this.colorChangeAnimation,
    required this.themeColor,
    this.size = const Size(300, 300),
  });

  @override
  State<WaterGlassWidget> createState() => _WaterGlassWidgetState();
}

class _WaterGlassWidgetState extends State<WaterGlassWidget>
    with TickerProviderStateMixin {
  
  // Ripple animation controller
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;
  
  // Ripple-related state
  List<RippleEffect> _ripples = [];
  
  @override
  void initState() {
    super.initState();
    
    // Initializes the ripple animation controller
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _rippleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
  }
  
  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }
  
  // Handles tap events
  void _handleTap(TapDownDetails details) {
    final center = Offset(widget.size.width / 2, widget.size.height / 2);
    final radius = widget.size.width / 2 - 6; // Water radius
    final tapPosition = details.localPosition;
    
    // Checks whether the tap is inside the water
    final distance = (tapPosition - center).distance;
    if (distance <= radius) {
      // Add new ripple effect
      final ripple = RippleEffect(
        center: tapPosition,
        startTime: DateTime.now(),
        maxRadius: radius,
      );
      
      setState(() {
        _ripples.add(ripple);
      });
      
      // Removes expired ripples
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _ripples.removeWhere((r) => r == ripple);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          widget.waveAnimation, 
          widget.colorChangeAnimation,
          _rippleAnimation,
        ]),
        builder: (context, child) {
          return CustomPaint(
            size: widget.size,
            painter: WaterGlassPainter(
              waveProgress: widget.waveAnimation.value,
              colorChangeProgress: widget.colorChangeAnimation.value,
              glassColor: widget.themeColor,
              waterColor: widget.themeColor,
              ripples: _ripples,
            ),
          );
        },
      ),
    );
  }
}

/// Ripple effect data
class RippleEffect {
  final Offset center;
  final DateTime startTime;
  final double maxRadius;
  
  RippleEffect({
    required this.center,
    required this.startTime,
    required this.maxRadius,
  });
  
  // Get current animation progress (0.0 - 1.0)
  double get progress {
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    final progress = elapsed / 1500.0; // 1.5 seconds of animation
    return math.min(1.0, math.max(0.0, progress));
  }
  
  // Gets the current ripple radius
  double get currentRadius {
    return maxRadius * progress;
  }
  
  // Get current intensity (for distortion effects)
  double get strength {
    // Use a bell curve with maximum intensity in the middle
    final t = progress;
    return math.exp(-math.pow(t - 0.3, 2) / 0.1) * 0.8;
  }
}

/// Custom painter for the glass cup and animated water surface
class WaterGlassPainter extends CustomPainter {
  final double waveProgress;
  final double colorChangeProgress;
  final Color glassColor;
  final Color waterColor;
  final List<RippleEffect> ripples;

  WaterGlassPainter({
    required this.waveProgress,
    required this.colorChangeProgress,
    required this.glassColor,
    required this.waterColor,
    required this.ripples,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw glass container shell
    _drawGlassContainer(canvas, center, radius);
    
    // Draws the water surface and wave effects, including distortion
    _drawWaterWithDistortion(canvas, center, radius);
    
    // Draw ripple effects
    _drawRippleEffect(canvas, center, radius);
    
    // Draws interactive ripples
    _drawInteractiveRipples(canvas, center, radius);
    
    // Draw glass highlight effect
    _drawGlassHighlight(canvas, center, radius);
  }

  void _drawGlassContainer(Canvas canvas, Offset center, double radius) {
    // Border of the glass container
    final glassBorderPaint = Paint()
      ..color = glassColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    // Background of glass containers (transparent)
    final glassBackgroundPaint = Paint()
      ..color = glassColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    // Draw glass containers
    canvas.drawCircle(center, radius - 2, glassBackgroundPaint);
    canvas.drawCircle(center, radius - 2, glassBorderPaint);
  }

  void _drawWaterWithDistortion(Canvas canvas, Offset center, double radius) {
    // Water filling area
    final waterLevel = 0.7; // Water level height (70%)
    final waterRadius = radius - 6;
    
    // Creates the water path
    final waterPath = Path();
    
    // Calculates wave parameters for a seamless loop
    final waveAmplitude = 8.0 * (1.0 + colorChangeProgress * 2.0); // Increase wave bands when colour changes
    final waveFrequency = 2.0; // Reduce frequency and smoother waves.
    final waveOffset = waveProgress * 2 * math.pi; // Ensures a complete 2π cycle
    
    // Baseline height of surface
    final waterSurfaceY = center.dy + (1 - waterLevel) * waterRadius;
    
    // Draw wave shape water surface
    final wavePoints = <Offset>[];
    final stepSize = 1.0; // Reduce step length and increase smoothness
    
    for (double x = center.dx - waterRadius; x <= center.dx + waterRadius; x += stepSize) {
      final relativeX = (x - center.dx) / waterRadius;
      if (relativeX * relativeX <= 1) { // Make sure it's within the circle.
        // Use a single sine wave to ensure a perfect cycle
        var waveY = waterSurfaceY + 
            waveAmplitude * math.sin(waveFrequency * math.pi * relativeX + waveOffset);
        
        // Apply ripple effect
        final currentPoint = Offset(x, waveY);
        final distortedPoint = _applyRippleDistortion(currentPoint, center, waterRadius);
        
        wavePoints.add(distortedPoint);
      }
    }
    
    // Builds the water path
    if (wavePoints.isNotEmpty) {
      waterPath.moveTo(wavePoints.first.dx, wavePoints.first.dy);
      
      // Connects points with cubic Bézier curves for smoother waves
      for (int i = 1; i < wavePoints.length; i++) {
        if (i < wavePoints.length - 1) {
          final current = wavePoints[i];
          final next = wavePoints[i + 1];
          final controlPoint1 = Offset(
            current.dx + (next.dx - current.dx) * 0.3,
            current.dy,
          );
          final controlPoint2 = Offset(
            current.dx + (next.dx - current.dx) * 0.7,
            next.dy,
          );
          waterPath.cubicTo(
            controlPoint1.dx, controlPoint1.dy,
            controlPoint2.dx, controlPoint2.dy,
            next.dx, next.dy,
          );
        } else {
          waterPath.lineTo(wavePoints[i].dx, wavePoints[i].dy);
        }
      }
      
      // Connect to the bottom of the container to form a closed path
      waterPath.lineTo(center.dx + waterRadius, center.dy + waterRadius);
      waterPath.lineTo(center.dx - waterRadius, center.dy + waterRadius);
      waterPath.close();
    }
    
    // The area where the water is cut is round
    canvas.save();
    final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: waterRadius));
    canvas.clipPath(clipPath);
    
    // Draw water gradients
    final waterGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        waterColor.withOpacity(0.6),
        waterColor.withOpacity(0.9),
      ],
    );
    
    final waterPaint = Paint()
      ..shader = waterGradient.createShader(
        Rect.fromCircle(center: center, radius: waterRadius),
      );
    
    canvas.drawPath(waterPath, waterPaint);
    
    // Draw surface reflection - also use smooth connections
    final reflectionPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Draw smooth lines
    if (wavePoints.length > 1) {
      final reflectionPath = Path();
      reflectionPath.moveTo(wavePoints.first.dx, wavePoints.first.dy);
      
      for (int i = 1; i < wavePoints.length; i++) {
        if (i < wavePoints.length - 1) {
          final current = wavePoints[i];
          final next = wavePoints[i + 1];
          final controlPoint1 = Offset(
            current.dx + (next.dx - current.dx) * 0.3,
            current.dy,
          );
          final controlPoint2 = Offset(
            current.dx + (next.dx - current.dx) * 0.7,
            next.dy,
          );
          reflectionPath.cubicTo(
            controlPoint1.dx, controlPoint1.dy,
            controlPoint2.dx, controlPoint2.dy,
            next.dx, next.dy,
          );
        } else {
          reflectionPath.lineTo(wavePoints[i].dx, wavePoints[i].dy);
        }
      }
      
      canvas.drawPath(reflectionPath, reflectionPaint);
    }
    
    canvas.restore();
  }

  // Apply ripple effect
  Offset _applyRippleDistortion(Offset point, Offset center, double waterRadius) {
    var distortedPoint = point;
    
    for (final ripple in ripples) {
      final distance = (point - ripple.center).distance;
      final rippleRadius = ripple.currentRadius;
      
      // The ripple effect continues to spread without border restrictions
      if (distance < rippleRadius + 20 && ripple.strength > 0.01) {
        // Calculating the degree of distortion, the closer it gets to the center, the greater it gets.
        final normalizedDistance = distance / (rippleRadius + 20);
        final distortionStrength = ripple.strength * (1.0 - normalizedDistance);
        
        if (distortionStrength > 0) {
          // Calculates radial offset
          final direction = (point - ripple.center).direction;
          final radialOffset = math.sin(distance * 0.1 - ripple.progress * 6) * 
                              distortionStrength * 15.0;
          
          // Calculates tangential offset for a rotational effect
          final tangentialDirection = direction + math.pi / 2;
          final tangentialOffset = math.cos(distance * 0.08 - ripple.progress * 8) * 
                                  distortionStrength * 8.0;
          
          // Application of distortion - no limits on boundaries, natural transmission of effects
          distortedPoint = Offset(
            distortedPoint.dx + math.cos(direction) * radialOffset + 
                               math.cos(tangentialDirection) * tangentialOffset,
            distortedPoint.dy + math.sin(direction) * radialOffset + 
                               math.sin(tangentialDirection) * tangentialOffset,
          );
        }
      }
    }
    
    return distortedPoint;
  }

  void _drawRippleEffect(Canvas canvas, Offset center, double radius) {
    // Draw multiple ripple circles - ensure a consistent cycle
    final rippleCount = 3; // Number of ripples displayed simultaneously
    final baseRadius = radius - 2; // Base radius (glass container size)
    
    for (int i = 0; i < rippleCount; i++) {
      // Calculating the delay and progress of each ripple - ensuring a perfect cycle
      final delay = i / rippleCount;
      final rippleProgress = (waveProgress + delay) % 1.0;
      
      // Expands the ripple from the base radius to 1.5 times its size using easing
      final easedProgress = _easeInOut(rippleProgress);
      final rippleRadius = baseRadius + (baseRadius * 0.5 * easedProgress);
      
      // Transparency: gradual reduction from 0.6 to 0, use of smooth transition
      final opacity = (1.0 - easedProgress) * 0.6;
      
      if (opacity > 0) {
        final ripplePaint = Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        
        canvas.drawCircle(center, rippleRadius, ripplePaint);
      }
    }
  }

  // Draws interactive ripples
  void _drawInteractiveRipples(Canvas canvas, Offset center, double radius) {
    final waterRadius = radius - 6; // Real water radius
    
    // Clips the ripple drawing area to the circular water surface
    canvas.save();
    final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: waterRadius));
    canvas.clipPath(clipPath);
    
    for (final ripple in ripples) {
      if (ripple.progress < 1.0) {
        // The ripple continues spreading without boundary constraints
        final rippleRadius = ripple.currentRadius;
        final opacity = (1.0 - ripple.progress) * 0.8;
        
        // Main ripple, clipped automatically by clipPath
        final ripplePaint = Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        
        canvas.drawCircle(ripple.center, rippleRadius, ripplePaint);
        
        // Secondary ripple, smaller and thinner
        final secondaryRadius = rippleRadius * 0.6;
        final secondaryPaint = Paint()
          ..color = Colors.white.withOpacity(opacity * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        
        canvas.drawCircle(ripple.center, secondaryRadius, secondaryPaint);
      }
    }
    
    canvas.restore();
  }

  // Smooth slow motion function to ensure zero speed at start and end
  double _easeInOut(double t) {
    return t * t * (3.0 - 2.0 * t);
  }

  void _drawGlassHighlight(Canvas canvas, Offset center, double radius) {
    // Glass Highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Top Left High Arc
    final highlightPath = Path();
    highlightPath.addArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      -2.5, // Start angle
      1.0,  // arc long
    );
    
    canvas.drawPath(highlightPath, highlightPaint);
    
    // Additional flash effect when colour changes
    if (colorChangeProgress > 0) {
      final flashPaint = Paint()
        ..color = glassColor.withOpacity(0.6 * colorChangeProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;
      
      canvas.drawCircle(center, radius - 2, flashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WaterGlassPainter oldDelegate) {
    return waveProgress != oldDelegate.waveProgress ||
           colorChangeProgress != oldDelegate.colorChangeProgress ||
           glassColor != oldDelegate.glassColor ||
           waterColor != oldDelegate.waterColor ||
           ripples != oldDelegate.ripples;
  }
} 