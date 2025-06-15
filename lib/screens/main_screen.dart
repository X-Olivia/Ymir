import 'package:flutter/material.dart';
import 'dart:ui';
import '../widgets/floating_nav_bar.dart';
import '../widgets/water_glass_widget.dart';
import '../widgets/color_slider_widget.dart';
import 'image_post_page.dart';
import 'caption_suggest_page.dart';
import 'ai_character_select_page.dart';
import 'post_view_page.dart'; // 导入PostViewPage
import '../services/draft_service.dart';
import '../models/post_model.dart'; // 导入PostModel
import '../services/greeting_service.dart';
import '../services/background_comment_service.dart';
import '../services/user_service.dart'; // 添加UserService导入
import 'chat_page.dart';
import '../utils/responsive_utils.dart'; // 添加响应式工具类导入

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  // 主题颜色选择，默认为蓝色
  Color _themeColor = const Color(0xFF2463b3);
  
  // 当前选中的导航项（视觉高亮）
  int _selectedIndex = 0;
  
  // 当前激活的页面
  int _activeIndex = 0;
  
  // ImagePostPage 的 GlobalKey，用于调用其方法
  final GlobalKey<ImagePostPageState> _imagePostPageKey = GlobalKey<ImagePostPageState>();
  
  // CaptionSuggestPage 的 GlobalKey，用于调用其方法
  final GlobalKey<CaptionSuggestPageState> _captionSuggestPageKey = GlobalKey<CaptionSuggestPageState>();
  
  // AICharacterSelectPage 的 GlobalKey，用于调用其方法
  final GlobalKey<AICharacterSelectPageState> _aiCharacterSelectPageKey = GlobalKey<AICharacterSelectPageState>();
  
  // PostViewPage 的 GlobalKey，用于调用其方法
  final GlobalKey<PostViewPageState> _postViewPageKey = GlobalKey<PostViewPageState>();
  
  // 可选的主题颜色
  final List<Color> _themeColors = [
    const Color(0xFF2463b3), // 蓝色
    const Color(0xFFa18dc1), // 紫色
    const Color(0xFF8bb179), // 绿色
    const Color(0xFFfbb93b), // 黄色
    const Color(0xFFfeabcd), // 粉色
  ];
  
  // 当前颜色索引
  int _colorIndex = 0;
  
  // 帖子数据，用于PostViewPage
  PostModel? _currentPostData;
  
  // 草稿导航相关
  String? _draftIdToLoad; // 要加载的草稿ID
  bool _isDraftNavigation = false; // 是否是从草稿箱导航过来的
  
  // 水波动画控制器
  late AnimationController _waveController;
  late AnimationController _colorChangeController;
  late Animation<double> _waveAnimation;
  late Animation<double> _colorChangeAnimation;
  
  // 颜色球击球效果动画控制器
  late AnimationController _ballBounceController;
  late Animation<Offset> _ballBounceAnimation;
  
  // 滑动条偏移量（用于碰撞检测）
  double _sliderOffset = 0.0;
  
  // 颜色球是否正在被拖拽
  bool _isBallBeingDragged = false;
  
  // 颜色球当前偏移量
  Offset _ballCurrentOffset = Offset.zero;
  
  @override
  void initState() {
    super.initState();
    
    // 检查是否需要显示问候
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // [DEBUG] 清除所有问候记录，方便调试
      await GreetingService.clearAllGreetingRecords();
      _checkDailyGreeting();
    });
    
    // 初始化动画控制器
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _colorChangeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // 颜色球击球动画控制器
    _ballBounceController = AnimationController(
      duration: const Duration(milliseconds: 1000), // 减少持续时间让弹起更快
      vsync: this,
    );
    
    _waveAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_waveController);
    
    _colorChangeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _colorChangeController,
      curve: Curves.elasticOut,
    ));
    
    _ballBounceAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ballBounceController,
      curve: Curves.elasticOut,
    ));
    
    // 初始化页面列表 - 首页内容不直接放入页面列表，单独处理
    // 移除静态页面列表，改为动态创建
  }

  // 检查并显示每日问候
  Future<void> _checkDailyGreeting() async {
    print('🔍 检查每日问候...');
    print('问候功能是否启用: ${GreetingService.isGreetingEnabled()}');
    print('是否应该显示问候: ${GreetingService.shouldShowGreetingNow()}');
    
    if (GreetingService.shouldShowGreetingNow()) {
      // 获取用户昵称
      final userNickname = await UserService.getNickname();
      
      await showDialog(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Stack(
            children: [
              // 磨砂玻璃背景
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 标题行
                        Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              color: _themeColor,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '每日问候',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // 问候内容
                        Text(
                          '今天你跟$userNickname说${GreetingService.getGreetingMessage()}了吗？',
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // 提示文字
                        Text(
                          '在设置 > 隐私设置中关闭每日问候',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // 按钮行
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                '稍后再说',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                await GreetingService.markGreetingShown();
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _themeColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('说啦'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // 左上角反光效果
              Positioned(
                left: 0,
                top: 0,
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                    ),
                    child: Container(
                      width: 150,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: const [0.0, 0.3, 1.0],
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.05),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // 右下角反光效果
              Positioned(
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(20),
                    ),
                    child: Container(
                      width: 120,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomRight,
                          end: Alignment.topLeft,
                          stops: const [0.0, 0.3, 1.0],
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.03),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      print('❌ 不需要显示问候');
    }
  }

  // 动态获取页面，确保主题色能够实时更新
  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return Container(); // 首页占位符，实际不会使用
      case 1:
        return ImagePostPage(
          key: _imagePostPageKey,
          themeColor: _themeColor,
          draftId: _isDraftNavigation ? _draftIdToLoad : null, // 传递草稿ID
          onBack: () {
            // 返回到主页面状态
            setState(() {
              _activeIndex = 0;
              _selectedIndex = 0;
              _clearDraftNavigation(); // 清除草稿导航状态
            });
          },
          onPostPublished: (postData) {
            // 发布帖子后显示帖子详情页面
            _clearDraftNavigation(); // 清除草稿导航状态
            showPostView(postData, isNewlyPublished: true);
          },
        );
      case 2:
        return CaptionSuggestPage(
          key: _captionSuggestPageKey,
          themeColor: _themeColor,
          draftId: _isDraftNavigation ? _draftIdToLoad : null, // 传递草稿ID
          onBack: () {
            // 返回到主页面状态
            setState(() {
              _activeIndex = 0;
              _selectedIndex = 0;
              _clearDraftNavigation(); // 清除草稿导航状态
            });
          },
          onPostPublished: (postData) {
            // 发布帖子后显示帖子详情页面
            _clearDraftNavigation(); // 清除草稿导航状态
            showPostView(postData, isNewlyPublished: true);
          },
        );
      case 3:
        return AICharacterSelectPage(
          key: _aiCharacterSelectPageKey, 
          themeColor: _themeColor,
        );
      case 4: // 添加PostViewPage
        return PostViewPage(
          key: _postViewPageKey,
          postData: _currentPostData,
          themeColor: _themeColor,
          onBack: () {
            // 从发布后进入的，返回到主页面
            setState(() {
              _activeIndex = 0;
              _selectedIndex = 0;
              _currentPostData = null; // 清空帖子数据
            });
          },
        );
      default:
        return Container();
    }
  }

  // 根据颜色索引获取背景图片路径
  String _getBackgroundImagePath() {
    switch (_colorIndex) {
      case 0:
        return 'assets/images/back/blue.png';
      case 1:
        return 'assets/images/back/purple.png';
      case 2:
        return 'assets/images/back/green.png';
      case 3:
        return 'assets/images/back/orange.png';
      case 4:
        return 'assets/images/back/pink.png';
      default:
        return 'assets/images/back/blue.png';
    }
  }

  // 处理返回按键
  Future<bool> _handleBackButton() async {
    // 如果当前在帖子详情页面
    if (_activeIndex == 4) {
      // 从发布后进入的，返回到主页面
      setState(() {
        _activeIndex = 0;
        _selectedIndex = 0;
        _currentPostData = null; // 清空帖子数据
      });
      return false; // 阻止默认返回行为
    }
    
    // 如果当前在AI选择页面
    if (_activeIndex == 3) {
      final aiCharacterSelectPageState = _aiCharacterSelectPageKey.currentState;
      if (aiCharacterSelectPageState != null) {
        // 检查是否有选中的AI好友
        if (!aiCharacterSelectPageState.hasSelectedFriends()) {
          // 没有选中任何好友，显示提示
          _showSelectFriendsDialog();
          return false; // 阻止返回
        }
      }
      
      // 有选中的好友，允许返回到主页面
      setState(() {
        _activeIndex = 0;
        _selectedIndex = 0;
      });
      return false; // 阻止默认返回行为
    }
    
    // 如果当前在图片发布页面
    if (_activeIndex == 1) {
      final imagePostPageState = _imagePostPageKey.currentState;
      if (imagePostPageState != null) {
        // 检查内容是否为空
        final isEmpty = imagePostPageState.isContentEmpty();
        
        if (isEmpty) {
          // 内容为空，直接清空草稿箱并返回
          await DraftService.clearAllDrafts();
          setState(() {
            _activeIndex = 0;
            _selectedIndex = 0;
          });
          return false; // 阻止默认返回行为
        } else {
          // 内容不为空，询问是否保存
          final shouldSave = await _showSaveConfirmDialog();
          
          if (shouldSave == true) {
            // 用户选择保存
            await imagePostPageState.saveDraftSilently();
          } else if (shouldSave == false) {
            // 用户选择不保存，清空草稿箱
            await DraftService.clearAllDrafts();
          }
          // 如果用户取消（shouldSave == null），则不返回
          
          if (shouldSave != null) {
            setState(() {
              _activeIndex = 0;
              _selectedIndex = 0;
            });
          }
          
          return false; // 阻止默认返回行为
        }
      }
    }

    // 如果当前在文案页面
    if (_activeIndex == 2) {
      final captionSuggestPageState = _captionSuggestPageKey.currentState;
      if (captionSuggestPageState != null) {
        // 检查内容是否为空
        final isEmpty = captionSuggestPageState.isContentEmpty();
        
        if (isEmpty) {
          // 内容为空，直接清空草稿箱并返回
          await DraftService.clearAllCaptionDrafts();
          setState(() {
            _activeIndex = 0;
            _selectedIndex = 0;
          });
          return false; // 阻止默认返回行为
        } else {
          // 内容不为空，询问是否保存
          final shouldSave = await _showSaveConfirmDialog();
          
          if (shouldSave == true) {
            // 用户选择保存
            await captionSuggestPageState.saveDraftSilently();
          } else if (shouldSave == false) {
            // 用户选择不保存，清空草稿箱
            await DraftService.clearAllCaptionDrafts();
          }
          // 如果用户取消（shouldSave == null），则不返回
          
          if (shouldSave != null) {
            setState(() {
              _activeIndex = 0;
              _selectedIndex = 0;
            });
          }
          
          return false; // 阻止默认返回行为
        }
      }
    }
    
    // 其他情况允许正常返回
    return true;
  }

  // 显示保存确认对话框
  Future<bool?> _showSaveConfirmDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '是否保存草稿？',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '检测到您有未保存的内容，是否保存到草稿箱？',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text(
              '取消',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '不保存',
              style: TextStyle(color: _themeColor, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _themeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '保存',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // 显示选择AI好友提示对话框
  void _showSelectFriendsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '请选择AI好友',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '至少需要选择一个AI好友才能继续使用，请返回选择页面进行选择。',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _themeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '知道了',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // 显示帖子详情页面
  void showPostView(PostModel postData, {bool isNewlyPublished = false}) async {
    // 先立即跳转到帖子详情页面
    setState(() {
      _currentPostData = postData;
      _activeIndex = 4;
      _selectedIndex = 4;
    });
    
    // 如果是新发布的帖子，异步启动AI评论生成（不阻塞页面跳转）
    if (isNewlyPublished) {
      print('🚀 新发布的帖子，异步启动AI评论生成任务');
      // 使用unawaited来异步执行，不阻塞当前方法
      BackgroundCommentService.startCommentGeneration(postData).catchError((error) {
        print('❌ AI评论生成任务启动失败: $error');
      });
    }
  }

  // 处理草稿导航 - 从草稿箱导航到编辑页面
  void navigateToDraft(String draftId, bool isCaptionDraft) {
    setState(() {
      _draftIdToLoad = draftId;
      _isDraftNavigation = true;
      if (isCaptionDraft) {
        _activeIndex = 2; // 文案建议页面
        _selectedIndex = 2;
      } else {
        _activeIndex = 1; // 图片发布页面
        _selectedIndex = 1;
      }
    });
  }

  // 清除草稿导航状态
  void _clearDraftNavigation() {
    _draftIdToLoad = null;
    _isDraftNavigation = false;
  }

  @override
  void dispose() {
    _waveController.dispose();
    _colorChangeController.dispose();
    _ballBounceController.dispose();
    super.dispose();
  }

  // 处理滑动条偏移变化（用于碰撞检测）
  void _handleSliderOffsetChanged(double offset) {
    setState(() {
      _sliderOffset = offset;
    });
    
    // 碰撞检测：当滑动条向上移动且偏移量达到一定值时
    if (offset < -80) {
      // 进入拖拽模式，颜色球跟随滑动条移动
      if (!_isBallBeingDragged && !_ballBounceController.isAnimating) {
        _isBallBeingDragged = true;
      }
      
      // 颜色球跟随滑动条移动（但移动幅度稍小一些，营造被推动的感觉）
      if (_isBallBeingDragged) {
        final ballOffset = (offset + 80) * 0.6; // 颜色球移动幅度为滑动条的60%
        setState(() {
          _ballCurrentOffset = Offset(0, ballOffset);
        });
      }
    } else {
      // 滑动条回到安全区域，如果之前在拖拽状态，触发释放效果
      if (_isBallBeingDragged) {
        _triggerBallRelease();
        _isBallBeingDragged = false;
      }
    }
  }
  
  // 触发颜色球释放效果（惯性向上运动后回弹）
  void _triggerBallRelease() {
    // 从当前位置开始，继续向上惯性运动，然后回弹到原位
    final currentOffset = _ballCurrentOffset;
    final inertiaDistance = 40.0; // 惯性向上运动的距离
    
    _ballBounceAnimation = TweenSequence<Offset>([
      // 第一阶段：快速惯性向上运动
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: currentOffset,
          end: Offset(0, currentOffset.dy - inertiaDistance),
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 25, // 25% 的时间用于惯性向上
      ),
      // 第二阶段：弹性回落到原位
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(0, currentOffset.dy - inertiaDistance),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 75, // 75% 的时间用于回弹
      ),
    ]).animate(_ballBounceController);
    
    // 添加动画监听器，更新颜色球当前位置
    _ballBounceAnimation.addListener(() {
      setState(() {
        _ballCurrentOffset = _ballBounceAnimation.value;
      });
    });
    
    // 动画完成后重置状态
    _ballBounceController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _ballCurrentOffset = Offset.zero;
          _isBallBeingDragged = false;
        });
        _ballBounceController.removeStatusListener((status) {});
      }
    });
    
    _ballBounceController.reset();
    _ballBounceController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _handleBackButton();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        // 使用渐变背景
        body: Container(
          decoration: BoxDecoration(
            // 渐变背景
            image: DecorationImage(
              image: AssetImage(_getBackgroundImagePath()),
              fit: ResponsiveUtils.isExtraLargeTablet(context) 
                  ? BoxFit.cover // 13英寸iPad Pro使用cover以获得更大的背景
                  : BoxFit.cover,
              alignment: ResponsiveUtils.isExtraLargeTablet(context)
                  ? const Alignment(-0.5, -0.1) // 13英寸iPad Pro的背景对齐方式，稍微向右上偏移
                  : const Alignment(0.15, 0), // 其他设备保持原有偏移
              scale: ResponsiveUtils.isExtraLargeTablet(context) 
                  ? 0.8// 13英寸iPad Pro使用更小的scale值来放大背景
                  : 1.0, // 其他设备保持默认
            ),
          ),
          child: Stack(
            children: [
              // 磨砂玻璃效果层
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              // 原有内容
              SafeArea(
                child: Stack(
                  children: [
                    // 顶部导航按钮
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 聊天按钮
                          IconButton(
                            icon: Icon(
                              Icons.chat_bubble_outline,
                              size: 28,
                              color: _themeColor,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(themeColor: _themeColor),
                                ),
                              );
                            },
                          ),
                          // 设置按钮
                          IconButton(
                            icon: Icon(
                              Icons.settings,
                              size: 28,
                              color: _themeColor,
                            ),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/settings',
                                arguments: _themeColor,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // 页面内容 - 使用_activeIndex决定显示哪个页面
                    _activeIndex == 0 
                        ? _buildHomeContent() 
                        : Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              children: [
                                // 非主页时显示返回按钮
                                Padding(
                                  padding: const EdgeInsets.only(left: 16, top: 8),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.arrow_back_ios,
                                        color: _themeColor,
                                      ),
                                      onPressed: () async {
                                        await _handleBackButton();
                                      },
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _getPage(_activeIndex),
                                ),
                              ],
                            ),
                          ),
                    
                    // 底部导航栏
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Visibility(
                        // 只在主页面（_activeIndex为0）时显示导航栏
                        visible: _activeIndex == 0,
                        child: FloatingNavBar(
                          activeIndex: _activeIndex,
                          selectedIndex: _selectedIndex,
                          onTap: (index) {
                            // 确保索引在有效范围内 (4个导航页面: 0,1,2,3)
                            // PostViewPage (index 4) 不在导航栏中，只能通过发布帖子进入
                            if (index >= 4) return;
                            
                            if (_selectedIndex == index) {
                              // 再次点击同一个图标，触发页面跳转
                              setState(() {
                                _activeIndex = index;
                              });
                            } else {
                              // 第一次点击，只更新视觉状态
                              setState(() {
                                _selectedIndex = index;
                              });
                            }
                          },
                          themeColor: _themeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 主页内容
  Widget _buildHomeContent() {
    // 获取响应式参数
    final isTablet = ResponsiveUtils.isTablet(context);
    final titleFontSize = ResponsiveUtils.getResponsiveFontSize(context, 55);
    final responsivePadding = ResponsiveUtils.getResponsivePadding(context, 16);
    final waterGlassSize = ResponsiveUtils.getResponsiveSize(context, const Size(300, 300));
    
    // 获取iPad专用布局参数
    final layoutParams = ResponsiveUtils.getIPadHomeLayoutParams(context);
    
    return Padding(
      padding: EdgeInsets.fromLTRB(
        responsivePadding, 
        layoutParams['titleTopPadding']!, 
        responsivePadding, 
        layoutParams['navBarBottomPadding']!
      ), // 使用iPad专用的顶部和底部间距
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 标题文字 - 响应式字体大小
          Text(
            'YMIR',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              fontFamily: 'Library3AmSoft',
              color: _themeColor,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, 10)),
    
          SizedBox(height: layoutParams['titleToWaterGlassSpacing']!), // 使用iPad专用的标题到水杯间距
          
          // 滑动条颜色选择器
          Padding(
            padding: EdgeInsets.symmetric(horizontal: layoutParams['horizontalPadding']!), // 使用iPad专用的水平间距
            child: Column(
              children: [
                // 玻璃水杯颜色展示器 - 响应式尺寸
                Transform.translate(
                  offset: _ballCurrentOffset, // 直接使用当前偏移量
                  child: WaterGlassWidget(
                    waveAnimation: _waveAnimation,
                    colorChangeAnimation: _colorChangeAnimation,
                    themeColor: _themeColor,
                    size: waterGlassSize, // 使用响应式尺寸
                  ),
                ),
                SizedBox(height: layoutParams['waterGlassToSliderSpacing']!), // 使用iPad专用的水杯到滑动条间距
                
                // 离散滑动条 - 添加拖拽移动功能和碰撞检测
                LayoutBuilder(
                  builder: (context, constraints) {
                    // 计算最大偏移量（向上和向下都适用）
                    final screenHeight = MediaQuery.of(context).size.height;
                    final safeAreaTop = MediaQuery.of(context).padding.top;
                    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
                    final navBarHeight = layoutParams['navBarBottomPadding']!; // 使用iPad专用的导航栏高度
                    final safeMargin = ResponsiveUtils.getResponsivePadding(context, 20); // 响应式安全边距
                    
                    // 估算当前内容已使用的高度 - 使用iPad专用的布局参数
                    final usedHeight = layoutParams['titleTopPadding']! + // 顶部padding
                        titleFontSize + // 标题高度
                        ResponsiveUtils.getResponsivePadding(context, 10) + // 标题下方间距
                        layoutParams['titleToWaterGlassSpacing']! + // 标题到水杯间距
                        waterGlassSize.height + // 水杯高度
                        layoutParams['waterGlassToSliderSpacing']! + // 水杯和滑动条间距
                        200 + // 滑动条高度
                        100 + // 底部padding
                        safeAreaBottom;
                    
                    // 向下最大偏移量计算 - 针对iPad优化
                    // 计算剩余可用空间
                    final remainingSpace = screenHeight - usedHeight - navBarHeight - safeMargin;
                    
                    // iPad上允许更大的拖动距离，13英寸iPad Pro允许最大的拖动距离
                    final baseMaxDownOffset = ResponsiveUtils.isExtraLargeTablet(context) ? 180.0 : 
                                            (ResponsiveUtils.isLargeTablet(context) ? 150.0 : 
                                            (isTablet ? 120.0 : 80.0));
                    final minDownOffset = ResponsiveUtils.isExtraLargeTablet(context) ? 120.0 : 
                                        (ResponsiveUtils.isLargeTablet(context) ? 100.0 : 
                                        (isTablet ? 80.0 : 50.0));
                    
                    // 确保向下偏移量适应设备类型
                    final maxDownOffset = remainingSpace > 0 
                        ? remainingSpace.clamp(minDownOffset, baseMaxDownOffset)
                        : minDownOffset;
                    
                    // 向上最大偏移量（iPad上允许更大的击球距离）
                    final maxUpOffset = ResponsiveUtils.isExtraLargeTablet(context) ? 300.0 : 
                                      (ResponsiveUtils.isLargeTablet(context) ? 250.0 : 
                                      (isTablet ? 200.0 : 150.0));
                    
                    return ColorSliderWidget(
                      colors: _themeColors,
                      currentIndex: _colorIndex,
                      currentColor: _themeColor,
                      maxDownwardOffset: maxDownOffset,
                      maxUpwardOffset: maxUpOffset, // 添加独立的向上偏移量参数
                      onOffsetChanged: _handleSliderOffsetChanged, // 添加偏移变化回调
                      onColorChanged: (index) {
                        setState(() {
                          _colorIndex = index;
                          _themeColor = _themeColors[_colorIndex];
                          // 触发颜色变化动画
                          _colorChangeController.reset();
                          _colorChangeController.forward();
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 