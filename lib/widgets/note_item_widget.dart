import 'package:flutter/material.dart';
import 'dart:io';

class NoteItemWidget extends StatelessWidget {
  final Map<String, dynamic> noteData;
  final Color themeColor;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const NoteItemWidget({
    super.key,
    required this.noteData,
    required this.themeColor,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = noteData['title'] ?? '无标题';
    final imagePaths = List<String>.from(noteData['imagePaths'] ?? []);
    final topics = List<String>.from(noteData['topics'] ?? []);
    final createdAt = DateTime.tryParse(noteData['createdAt'] ?? '') ?? DateTime.now();
    final source = noteData['source'] ?? '';

    // 获取第一张有效图片
    String? firstImagePath;
    for (final path in imagePaths) {
      if (File(path).existsSync()) {
        firstImagePath = path;
        break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onDelete,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图片区域
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    color: Colors.grey[100],
                  ),
                  child: Stack(
                    children: [
                      // 图片
                      firstImagePath != null
                          ? ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                              child: Image.file(
                                File(firstImagePath),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: Colors.grey[400],
                                size: 32,
                              ),
                            ),
                      
                      // 来源标识（右上角）
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getSourceName(source),
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      
                      // 删除按钮（左上角）
                      if (onDelete != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: GestureDetector(
                            onTap: onDelete,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // 内容区域
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      
                      // 话题标签（最多显示1个）
                      if (topics.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#${topics.first}',
                            style: TextStyle(
                              fontSize: 8,
                              color: themeColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      
                      const Spacer(),
                      
                      // 创建时间
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 获取来源名称
  String _getSourceName(String source) {
    if (source.contains('captionSuggest')) {
      return '文案';
    } else {
      return '图片';
    }
  }

  // 格式化日期
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
} 