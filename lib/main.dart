import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';

// 导入所有页面
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'screens/image_post_page.dart';
import 'screens/caption_suggest_page.dart';
import 'screens/post_view_page.dart';
import 'screens/post_view_wrapper.dart';
import 'screens/user_settings_page.dart';
import 'screens/ai_character_select_page.dart';
import 'screens/chat_page.dart';

// 导入服务和模型
import 'services/draft_service.dart';
import 'services/notes_service.dart';
import 'models/post_model.dart';
import 'models/draft_model.dart';
import 'models/chat_model.dart';
import 'services/greeting_service.dart';
import 'services/background_comment_service.dart';
import 'services/chat_service.dart';

// 全局导航键
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 全局主屏幕状态键
final GlobalKey<MainScreenState> mainScreenKey = GlobalKey<MainScreenState>();

// 主题管理
class ThemeProvider extends ChangeNotifier {
  Color _themeColor = Colors.blue;

  Color get themeColor => _themeColor;

  void setThemeColor(Color color) {
    _themeColor = color;
    notifyListeners();
  }
}

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 Hive
  await Hive.initFlutter();
  
  // 注册适配器
  Hive.registerAdapter(DraftModelAdapter());
  
  // 初始化草稿服务
  await DraftService.init();
  
  await GreetingService.init();
  
  // 初始化聊天服务
  await ChatService.init();
  
  // 启动时修复图片路径
  await NotesService.fixAllNotesImagePaths();
  await DraftService.fixAllDraftImagePaths();
  
  // 后台评论服务已简化，不需要初始化
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YMIR',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        // 使用毛玻璃风格的主题
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        // 设置AppBar样式
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white.withOpacity(0.8),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        // 设置按钮样式
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.withOpacity(0.9),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // 卡片主题 - 修复类型错误
        cardTheme: CardThemeData(
          color: Colors.white.withOpacity(0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        // 输入框主题
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 1),
          ),
        ),
        // 底部导航栏主题
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white.withOpacity(0.8),
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
        ),
      ),
      // 定义路由
      initialRoute: '/',  // 恢复初始路由
      routes: {
        '/': (context) => const SplashScreen(),
        '/main': (context) => MainScreen(key: mainScreenKey),
        '/image_post': (context) => const ImagePostPage(),
        '/caption_suggest': (context) => const CaptionSuggestPage(),
        '/settings': (context) {
          final Color? themeColor = ModalRoute.of(context)?.settings.arguments as Color?;
          return UserSettingsPage(
            themeColor: themeColor,
            onNavigateToPost: (post) {
              // 使用PostViewWrapper提供内嵌导航栏的帖子详情页面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostViewWrapper(
                    postData: post,
                    themeColor: themeColor,
                  ),
                ),
              );
            },
            onNavigateToDraft: (draft, isCaptionDraft) {
              // 返回到主屏幕并导航到草稿编辑页面
              Navigator.popUntil(context, ModalRoute.withName('/main'));
              
              // 通过全局键调用主屏幕的草稿导航方法
              Future.delayed(const Duration(milliseconds: 100), () {
                mainScreenKey.currentState?.navigateToDraft(draft.id, isCaptionDraft);
              });
            },
          );
        },
        '/ai_select': (context) => const AICharacterSelectPage(),
      },
      onGenerateRoute: (settings) {
        // 处理带参数的路由
        if (settings.name == '/post_view') {
          final args = settings.arguments;
          return MaterialPageRoute(
            builder: (context) => PostViewPage(
              postData: args is PostModel ? args : null,
            ),
          );
        }
        return null;
      },
    );
  }
}

// 自定义毛玻璃容器组件，可在应用中多处使用
class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final BoxBorder? border;
  final Color backgroundColor;
  
  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.blur = 10,
    this.borderRadius = 16,
    this.border,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
