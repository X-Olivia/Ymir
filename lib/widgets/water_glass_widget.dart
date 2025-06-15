import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 水杯玻璃颜色展示组件
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
  
  // 涟漪动画控制器
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;
  
  // 涟漪相关状态
  List<RippleEffect> _ripples = [];
  
  @override
  void initState() {
    super.initState();
    
    // 初始化涟漪动画控制器
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
  
  // 处理点击事件
  void _handleTap(TapDownDetails details) {
    final center = Offset(widget.size.width / 2, widget.size.height / 2);
    final radius = widget.size.width / 2 - 6; // 水的半径
    final tapPosition = details.localPosition;
    
    // 检查点击是否在水的区域内
    final distance = (tapPosition - center).distance;
    if (distance <= radius) {
      // 添加新的涟漪效果
      final ripple = RippleEffect(
        center: tapPosition,
        startTime: DateTime.now(),
        maxRadius: radius,
      );
      
      setState(() {
        _ripples.add(ripple);
      });
      
      // 清理过期的涟漪
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

/// 涟漪效果数据类
class RippleEffect {
  final Offset center;
  final DateTime startTime;
  final double maxRadius;
  
  RippleEffect({
    required this.center,
    required this.startTime,
    required this.maxRadius,
  });
  
  // 获取当前的动画进度 (0.0 - 1.0)
  double get progress {
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    final progress = elapsed / 1500.0; // 1.5秒动画时长
    return math.min(1.0, math.max(0.0, progress));
  }
  
  // 获取当前涟漪半径
  double get currentRadius {
    return maxRadius * progress;
  }
  
  // 获取当前强度 (用于扭曲效果)
  double get strength {
    // 使用钟形曲线，在中间时强度最大
    final t = progress;
    return math.exp(-math.pow(t - 0.3, 2) / 0.1) * 0.8;
  }
}

/// 绘制玻璃水杯和波动水面的自定义画笔
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
    
    // 绘制玻璃容器外壳
    _drawGlassContainer(canvas, center, radius);
    
    // 绘制水面和波动效果（包含扭曲效果）
    _drawWaterWithDistortion(canvas, center, radius);
    
    // 绘制波纹特效
    _drawRippleEffect(canvas, center, radius);
    
    // 绘制交互涟漪
    _drawInteractiveRipples(canvas, center, radius);
    
    // 绘制玻璃高光效果
    _drawGlassHighlight(canvas, center, radius);
  }

  void _drawGlassContainer(Canvas canvas, Offset center, double radius) {
    // 玻璃容器的边框
    final glassBorderPaint = Paint()
      ..color = glassColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    // 玻璃容器的背景（半透明）
    final glassBackgroundPaint = Paint()
      ..color = glassColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    // 绘制玻璃容器
    canvas.drawCircle(center, radius - 2, glassBackgroundPaint);
    canvas.drawCircle(center, radius - 2, glassBorderPaint);
  }

  void _drawWaterWithDistortion(Canvas canvas, Offset center, double radius) {
    // 水的填充区域
    final waterLevel = 0.7; // 水位高度（70%）
    final waterRadius = radius - 6;
    
    // 创建水的路径
    final waterPath = Path();
    
    // 计算波浪参数 - 修改为连贯循环
    final waveAmplitude = 8.0 * (1.0 + colorChangeProgress * 2.0); // 颜色变化时波幅增大
    final waveFrequency = 2.0; // 减少频率，让波浪更平滑
    final waveOffset = waveProgress * 2 * math.pi; // 确保2π周期完整循环
    
    // 水面的基准高度
    final waterSurfaceY = center.dy + (1 - waterLevel) * waterRadius;
    
    // 绘制波浪形状的水面
    final wavePoints = <Offset>[];
    final stepSize = 1.0; // 减小步长，增加平滑度
    
    for (double x = center.dx - waterRadius; x <= center.dx + waterRadius; x += stepSize) {
      final relativeX = (x - center.dx) / waterRadius;
      if (relativeX * relativeX <= 1) { // 确保在圆形范围内
        // 使用单一正弦波确保完美循环
        var waveY = waterSurfaceY + 
            waveAmplitude * math.sin(waveFrequency * math.pi * relativeX + waveOffset);
        
        // 应用涟漪扭曲效果
        final currentPoint = Offset(x, waveY);
        final distortedPoint = _applyRippleDistortion(currentPoint, center, waterRadius);
        
        wavePoints.add(distortedPoint);
      }
    }
    
    // 构建水的路径
    if (wavePoints.isNotEmpty) {
      waterPath.moveTo(wavePoints.first.dx, wavePoints.first.dy);
      
      // 使用三次贝塞尔曲线连接点，使波浪更平滑
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
      
      // 连接到容器底部形成闭合路径
      waterPath.lineTo(center.dx + waterRadius, center.dy + waterRadius);
      waterPath.lineTo(center.dx - waterRadius, center.dy + waterRadius);
      waterPath.close();
    }
    
    // 裁剪水的区域为圆形
    canvas.save();
    final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: waterRadius));
    canvas.clipPath(clipPath);
    
    // 绘制水的渐变效果
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
    
    // 绘制水面反射效果 - 也使用平滑连接
    final reflectionPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // 绘制平滑的反射线条
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

  // 应用涟漪扭曲效果
  Offset _applyRippleDistortion(Offset point, Offset center, double waterRadius) {
    var distortedPoint = point;
    
    for (final ripple in ripples) {
      final distance = (point - ripple.center).distance;
      final rippleRadius = ripple.currentRadius;
      
      // 涟漪扭曲效果继续传播，不受边界限制
      if (distance < rippleRadius + 20 && ripple.strength > 0.01) {
        // 计算扭曲强度，距离涟漪中心越近扭曲越强
        final normalizedDistance = distance / (rippleRadius + 20);
        final distortionStrength = ripple.strength * (1.0 - normalizedDistance);
        
        if (distortionStrength > 0) {
          // 计算径向偏移
          final direction = (point - ripple.center).direction;
          final radialOffset = math.sin(distance * 0.1 - ripple.progress * 6) * 
                              distortionStrength * 15.0;
          
          // 计算切向偏移（旋转效果）
          final tangentialDirection = direction + math.pi / 2;
          final tangentialOffset = math.cos(distance * 0.08 - ripple.progress * 8) * 
                                  distortionStrength * 8.0;
          
          // 应用扭曲 - 不限制边界，让效果自然传播
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
    // 绘制多个波纹圆圈 - 确保循环连贯
    final rippleCount = 3; // 同时显示的波纹数量
    final baseRadius = radius - 2; // 基础半径（玻璃容器大小）
    
    for (int i = 0; i < rippleCount; i++) {
      // 计算每个波纹的延迟和进度 - 确保完美循环
      final delay = i / rippleCount;
      final rippleProgress = (waveProgress + delay) % 1.0;
      
      // 波纹半径：从基础半径扩大到1.5倍，使用平滑的缓动函数
      final easedProgress = _easeInOut(rippleProgress);
      final rippleRadius = baseRadius + (baseRadius * 0.5 * easedProgress);
      
      // 透明度：从0.6逐渐减少到0，使用平滑的过渡
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

  // 绘制交互涟漪
  void _drawInteractiveRipples(Canvas canvas, Offset center, double radius) {
    final waterRadius = radius - 6; // 水的实际半径
    
    // 裁剪涟漪绘制区域为圆形水面
    canvas.save();
    final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: waterRadius));
    canvas.clipPath(clipPath);
    
    for (final ripple in ripples) {
      if (ripple.progress < 1.0) {
        // 涟漪继续扩散，不受边界限制
        final rippleRadius = ripple.currentRadius;
        final opacity = (1.0 - ripple.progress) * 0.8;
        
        // 主涟漪 - 完整绘制，由clipPath自动裁剪
        final ripplePaint = Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        
        canvas.drawCircle(ripple.center, rippleRadius, ripplePaint);
        
        // 次级涟漪（更小更细）
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

  // 平滑的缓动函数，确保开始和结束时速度为0
  double _easeInOut(double t) {
    return t * t * (3.0 - 2.0 * t);
  }

  void _drawGlassHighlight(Canvas canvas, Offset center, double radius) {
    // 玻璃高光效果
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // 左上角高光弧
    final highlightPath = Path();
    highlightPath.addArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      -2.5, // 起始角度
      1.0,  // 弧长
    );
    
    canvas.drawPath(highlightPath, highlightPaint);
    
    // 颜色变化时的额外闪光效果
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