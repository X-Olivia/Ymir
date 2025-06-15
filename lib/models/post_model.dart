import 'dart:io';

enum PostSource {
  imagePost,    // 来自图片发布页面
  captionSuggest, // 来自文案建议页面
}

class PostModel {
  final String id; // 添加唯一ID
  final String title;
  final String? description; // 可能为空
  final List<String> topics;
  final List<File> images; // 必须有图片
  final PostSource source;
  final DateTime createdAt;
  final List<Map<String, dynamic>> comments; // 添加评论列表
  final bool isGeneratingComments; // 添加评论生成状态

  PostModel({
    String? id, // 可选ID，如果不提供则自动生成
    required this.title,
    this.description,
    required this.topics,
    required this.images,
    required this.source,
    required this.createdAt,
    this.comments = const [], // 默认空评论列表
    this.isGeneratingComments = false, // 默认不在生成中
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  // 验证帖子数据是否有效
  bool get isValid {
    return title.isNotEmpty && images.isNotEmpty;
  }

  // 获取来源页面的中文名称
  String get sourceName {
    switch (source) {
      case PostSource.imagePost:
        return '图片发布';
      case PostSource.captionSuggest:
        return '文案建议';
    }
  }

  // 复制并修改帖子数据
  PostModel copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? topics,
    List<File>? images,
    PostSource? source,
    DateTime? createdAt,
    List<Map<String, dynamic>>? comments,
    bool? isGeneratingComments,
  }) {
    return PostModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      topics: topics ?? this.topics,
      images: images ?? this.images,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      comments: comments ?? this.comments,
      isGeneratingComments: isGeneratingComments ?? this.isGeneratingComments,
    );
  }

  @override
  String toString() {
    return 'PostModel(id: $id, title: $title, description: $description, topics: $topics, images: ${images.length}, source: $source, createdAt: $createdAt, comments: ${comments.length}, isGeneratingComments: $isGeneratingComments)';
  }
} 