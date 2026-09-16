import 'package:hive/hive.dart';

part 'draft_model.g.dart';

@HiveType(typeId: 0)
class DraftModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  List<String> topics;

  @HiveField(4)
  List<String> imagePaths; // Stores local image paths

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  DraftModel({
    required this.id,
    required this.title,
    required this.description,
    required this.topics,
    required this.imagePaths,
    required this.createdAt,
    required this.updatedAt,
  });

  // Copies the draft with selected changes
  DraftModel copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? topics,
    List<String>? imagePaths,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DraftModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      topics: topics ?? this.topics,
      imagePaths: imagePaths ?? this.imagePaths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Determines whether the draft is empty
  bool get isEmpty {
    return title.trim().isEmpty && 
           description.trim().isEmpty && 
           topics.isEmpty && 
           imagePaths.isEmpty;
  }

  @override
  String toString() {
    return 'DraftModel(id: $id, title: $title, description: $description, topics: $topics, imagePaths: $imagePaths, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
} 