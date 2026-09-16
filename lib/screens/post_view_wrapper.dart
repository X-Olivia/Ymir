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
          // Use the same background as MainScreen
          image: DecorationImage(
            image: AssetImage(_getBackgroundImagePath(effectiveThemeColor)),
            fit: BoxFit.cover,
            alignment: const Alignment(0.15, 0),
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Top navigation buttons - mirrors MainScreen's navigation bar
              Positioned(
                top: 10,
                right: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Share button
                    IconButton(
                      icon: Icon(
                        Icons.share_outlined,
                        size: 28,
                        color: effectiveThemeColor,
                      ),
                      onPressed: () {
                        // Share feature
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Post sharing'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    // Settings button
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
              
              // Back button
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
              
              // PostViewPage content
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60), // Leave room for the top navigation bar
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

  // Get the background image path from the theme color
  String _getBackgroundImagePath(Color themeColor) {
    // Simplified color-matching logic
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