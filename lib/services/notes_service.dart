import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/post_model.dart';

class NotesService {
  static const String _notesKey = 'user_notes';

  // 保存帖子到笔记
  static Future<PostModel> savePostAsNote(PostModel post) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey) ?? '[]';
      final List<dynamic> notesList = json.decode(notesJson);

      // 检查是否已存在相同ID的笔记
      final existingIndex = notesList.indexWhere((note) => note['id'] == post.id);
      
      List<String> finalImagePaths;
      
      if (existingIndex != -1) {
        // 更新现有笔记：保留原有图片路径，只更新其他数据
        final existingNote = notesList[existingIndex];
        finalImagePaths = List<String>.from(existingNote['imagePaths']);
        
        final updatedNoteData = {
          'id': post.id,
          'title': post.title,
          'description': post.description,
          'topics': post.topics,
          'imagePaths': finalImagePaths, // 保留原有图片路径
          'source': post.source.toString(),
          'createdAt': existingNote['createdAt'], // 保留原创建时间
          'comments': post.comments, // 更新评论
          'isGeneratingComments': post.isGeneratingComments, // 更新生成状态
        };
        
        notesList[existingIndex] = updatedNoteData;
      } else {
        // 创建新笔记：需要复制图片到持久化目录
        finalImagePaths = await _copyImagesToNotesDirectory(post.images, post.id);
        
        final noteData = {
          'id': post.id,
          'title': post.title,
          'description': post.description,
          'topics': post.topics,
          'imagePaths': finalImagePaths,
          'source': post.source.toString(),
          'createdAt': post.createdAt.toIso8601String(),
          'comments': post.comments,
          'isGeneratingComments': post.isGeneratingComments,
        };
        
        // 添加到笔记列表开头（最新的在前面）
        notesList.insert(0, noteData);
      }

      // 保存到本地存储
      await prefs.setString(_notesKey, json.encode(notesList));
      
      // 返回更新了图片路径的PostModel
      return post.copyWith(
        images: finalImagePaths.map((path) => File(path)).toList(),
      );
    } catch (e) {
      print('保存笔记失败: $e');
      throw Exception('保存笔记失败');
    }
  }

  // 将图片复制到笔记专用目录
  static Future<List<String>> _copyImagesToNotesDirectory(List<File> images, String postId) async {
    List<String> persistentPaths = [];
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final notesImageDir = Directory('${appDir.path}/notes_images');
      
      // 确保目录存在
      if (!await notesImageDir.exists()) {
        await notesImageDir.create(recursive: true);
      }

      for (int i = 0; i < images.length; i++) {
        final imageFile = images[i];
        
        if (await imageFile.exists()) {
          // 创建唯一的文件名，使用帖子ID和索引
          final fileName = '${postId}_$i.jpg';
          final persistentPath = '${notesImageDir.path}/$fileName';
          
          // 检查目标文件是否已经存在
          final targetFile = File(persistentPath);
          if (await targetFile.exists()) {
            // 如果文件已存在，直接使用现有文件
            persistentPaths.add(persistentPath);
            print('图片文件已存在，跳过复制: $persistentPath');
          } else {
            // 复制文件到笔记图片目录
            await imageFile.copy(persistentPath);
            persistentPaths.add(persistentPath);
            print('图片已复制到持久化目录: $persistentPath');
          }
        } else {
          print('警告：图片文件不存在，跳过: ${imageFile.path}');
        }
      }
    } catch (e) {
      print('复制图片到笔记目录失败: $e');
      // 如果复制失败，返回原始路径作为后备
      return images.map((file) => file.path).toList();
    }
    
    return persistentPaths;
  }

  // 删除图片文件
  static Future<void> _deleteImageFiles(List<String> imagePaths) async {
    for (final path in imagePaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          print('已删除图片文件: $path');
        }
      } catch (e) {
        print('删除图片文件失败: $path, error: $e');
      }
    }
  }

  // 获取所有笔记
  static Future<List<Map<String, dynamic>>> getAllNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey) ?? '[]';
      final List<dynamic> notesList = json.decode(notesJson);
      
      return notesList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('获取笔记失败: $e');
      return [];
    }
  }

  // 删除笔记
  static Future<void> deleteNote(String noteId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey) ?? '[]';
      final List<dynamic> notesList = json.decode(notesJson);

      // 找到要删除的笔记，获取其图片路径
      final noteToDelete = notesList.firstWhere(
        (note) => note['id'] == noteId,
        orElse: () => null,
      );
      
      if (noteToDelete != null) {
        // 删除笔记对应的图片文件
        final imagePaths = List<String>.from(noteToDelete['imagePaths'] ?? []);
        await _deleteImageFiles(imagePaths);
      }

      // 移除指定ID的笔记
      notesList.removeWhere((note) => note['id'] == noteId);

      // 保存更新后的列表
      await prefs.setString(_notesKey, json.encode(notesList));
    } catch (e) {
      print('删除笔记失败: $e');
      throw Exception('删除笔记失败');
    }
  }

  // 根据笔记数据创建PostModel对象
  static Future<PostModel?> createPostFromNote(Map<String, dynamic> noteData) async {
    try {
      final imagePaths = List<String>.from(noteData['imagePaths'] ?? []);
      List<File> validImages = [];
      
      for (final path in imagePaths) {
        File imageFile = File(path);
        if (imageFile.existsSync()) {
          validImages.add(imageFile);
        }
      }

      if (validImages.isEmpty) {
        return null; // 如果图片文件不存在，返回null
      }

      final sourceString = noteData['source'] ?? 'PostSource.imagePost';
      PostSource source = PostSource.imagePost;
      if (sourceString.contains('captionSuggest')) {
        source = PostSource.captionSuggest;
      }

      // 处理评论数据
      final commentsData = noteData['comments'];
      List<Map<String, dynamic>> comments = [];
      if (commentsData is List) {
        comments = List<Map<String, dynamic>>.from(commentsData);
      }

      return PostModel(
        id: noteData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: noteData['title'] ?? '',
        description: noteData['description'],
        topics: List<String>.from(noteData['topics'] ?? []),
        images: validImages,
        source: source,
        createdAt: DateTime.parse(noteData['createdAt'] ?? DateTime.now().toIso8601String()),
        comments: comments,
        isGeneratingComments: noteData['isGeneratingComments'] ?? false,
      );
    } catch (e) {
      print('创建PostModel失败: $e');
      return null;
    }
  }

  // 清空所有笔记
  static Future<void> clearAllNotes() async {
    try {
      // 先获取所有笔记的图片路径并删除
      final notes = await getAllNotes();
      for (final note in notes) {
        final imagePaths = List<String>.from(note['imagePaths'] ?? []);
        await _deleteImageFiles(imagePaths);
      }
      
      // 删除整个笔记图片目录
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final notesImageDir = Directory('${appDir.path}/notes_images');
        if (await notesImageDir.exists()) {
          await notesImageDir.delete(recursive: true);
          print('已删除笔记图片目录');
        }
      } catch (e) {
        print('删除笔记图片目录失败: $e');
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notesKey);
    } catch (e) {
      print('清空笔记失败: $e');
      throw Exception('清空笔记失败');
    }
  }

  // 启动时修复所有笔记的图片路径
  static Future<void> fixAllNotesImagePaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey) ?? '[]';
      final List<dynamic> notesList = json.decode(notesJson);
      
      bool hasChanges = false;
      
      for (int i = 0; i < notesList.length; i++) {
        final note = notesList[i];
        final imagePaths = List<String>.from(note['imagePaths'] ?? []);
        List<String> fixedPaths = [];
        bool noteHasChanges = false;
        
        for (final path in imagePaths) {
          File imageFile = File(path);
          
          // 如果原路径的文件不存在，尝试修复
          if (!imageFile.existsSync()) {
            final fileName = path.split('/').last;
            final fixedPath = await _tryFixImagePath(fileName);
            if (fixedPath != null) {
              fixedPaths.add(fixedPath);
              noteHasChanges = true;
              print('启动修复图片路径: $fileName -> $fixedPath');
            } else {
              fixedPaths.add(path); // 保留原路径
            }
          } else {
            fixedPaths.add(path); // 路径有效，保留
          }
        }
        
        // 如果这个笔记有路径变化，更新它
        if (noteHasChanges) {
          notesList[i] = {
            ...note,
            'imagePaths': fixedPaths,
          };
          hasChanges = true;
        }
      }
      
      // 如果有任何变化，保存到本地存储
      if (hasChanges) {
        await prefs.setString(_notesKey, json.encode(notesList));
        print('启动时修复了笔记图片路径');
      }
    } catch (e) {
      print('启动时修复笔记图片路径失败: $e');
    }
  }

  // 尝试修复图片路径
  static Future<String?> _tryFixImagePath(String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final notesImageDir = Directory('${appDir.path}/notes_images');
      
      if (await notesImageDir.exists()) {
        final fixedPath = '${notesImageDir.path}/$fileName';
        final file = File(fixedPath);
        if (await file.exists()) {
          print('修复图片路径成功: $fileName -> $fixedPath');
          return fixedPath;
        }
      }
    } catch (e) {
      print('修复图片路径失败: $fileName, error: $e');
    }
    return null;
  }
} 