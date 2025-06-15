import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/post_model.dart';
import 'post_view_page.dart';

class PostViewWrapper extends StatelessWidget {
  final PostModel postData;
  final Color? themeColor;

  const PostViewWrapper({
    super.key,
    required this.postData,
    this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveThemeColor = themeColor ?? Theme.of(context).primaryColor;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // 使用与MainScreen相同的背景
          image: DecorationImage(
            image: AssetImage(_getBackgroundImagePath(effectiveThemeColor)),
            fit: BoxFit.cover,
            alignment: const Alignment(0.15, 0),
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 顶部导航按钮 - 复制MainScreen的导航栏
              Positioned(
                top: 10,
                right: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 分享按钮
                    IconButton(
                      icon: Icon(
                        Icons.share_outlined,
                        size: 28,
                        color: effectiveThemeColor,
                      ),
                      onPressed: () {
                        // 分享功能
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('帖子分享功能'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    // 设置按钮
                    IconButton(
                      icon: Icon(
                        Icons.settings,
                        size: 28,
                        color: effectiveThemeColor,
                      ),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/settings',
                          arguments: effectiveThemeColor,
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // 返回按钮
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    size: 28,
                    color: effectiveThemeColor,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              
              // PostViewPage 内容
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60), // 为顶部导航栏留出空间
                  child: PostViewPage(
                    postData: postData,
                    themeColor: effectiveThemeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 根据主题色获取背景图片路径
  String _getBackgroundImagePath(Color themeColor) {
    // 简化的颜色匹配逻辑
    if (themeColor == const Color(0xFF2463b3)) {
      return 'assets/images/back/blue.png';
    } else if (themeColor == const Color(0xFFa18dc1)) {
      return 'assets/images/back/purple.png';
    } else if (themeColor == const Color(0xFF8bb179)) {
      return 'assets/images/back/green.png';
    } else if (themeColor == const Color(0xFFfbb93b)) {
      return 'assets/images/back/orange.png';
    } else if (themeColor == const Color(0xFFfeabcd)) {
      return 'assets/images/back/pink.png';
    } else {
      return 'assets/images/back/blue.png';
    }
  }
} 