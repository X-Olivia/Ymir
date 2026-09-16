import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/post_model.dart';

class NotesService {
  static const String _notesKey = 'user_notes';

  // Save post to notes
  static Future<PostModel> savePostAsNote(PostModel post) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey) ?? '[]';
      final List<dynamic> notesList = json.decode(notesJson);

      // Check if the same already existsIDNotes
      final existingIndex = notesList.indexWhere((note) => note['id'] == post.id);
      
      List<String> finalImagePaths;
      
      if (existingIndex != -1) {
        // Update existing notes: keep the original image path and only update other data
        final existingNote = notesList[existingIndex];
        finalImagePaths = List<String>.from(existingNote['imagePaths']);
        
        final updatedNoteData = {
          'id': post.id,
          'title': post.title,
          'description': post.description,
          'topics': post.topics,
          'imagePaths': finalImagePaths, // Keep original image path
          'source': post.source.toString(),
          'createdAt': existingNote['createdAt'], // Keep original creation time
          'comments': post.comments, // Update comment
          'isGeneratingComments': post.isGeneratingComments, // Update build status
        };
        
        notesList[existingIndex] = updatedNoteData;
      } else {
        // Create a new note: need to copy the image to the persistence directory
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
        
        // Add to the beginning of the note list (newest first)
        notesList.insert(0, noteData);
      }

      // Save to local storage
      await prefs.setString(_notesKey, json.encode(notesList));
      
      // Return the updated image pathPostModel
      return post.copyWith(
        images: finalImagePaths.map((path) => File(path)).toList(),
      );
    } catch (e) {
      print('Failed to save note: $e');
      throw Exception('Failed to save note');
    }
  }

  // Copy the image to the note-specific directory
  static Future<List<String>> _copyImagesToNotesDirectory(List<File> images, String postId) async {
    List<String> persistentPaths = [];
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final notesImageDir = Directory('${appDir.path}/notes_images');
      
      // Make sure the directory exists
      if (!await notesImageDir.exists()) {
        await notesImageDir.create(recursive: true);
      }

      for (int i = 0; i < images.length; i++) {
        final imageFile = images[i];
        
        if (await imageFile.exists()) {
          // Create unique filename, use postIDand index
          final fileName = '${postId}_$i.jpg';
          final persistentPath = '${notesImageDir.path}/$fileName';
          
          // Check if the target file already exists
          final targetFile = File(persistentPath);
          if (await targetFile.exists()) {
            // If the file already exists, use the existing file directly
            persistentPaths.add(persistentPath);
            print('Image file already exists, skip copying: $persistentPath');
          } else {
            // Copy the file to the note image directory
            await imageFile.copy(persistentPath);
            persistentPaths.add(persistentPath);
            print('The image has been copied to the persistence directory: $persistentPath');
          }
        } else {
          print('Warning: Image file does not exist, skip: ${imageFile.path}');
        }
      }
    } catch (e) {
      print('Failed to copy images to note directory: $e');
      // If copying fails, return the original path as a fallback
      return images.map((file) => file.path).toList();
    }
    
    return persistentPaths;
  }

  // Delete image files
  static Future<void> _deleteImageFiles(List<String> imagePaths) async {
    for (final path in imagePaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          print('Image file deleted: $path');
        }
      } catch (e) {
        print('Failed to delete image file: $path, error: $e');
      }
    }
  }

  // Get all notes
  static Future<List<Map<String, dynamic>>> getAllNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey) ?? '[]';
      final List<dynamic> notesList = json.decode(notesJson);
      
      return notesList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Failed to get notes: $e');
      return [];
    }
  }

  // Delete note
  static Future<void> deleteNote(String noteId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey) ?? '[]';
      final List<dynamic> notesList = json.decode(notesJson);

      // Find the note you want to delete and get its image path
      final noteToDelete = notesList.firstWhere(
        (note) => note['id'] == noteId,
        orElse: () => null,
      );
      
      if (noteToDelete != null) {
        // Delete the image file corresponding to the note
        final imagePaths = List<String>.from(noteToDelete['imagePaths'] ?? []);
        await _deleteImageFiles(imagePaths);
      }

      // Remove assignmentIDNotes
      notesList.removeWhere((note) => note['id'] == noteId);

      // Save updated list
      await prefs.setString(_notesKey, json.encode(notesList));
    } catch (e) {
      print('Failed to delete note: $e');
      throw Exception('Failed to delete note');
    }
  }

  // Created from note dataPostModelobject
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
        return null; // If the image file does not exist, returnnull
      }

      final sourceString = noteData['source'] ?? 'PostSource.imagePost';
      PostSource source = PostSource.imagePost;
      if (sourceString.contains('captionSuggest')) {
        source = PostSource.captionSuggest;
      }

      // Process comment data
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
      print('createPostModelfail: $e');
      return null;
    }
  }

  // Clear all notes
  static Future<void> clearAllNotes() async {
    try {
      // First get the image paths of all notes and delete them
      final notes = await getAllNotes();
      for (final note in notes) {
        final imagePaths = List<String>.from(note['imagePaths'] ?? []);
        await _deleteImageFiles(imagePaths);
      }
      
      // Delete the entire note image directory
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final notesImageDir = Directory('${appDir.path}/notes_images');
        if (await notesImageDir.exists()) {
          await notesImageDir.delete(recursive: true);
          print('Deleted note image directory');
        }
      } catch (e) {
        print('Failed to delete note image directory: $e');
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notesKey);
    } catch (e) {
      print('Failed to clear notes: $e');
      throw Exception('Failed to clear notes');
    }
  }

  // Fix image paths for all notes on startup
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
          
          // If the file in the original path does not exist, try to repair it
          if (!imageFile.existsSync()) {
            final fileName = path.split('/').last;
            final fixedPath = await _tryFixImagePath(fileName);
            if (fixedPath != null) {
              fixedPaths.add(fixedPath);
              noteHasChanges = true;
              print('Repairing image path: $fileName -> $fixedPath');
            } else {
              fixedPaths.add(path); // Keep original path
            }
          } else {
            fixedPaths.add(path); // The path is valid, keep it
          }
        }
        
        // If the path of this note changes, update it
        if (noteHasChanges) {
          notesList[i] = {
            ...note,
            'imagePaths': fixedPaths,
          };
          hasChanges = true;
        }
      }
      
      // If there are any changes, save to local storage
      if (hasChanges) {
        await prefs.setString(_notesKey, json.encode(notesList));
        print('Fixed note image path on startup');
      }
    } catch (e) {
      print('Failed to fix note image path at startup: $e');
    }
  }

  // Try fixing the image path
  static Future<String?> _tryFixImagePath(String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final notesImageDir = Directory('${appDir.path}/notes_images');
      
      if (await notesImageDir.exists()) {
        final fixedPath = '${notesImageDir.path}/$fileName';
        final file = File(fixedPath);
        if (await file.exists()) {
          print('Repair image path successfully: $fileName -> $fixedPath');
          return fixedPath;
        }
      }
    } catch (e) {
      print('Failed to fix image path: $fileName, error: $e');
    }
    return null;
  }
} 