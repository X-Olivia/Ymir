import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

/// Color slider with drag-to-move interaction
class ColorSliderWidget extends StatefulWidget {
  final List<Color> colors;
  final int currentIndex;
  final Color currentColor;
  final ValueChanged<int> onColorChanged;
  final double maxDownwardOffset; // Maximum downward offset
  final double maxUpwardOffset; // Maximum upward offset
  final ValueChanged<double>? onOffsetChanged; // Offset change callback

  const ColorSliderWidget({
    super.key,
    required this.colors,
    required this.currentIndex,
    required this.currentColor,
    required this.onColorChanged,
    this.maxDownwardOffset = 100.0, // Defaults to a 100-pixel downward offset
    this.maxUpwardOffset = 100.0, // Defaults to a 100-pixel upward offset
    this.onOffsetChanged, // Offset change callback
  });

  @override
  State<ColorSliderWidget> createState() => _ColorSliderWidgetState();
}

class _ColorSliderWidgetState extends State<ColorSliderWidget>
    with TickerProviderStateMixin {
  // Position offset animation controller
  late AnimationController _offsetController;
  late Animation<Offset> _offsetAnimation;
  
  // Current Offset
  Offset _currentOffset = Offset.zero;
  
  // Whether drag-to-move mode is active
  bool _isDragMode = false;
  
  // Drag start position
  double _dragStartY = 0.0;
  
  // Whether the pointer is down
  bool _isPointerDown = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initializes the offset animation controller
    _offsetController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _offsetController,
      curve: Curves.elasticOut,
    ));
    
    _offsetAnimation.addListener(() {
      setState(() {
        _currentOffset = _offsetAnimation.value;
      });
      // Reports offset changes during the animation
      widget.onOffsetChanged?.call(_offsetAnimation.value.dy);
    });
  }
  
  @override
  void dispose() {
    _offsetController.dispose();
    super.dispose();
  }
  
  // Handles pointer down
  void _handlePointerDown(PointerDownEvent event) {
    _isPointerDown = true;
    _dragStartY = event.position.dy;
    
    // Allows drag mode only at the bottom (blue, index 0) or top (pink, index 4)
    if (widget.currentIndex == 0 || widget.currentIndex == 4) {
      _isDragMode = false; // Further dragging is required to enter drag mode
    }
  }
  
  // Handles pointer movement
  void _handlePointerMove(PointerMoveEvent event) {
    if (!_isPointerDown) return;
    
    final currentY = event.position.dy;
    final deltaY = currentY - _dragStartY;
    
    // Lowers the drag-mode threshold for better responsiveness on physical devices
    // Enters drag mode when pulling down at the bottom or up at the top
    if ((widget.currentIndex == 0 && deltaY > 10) ||  // From 20 to 10 pixels.
        (widget.currentIndex == 4 && deltaY < -10)) { // Changed from -20 to -10 pixels
      if (!_isDragMode) {
        _isDragMode = true;
        _dragStartY = currentY; // Reset Start Location
      }
    }
    
    if (_isDragMode) {
      // Calculates the new offset with increased sensitivity
      final newOffsetY = _currentOffset.dy + event.delta.dy;
      
      // Clamps the offset
      double clampedOffsetY;
      if (widget.currentIndex == 0) {
        // Bottom: only move down, not up
        clampedOffsetY = newOffsetY.clamp(0.0, widget.maxDownwardOffset);
      } else {
        // Top: Only move up, not down
        clampedOffsetY = newOffsetY.clamp(-widget.maxUpwardOffset, 0.0);
      }
      
      setState(() {
        _currentOffset = Offset(0, clampedOffsetY);
      });
      
      // Reports the offset change
      widget.onOffsetChanged?.call(clampedOffsetY);
    }
  }
  
  // Handles pointer up
  void _handlePointerUp(PointerUpEvent event) {
    _isPointerDown = false;
    
    if (_isDragMode) {
      _isDragMode = false;
      
      // Runs the spring-back animation
      _offsetAnimation = Tween<Offset>(
        begin: _currentOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _offsetController,
        curve: Curves.elasticOut,
      ));
      
      _offsetController.reset();
      _offsetController.forward();
      
      // Reports that the offset has reset
      widget.onOffsetChanged?.call(0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      behavior: HitTestBehavior.translucent,
      child: Transform.translate(
        offset: _currentOffset,
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: widget.currentColor.withOpacity(0.8),
            inactiveTrackColor: widget.currentColor.withOpacity(0.3),
            thumbColor: widget.currentColor,
            thumbShape: _CustomSliderThumbShape(
              thumbRadius: 12,
              colors: widget.colors,
              currentIndex: widget.currentIndex,
            ),
            overlayColor: widget.currentColor.withOpacity(0.2),
            trackHeight: 30,
          ),
          child: SizedBox(
            height: 200, // Set the height of the vertical slider
            child: RotatedBox(
              quarterTurns: 3, // Rotating 270 degrees to keep the slide straight.
              child: AbsorbPointer(
                absorbing: _isDragMode, // Stop S Lider completely from receiving touch events in drag-and-drop mode
                child: Slider(
                  value: widget.currentIndex.toDouble(),
                  min: 0,
                  max: (widget.colors.length - 1).toDouble(),
                  divisions: widget.colors.length - 1,
                  onChanged: (value) {
                    // Normal Colour Selection
                    widget.onColorChanged(value.toInt());
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Customize slider shapes for displaying current colours
class _CustomSliderThumbShape extends SliderComponentShape {
  final double thumbRadius;
  final List<Color> colors;
  final int currentIndex;

  const _CustomSliderThumbShape({
    required this.thumbRadius,
    required this.colors,
    required this.currentIndex,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Draw the outer circle
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Draw slider fill
    final Paint fillPaint = Paint()
      ..color = colors[currentIndex]
      ..style = PaintingStyle.fill;

    // Draw sliders
    canvas.drawCircle(center, thumbRadius, fillPaint);
    canvas.drawCircle(center, thumbRadius, borderPaint);
  }
}

// Custom slider track shape with gradient support
class _GradientRectSliderTrackShape extends SliderTrackShape {
  final LinearGradient gradient;
  final Radius radius;

  const _GradientRectSliderTrackShape({
    required this.gradient,
    this.radius = const Radius.circular(15),
  });

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 8;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    if (sliderTheme.trackHeight == 0) {
      return;
    }

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    // Create a circular rectangle
    final RRect trackRRect = RRect.fromRectAndRadius(
      trackRect,
      radius,
    );

    // Fill with Gradient Colour
    final Paint paint = Paint()
      ..shader = gradient.createShader(trackRect)
      ..style = PaintingStyle.fill;

    // Draw Tracks
    context.canvas.drawRRect(trackRRect, paint);
  }
} 