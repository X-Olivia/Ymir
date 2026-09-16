import 'dart:io';

enum PostSource {
  imagePost,    // From the image post page
  captionSuggest, // From the caption suggestions page
}

class PostModel {
  final String id; // Unique ID
  final String title;
  final String? description; // May be empty
  final List<String> topics;
  final List<File> images; // Must contain images
  final PostSource source;
  final DateTime createdAt;
  final List<Map<String, dynamic>> comments; // Comment list
  final bool isGeneratingComments; // Comment generation state

  PostModel({
    String? id, // Optional; generated automatically when omitted
    required this.title,
    this.description,
    required this.topics,
    required this.images,
    required this.source,
    required this.createdAt,
    this.comments = const [], // Empty by default
    this.isGeneratingComments = false, // Not generating by default
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  // Validates the post data
  bool get isValid {
    return title.isNotEmpty && images.isNotEmpty;
  }

  // Gets the display name of the source page
  String get sourceName {
    switch (source) {
      case PostSource.imagePost:
        return 'Image Post';
      case PostSource.captionSuggest:
        return 'Caption Suggestions';
    }
  }

  // Copies the post with selected changes
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