import 'package:flutter/material.dart';
import 'dart:io';
import '../models/post_model.dart';

class PostViewUIComponents {
  // Builds the image carousel
  static Widget buildImageCarousel({
    required List<File> images,
    required PageController pageController,
    required int currentImageIndex,
    required Function(int) onPageChanged,
    required Color themeColor,
  }) {
    return Column(
      children: [
        // Image carousel
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: pageController,
            onPageChanged: onPageChanged,
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: images[index].existsSync()
                      ? Image.file(
                          images[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),
              );
            },
          ),
        ),
        
        // Image indicator
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(images.length, (index) {
              final isActive = index == currentImageIndex;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isActive ? themeColor : Colors.grey.withOpacity(0.4),
                  border: isActive ? null : Border.all(
                    color: Colors.grey.withOpacity(0.6),
                    width: 1,
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  // Builds topic tags
  static Widget buildTopicTags({
    required List<String> topics,
    required Color themeColor,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: topics.map((topic) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: themeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: themeColor.withOpacity(0.3),
            ),
          ),
          child: Text(
            '#$topic',
            style: TextStyle(
              fontSize: 12,
              color: themeColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  // Builds the bottom interaction bar
  static Widget buildBottomInteractionBar({
    required String? replyingToCommentId,
    required String? replyingToUserName,
    required Color themeColor,
    required bool isLiked,
    required int likeCount,
    required bool isCollected,
    required VoidCallback onToggleLike,
    required VoidCallback onToggleCollect,
    required VoidCallback onShowInputModal,
    required VoidCallback onSubmitComment,
    required VoidCallback onCancelReply,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply indicator
            if (replyingToCommentId != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Replying to $replyingToUserName',
                        style: TextStyle(
                          color: themeColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onCancelReply,
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: themeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Single-row controls: like, favorite, comment field, and send
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Like button
                  GestureDetector(
                    onTap: onToggleLike,
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 24,
                          color: isLiked ? Colors.red : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          likeCount.toString(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  
                  // Favorite button
                  GestureDetector(
                    onTap: onToggleCollect,
                    child: Icon(
                      isCollected ? Icons.star : Icons.star_border,
                      size: 24,
                      color: isCollected ? Colors.orange : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 20),
                  
                  // Comment input field
                  Expanded(
                    child: GestureDetector(
                      onTap: onShowInputModal,
                      child: Container(
                        height: 30, // Uses a fixed height
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15), // Matches the corner radius to the height
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          replyingToCommentId != null 
                              ? 'Reply to $replyingToUserName...'
                              : 'Say something...',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Send button
                  GestureDetector(
                    onTap: onSubmitComment,
                    child: Container(
                      height: 30, // Matches the input field height
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(15), // Matches the input field corner radius
                      ),
                      alignment: Alignment.center, // Centers the content
                      child: const Text(
                        'Send',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the user information section
  static Widget buildUserInfoSection({
    required bool isLoadingUserInfo,
    required String userNickname,
    required String userAvatarPlaceholder,
    required Color userAvatarColor,
    required String? userAvatarPath,
    required DateTime createdAt,
    required PostSource source,
    required String sourceName,
    required String Function(DateTime) formatDate,
    required Color Function(PostSource) getSourceColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          // User avatar
          isLoadingUserInfo
              ? CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : CircleAvatar(
                  radius: 20,
                  backgroundColor: userAvatarPath == null ? userAvatarColor : null,
                  backgroundImage: userAvatarPath != null 
                      ? AssetImage(userAvatarPath) 
                      : null,
                  child: userAvatarPath == null ? Text(
                    userAvatarPlaceholder,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ) : null,
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoadingUserInfo ? 'Loading...' : userNickname,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  formatDate(createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Builds the post content section
  static Widget buildPostContent({
    required String title,
    required String? description,
    required List<String> topics,
    required List<File> images,
    required Color themeColor,
    required PageController pageController,
    required int currentImageIndex,
    required Function(int) onPageChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        // Description
        if (description?.isNotEmpty == true) ...[
          Text(
            description!,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Topic tags
        if (topics.isNotEmpty) ...[
          buildTopicTags(topics: topics, themeColor: themeColor),
          const SizedBox(height: 16),
        ],
        
        // Image carousel
        if (images.isNotEmpty) ...[
          buildImageCarousel(
            images: images,
            pageController: pageController,
            currentImageIndex: currentImageIndex,
            onPageChanged: onPageChanged,
            themeColor: themeColor,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
} 