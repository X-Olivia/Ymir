import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

/// 颜色滑动条组件 - 支持拖拽移动交互
class ColorSliderWidget extends StatefulWidget {
  final List<Color> colors;
  final int currentIndex;
  final Color currentColor;
  final ValueChanged<int> onColorChanged;
  final double maxDownwardOffset; // 最大向下偏移量
  final double maxUpwardOffset; // 最大向上偏移量
  final ValueChanged<double>? onOffsetChanged; // 偏移变化回调

  const ColorSliderWidget({
    super.key,
    required this.colors,
    required this.currentIndex,
    required this.currentColor,
    required this.onColorChanged,
    this.maxDownwardOffset = 100.0, // 默认最大向下偏移100像素
    this.maxUpwardOffset = 100.0, // 默认最大向上偏移100像素
    this.onOffsetChanged, // 偏移变化回调
  });

  @override
  State<ColorSliderWidget> createState() => _ColorSliderWidgetState();
}

class _ColorSliderWidgetState extends State<ColorSliderWidget>
    with TickerProviderStateMixin {
  // 位置偏移动画控制器
  late AnimationController _offsetController;
  late Animation<Offset> _offsetAnimation;
  
  // 当前偏移量
  Offset _currentOffset = Offset.zero;
  
  // 是否处于拖拽移动模式
  bool _isDragMode = false;
  
  // 拖拽起始位置
  double _dragStartY = 0.0;
  
  // 是否正在拖拽
  bool _isPointerDown = false;
  
  @override
  void initState() {
    super.initState();
    
    // 初始化偏移动画控制器
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
      // 在动画过程中也通知偏移变化
      widget.onOffsetChanged?.call(_offsetAnimation.value.dy);
    });
  }
  
  @override
  void dispose() {
    _offsetController.dispose();
    super.dispose();
  }
  
  // 处理指针按下
  void _handlePointerDown(PointerDownEvent event) {
    _isPointerDown = true;
    _dragStartY = event.position.dy;
    
    // 在最底部（蓝色，index=0）或最顶部（粉色，index=4）时才允许进入拖拽模式
    if (widget.currentIndex == 0 || widget.currentIndex == 4) {
      _isDragMode = false; // 初始不是拖拽模式，需要继续拖拽才进入
    }
  }
  
  // 处理指针移动
  void _handlePointerMove(PointerMoveEvent event) {
    if (!_isPointerDown) return;
    
    final currentY = event.position.dy;
    final deltaY = currentY - _dragStartY;
    
    // 降低进入拖拽模式的阈值，提高真机响应性
    // 如果在最底部且向下拖拽，或在最顶部且向上拖拽，进入拖拽移动模式
    if ((widget.currentIndex == 0 && deltaY > 10) ||  // 从20降低到10像素
        (widget.currentIndex == 4 && deltaY < -10)) { // 从-20提高到-10像素
      if (!_isDragMode) {
        _isDragMode = true;
        _dragStartY = currentY; // 重置起始位置
      }
    }
    
    if (_isDragMode) {
      // 计算新的偏移量 - 提高灵敏度
      final newOffsetY = _currentOffset.dy + event.delta.dy;
      
      // 限制偏移范围
      double clampedOffsetY;
      if (widget.currentIndex == 0) {
        // 底部：只能向下移动，不能向上移动
        clampedOffsetY = newOffsetY.clamp(0.0, widget.maxDownwardOffset);
      } else {
        // 顶部：只能向上移动，不能向下移动
        clampedOffsetY = newOffsetY.clamp(-widget.maxUpwardOffset, 0.0);
      }
      
      setState(() {
        _currentOffset = Offset(0, clampedOffsetY);
      });
      
      // 通知偏移变化
      widget.onOffsetChanged?.call(clampedOffsetY);
    }
  }
  
  // 处理指针抬起
  void _handlePointerUp(PointerUpEvent event) {
    _isPointerDown = false;
    
    if (_isDragMode) {
      _isDragMode = false;
      
      // 执行回弹动画
      _offsetAnimation = Tween<Offset>(
        begin: _currentOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _offsetController,
        curve: Curves.elasticOut,
      ));
      
      _offsetController.reset();
      _offsetController.forward();
      
      // 通知偏移重置
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
            height: 200, // 设置竖直滑动条的高度
            child: RotatedBox(
              quarterTurns: 3, // 旋转270度使滑动条竖直
              child: AbsorbPointer(
                absorbing: _isDragMode, // 在拖拽移动模式下完全阻止Slider接收触摸事件
                child: Slider(
                  value: widget.currentIndex.toDouble(),
                  min: 0,
                  max: (widget.colors.length - 1).toDouble(),
                  divisions: widget.colors.length - 1,
                  onChanged: (value) {
                    // 正常颜色选择
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

// 自定义滑块形状，用于显示当前颜色
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

    // 绘制外圈
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // 绘制滑块填充
    final Paint fillPaint = Paint()
      ..color = colors[currentIndex]
      ..style = PaintingStyle.fill;

    // 绘制滑块
    canvas.drawCircle(center, thumbRadius, fillPaint);
    canvas.drawCircle(center, thumbRadius, borderPaint);
  }
}

// 自定义滑动条轨道形状，支持渐变色
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

    // 创建圆角矩形
    final RRect trackRRect = RRect.fromRectAndRadius(
      trackRect,
      radius,
    );

    // 使用渐变色填充
    final Paint paint = Paint()
      ..shader = gradient.createShader(trackRect)
      ..style = PaintingStyle.fill;

    // 绘制轨道
    context.canvas.drawRRect(trackRRect, paint);
  }
} 