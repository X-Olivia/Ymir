import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 修复：使用 addPostFrameCallback 确保context已经准备好
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1秒后导航到主页
      Timer(const Duration(seconds: 1), () {
        if (mounted) {  // 添加检查确保组件仍然挂载
          Navigator.pushReplacementNamed(context, '/main');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 这里可以放置应用logo或名称
            const Text(
              'YMIR',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
} 