import 'dart:async';

class PostInteractionService {
  // 点赞增长相关
  Timer? _likeGrowthTimer;
  bool _isLikeGrowthActive = false;
  
  // 回调函数
  Function(int)? _onLikeCountChanged;

  PostInteractionService({
    Function(int)? onLikeCountChanged,
  }) {
    _onLikeCountChanged = onLikeCountChanged;
  }

  // 启动交互功能
  void startInteractiveFeatures() {
    startLikeGrowth();
  }

  // 启动点赞数量增长
  void startLikeGrowth({int currentLikeCount = 42}) {
    if (_isLikeGrowthActive) return;
    
    _isLikeGrowthActive = true;
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    final targetLikeCount = currentLikeCount + 30 + (random % 70); // 30-99的增长
    
    // 5分钟内缓慢增长
    const totalDuration = Duration(minutes: 5);
    const updateInterval = Duration(seconds: 10); // 每10秒更新一次
    final totalUpdates = totalDuration.inSeconds ~/ updateInterval.inSeconds;
    final incrementPerUpdate = (targetLikeCount - currentLikeCount) / totalUpdates;
    
    int updateCount = 0;
    
    _likeGrowthTimer = Timer.periodic(updateInterval, (timer) {
      updateCount++;
      final newLikeCount = currentLikeCount + (incrementPerUpdate * updateCount).round();
      
      if (updateCount >= totalUpdates || newLikeCount >= targetLikeCount) {
        _onLikeCountChanged?.call(targetLikeCount);
        timer.cancel();
        _isLikeGrowthActive = false;
      } else {
        _onLikeCountChanged?.call(newLikeCount);
      }
    });
  }

  // 格式化时间戳
  static String formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else {
      return '${difference.inDays}天前';
    }
  }

  // 停止所有交互功能
  void stopInteractiveFeatures() {
    _likeGrowthTimer?.cancel();
    _isLikeGrowthActive = false;
  }

  // 检查是否正在进行点赞增长
  bool get isLikeGrowthActive => _isLikeGrowthActive;

  // 清理资源
  void dispose() {
    stopInteractiveFeatures();
  }
} 