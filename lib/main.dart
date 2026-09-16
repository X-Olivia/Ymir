import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';

// Imports all pages
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'screens/image_post_page.dart';
import 'screens/caption_suggest_page.dart';
import 'screens/post_view_page.dart';
import 'screens/post_view_wrapper.dart';
import 'screens/user_settings_page.dart';
import 'screens/ai_character_select_page.dart';
import 'screens/chat_page.dart';

// Imports services and models
import 'services/draft_service.dart';
import 'services/notes_service.dart';
import 'models/post_model.dart';
import 'models/draft_model.dart';
import 'models/chat_model.dart';
import 'services/greeting_service.dart';
import 'services/background_comment_service.dart';
import 'services/chat_service.dart';

// Global navigation key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global main screen state key
final GlobalKey<MainScreenState> mainScreenKey = GlobalKey<MainScreenState>();

// Theme management
class ThemeProvider extends ChangeNotifier {
  Color _themeColor = Colors.blue;

  Color get themeColor => _themeColor;

  void setThemeColor(Color color) {
    _themeColor = color;
    notifyListeners();
  }
}

void main() async {
  // Ensures Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initializes Hive
  await Hive.initFlutter();
  
  // Registers adapters
  Hive.registerAdapter(DraftModelAdapter());
  
  // Initializes the draft service
  await DraftService.init();
  
  await GreetingService.init();
  
  // Initializes the chat service
  await ChatService.init();
  
  // Repairs image paths at startup
  await NotesService.fixAllNotesImagePaths();
  await DraftService.fixAllDraftImagePaths();
  
  // The background comment service has been simplified and requires no initialization
  
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
        // Uses a frosted-glass theme
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        // Configures the AppBar style
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
        // Configures the button style
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
        // Card theme - fixes a type error
        cardTheme: CardThemeData(
          color: Colors.white.withOpacity(0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        // Input field theme
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
        // Bottom navigation bar theme
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white.withOpacity(0.8),
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
        ),
      ),
      // Defines routes
      initialRoute: '/',  // Restores the initial route
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
              // Uses PostViewWrapper for a post details page with an embedded navigation bar
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
              // Returns to the main screen and opens the draft editor
              Navigator.popUntil(context, ModalRoute.withName('/main'));
              
              // Calls the main screen's draft navigation method through the global key
              Future.delayed(const Duration(milliseconds: 100), () {
                mainScreenKey.currentState?.navigateToDraft(draft.id, isCaptionDraft);
              });
            },
          );
        },
        '/ai_select': (context) => const AICharacterSelectPage(),
      },
      onGenerateRoute: (settings) {
        // Handles routes with arguments
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

// Reusable custom frosted-glass container
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
