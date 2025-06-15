import 'package:flutter/material.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ymir',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainScreen(),
      routes: {
        '/': (context) => const MainScreen(),
        '/settings': (context) {
          final Color? themeColor = ModalRoute.of(context)?.settings.arguments as Color?;
          return UserSettingsPage(themeColor: themeColor);
        },
      },
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main Screen'),
      ),
      body: Center(
        child: Text(
          'This is the main screen',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}

class UserSettingsPage extends StatelessWidget {
  final Color? themeColor;

  const UserSettingsPage({Key? key, this.themeColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Settings'),
      ),
      body: Center(
        child: Text(
          'This is the user settings page',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
} 