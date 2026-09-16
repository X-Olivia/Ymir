import 'dart:async';

class PostInteractionService {
  // Like growth related
  Timer? _likeGrowthTimer;
  bool _isLikeGrowthActive = false;
  
  // callback function
  Function(int)? _onLikeCountChanged;

  PostInteractionService({
    Function(int)? onLikeCountChanged,
  }) {
    _onLikeCountChanged = onLikeCountChanged;
  }

  // Start interactive features
  void startInteractiveFeatures() {
    startLikeGrowth();
  }

  // Start growing the number of likes
  void startLikeGrowth({int currentLikeCount = 42}) {
    if (_isLikeGrowthActive) return;
    
    _isLikeGrowthActive = true;
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    final targetLikeCount = currentLikeCount + 30 + (random % 70); // Increase by 30–99 likes
    
    // Increase gradually over five minutes
    const totalDuration = Duration(minutes: 5);
    const updateInterval = Duration(seconds: 10); // Update every 10 seconds
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

  // Format timestamp
  static String formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  // Stop all interactive functions
  void stopInteractiveFeatures() {
    _likeGrowthTimer?.cancel();
    _isLikeGrowthActive = false;
  }

  // Check if likes growth is taking place
  bool get isLikeGrowthActive => _isLikeGrowthActive;

  // Clean up resources
  void dispose() {
    stopInteractiveFeatures();
  }
} 