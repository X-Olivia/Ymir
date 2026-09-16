import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/draft_model.dart';

class DraftService {
  static const String _draftBoxName = 'drafts';
  static const String _captionDraftBoxName = 'caption_drafts';
  static Box<DraftModel>? _draftBox;
  static Box<DraftModel>? _captionDraftBox;

  // initialization Hive
  static Future<void> init() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
    
    // Register adapter
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DraftModelAdapter());
    }
    
    // Open draft box
    _draftBox = await Hive.openBox<DraftModel>(_draftBoxName);
    // Open copy draft box
    _captionDraftBox = await Hive.openBox<DraftModel>(_captionDraftBoxName);
  }

  // Get draft box
  static Box<DraftModel> get _box {
    if (_draftBox == null) {
      throw Exception('DraftService not initialized. Call DraftService.init() first.');
    }
    return _draftBox!;
  }

  // Get the caption draft box
  static Box<DraftModel> get _captionBox {
    if (_captionDraftBox == null) {
      throw Exception('DraftService not initialized. Call DraftService.init() first.');
    }
    return _captionDraftBox!;
  }

  // save draft
  static Future<DraftModel> saveDraft({
    String? draftId,
    required String title,
    required String description,
    required List<String> topics,
    required List<AssetEntity> selectedAssets,
    List<String>? existingImagePaths,
  }) async {
    try {
      // Save the newly selected image locally and get the path
      List<String> newImagePaths = await _saveImagesToLocal(selectedAssets);
      
      // Merge existing image paths and new image paths
      List<String> allImagePaths = [
        ...(existingImagePaths ?? []),
        ...newImagePaths,
      ];
      
      final now = DateTime.now();
      
      DraftModel draft;
      
      if (draftId != null) {
        // Update existing draft
        final existingDraft = _box.get(draftId);
        if (existingDraft != null) {
          // Preserve the original images when existingImagePaths is not provided
          if (existingImagePaths == null) {
            allImagePaths = [
              ...existingDraft.imagePaths,
              ...newImagePaths,
            ];
          }
          
          draft = existingDraft.copyWith(
            title: title,
            description: description,
            topics: topics,
            imagePaths: allImagePaths,
            updatedAt: now,
          );
        } else {
          // If no existing draft is found, create a new one
          draft = DraftModel(
            id: draftId,
            title: title,
            description: description,
            topics: topics,
            imagePaths: allImagePaths,
            createdAt: now,
            updatedAt: now,
          );
        }
      } else {
        // Create new draft
        final id = DateTime.now().millisecondsSinceEpoch.toString();
        draft = DraftModel(
          id: id,
          title: title,
          description: description,
          topics: topics,
          imagePaths: allImagePaths,
          createdAt: now,
          updatedAt: now,
        );
      }

      // save to Hive
      await _box.put(draft.id, draft);
      return draft;
    } catch (e) {
      throw Exception('Failed to save draft: $e');
    }
  }

  // Get all drafts
  static List<DraftModel> getAllDrafts() {
    try {
      final drafts = _box.values.toList();
      // Sort by update time in descending order
      drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return drafts;
    } catch (e) {
      print('Failed to get draft list: $e');
      return [];
    }
  }

  // Get a single draft
  static DraftModel? getDraft(String id) {
    try {
      return _box.get(id);
    } catch (e) {
      print('Failed to get draft: $e');
      return null;
    }
  }

  // Delete draft
  static Future<bool> deleteDraft(String id) async {
    try {
      final draft = _box.get(id);
      if (draft != null) {
        // Delete associated image files
        await _deleteImageFiles(draft.imagePaths);
        // delete from database
        await _box.delete(id);
        return true;
      }
      return false;
    } catch (e) {
      print('Delete draft failed: $e');
      return false;
    }
  }

  // Clear all drafts
  static Future<void> clearAllDrafts() async {
    try {
      final drafts = getAllDrafts();
      // Delete all image files
      for (final draft in drafts) {
        await _deleteImageFiles(draft.imagePaths);
      }
      // Clear database
      await _box.clear();
    } catch (e) {
      print('Failed to clear draft: $e');
    }
  }

  // Get the current draft (the latest one, used to restore editing status)
  static DraftModel? getCurrentDraft() {
    try {
      final drafts = getAllDrafts();
      return drafts.isNotEmpty ? drafts.first : null;
    } catch (e) {
      print('Failed to get current draft: $e');
      return null;
    }
  }

  // Convert AssetEntity objects to local file paths
  static Future<List<String>> _saveImagesToLocal(List<AssetEntity> assets) async {
    List<String> imagePaths = [];
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${appDir.path}/draft_images');
      
      // Make sure the directory exists
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      for (int i = 0; i < assets.length; i++) {
        final asset = assets[i];
        final file = await asset.file;
        
        if (file != null) {
          // Create unique filename
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final localPath = '${imageDir.path}/$fileName';
          
          // Copy files to application directory
          await file.copy(localPath);
          imagePaths.add(localPath);
        }
      }
    } catch (e) {
      print('Failed to save image locally: $e');
    }
    
    return imagePaths;
  }

  // Delete image files
  static Future<void> _deleteImageFiles(List<String> imagePaths) async {
    for (final path in imagePaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Failed to delete image file: $path, error: $e');
      }
    }
  }

  // Load images from local path as File object
  static Future<File?> getImageFile(String imagePath) async {
    try {
      final file = File(imagePath);
      if (file.existsSync()) {
        return file;
      }
      
      // If the file in the original path does not exist, try to find it in the current application directory.
      final fileName = imagePath.split('/').last; // Get file name
      return await _tryFixDraftImagePath(fileName);
    } catch (e) {
      print('Failed to get image file: $imagePath, error: $e');
      return null;
    }
  }

  // Try fixing draft image path
  static Future<File?> _tryFixDraftImagePath(String fileName) async {
    try {
      // Try looking in the draft image directory
      final appDir = await getApplicationDocumentsDirectory();
      final draftImageDir = Directory('${appDir.path}/draft_images');
      if (await draftImageDir.exists()) {
        final fixedPath = '${draftImageDir.path}/$fileName';
        final file = File(fixedPath);
        if (await file.exists()) {
          print('Repair draft image path successfully: $fileName -> $fixedPath');
          return file;
        }
      }
    } catch (e) {
      print('Failed to fix draft image path: $fileName, error: $e');
    }
    return null;
  }

  // Caption draft methods
  
  // Save draft copy
  static Future<DraftModel> saveCaptionDraft({
    String? draftId,
    required String title,
    required String description,
    required List<String> topics,
    required List<AssetEntity> selectedAssets,
    List<String>? existingImagePaths,
  }) async {
    try {
      // Save the newly selected image locally and get the path
      List<String> newImagePaths = await _saveImagesToLocal(selectedAssets);
      
      // Merge existing image paths and new image paths
      List<String> allImagePaths = [
        ...(existingImagePaths ?? []),
        ...newImagePaths,
      ];
      
      final now = DateTime.now();
      
      DraftModel draft;
      
      if (draftId != null) {
        // Update existing draft
        final existingDraft = _captionBox.get(draftId);
        if (existingDraft != null) {
          // Preserve the original images when existingImagePaths is not provided
          if (existingImagePaths == null) {
            allImagePaths = [
              ...existingDraft.imagePaths,
              ...newImagePaths,
            ];
          }
          
          draft = existingDraft.copyWith(
            title: title,
            description: description,
            topics: topics,
            imagePaths: allImagePaths,
            updatedAt: now,
          );
        } else {
          // If no existing draft is found, create a new one
          draft = DraftModel(
            id: draftId,
            title: title,
            description: description,
            topics: topics,
            imagePaths: allImagePaths,
            createdAt: now,
            updatedAt: now,
          );
        }
      } else {
        // Create new draft
        final id = DateTime.now().millisecondsSinceEpoch.toString();
        draft = DraftModel(
          id: id,
          title: title,
          description: description,
          topics: topics,
          imagePaths: allImagePaths,
          createdAt: now,
          updatedAt: now,
        );
      }

      // Save to copy draft box
      await _captionBox.put(draft.id, draft);
      return draft;
    } catch (e) {
      throw Exception('Failed to save caption draft: $e');
    }
  }

  // Get all copy drafts
  static List<DraftModel> getAllCaptionDrafts() {
    try {
      final drafts = _captionBox.values.toList();
      // Sort by update time in descending order
      drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return drafts;
    } catch (e) {
      print('Failed to get copy draft list: $e');
      return [];
    }
  }

  // Get a single copy draft
  static DraftModel? getCaptionDraft(String id) {
    try {
      return _captionBox.get(id);
    } catch (e) {
      print('Failed to get copy draft: $e');
      return null;
    }
  }

  // Delete draft copy
  static Future<bool> deleteCaptionDraft(String id) async {
    try {
      final draft = _captionBox.get(id);
      if (draft != null) {
        // Delete associated image files
        await _deleteImageFiles(draft.imagePaths);
        // delete from database
        await _captionBox.delete(id);
        return true;
      }
      return false;
    } catch (e) {
      print('Failed to delete draft copy: $e');
      return false;
    }
  }

  // Clear all caption drafts
  static Future<void> clearAllCaptionDrafts() async {
    try {
      final drafts = getAllCaptionDrafts();
      // Delete all image files
      for (final draft in drafts) {
        await _deleteImageFiles(draft.imagePaths);
      }
      // Clear database
      await _captionBox.clear();
    } catch (e) {
      print('Failed to clear draft copy: $e');
    }
  }

  // Get the current copy draft (the latest one, used to restore editing status)
  static DraftModel? getCurrentCaptionDraft() {
    try {
      final drafts = getAllCaptionDrafts();
      return drafts.isNotEmpty ? drafts.first : null;
    } catch (e) {
      print('Failed to get the current caption draft: $e');
      return null;
    }
  }

  // Close database
  static Future<void> close() async {
    try {
      await _draftBox?.close();
      await _captionDraftBox?.close();
      _draftBox = null;
      _captionDraftBox = null;
    } catch (e) {
      print('Failed to close draft database: $e');
    }
  }

  // Fix image paths for all drafts on startup
  static Future<void> fixAllDraftImagePaths() async {
    try {
      // Fix draft image
      final imageDrafts = getAllDrafts();
      for (final draft in imageDrafts) {
        bool hasChanges = false;
        List<String> fixedPaths = [];
        
        for (final path in draft.imagePaths) {
          File imageFile = File(path);
          
          // If the file in the original path does not exist, try to repair it
          if (!imageFile.existsSync()) {
            final fileName = path.split('/').last;
            final fixedFile = await _tryFixDraftImagePath(fileName);
            if (fixedFile != null) {
              fixedPaths.add(fixedFile.path);
              hasChanges = true;
              print('Repairing draft image path: $fileName -> ${fixedFile.path}');
            } else {
              fixedPaths.add(path); // Keep original path
            }
          } else {
            fixedPaths.add(path); // The path is valid, keep it
          }
        }
        
        // If this draft has path changes, update it
        if (hasChanges) {
          final updatedDraft = draft.copyWith(imagePaths: fixedPaths);
          await _box.put(draft.id, updatedDraft);
        }
      }
      
      // Fix draft copy
      final captionDrafts = getAllCaptionDrafts();
      for (final draft in captionDrafts) {
        bool hasChanges = false;
        List<String> fixedPaths = [];
        
        for (final path in draft.imagePaths) {
          File imageFile = File(path);
          
          // If the file in the original path does not exist, try to repair it
          if (!imageFile.existsSync()) {
            final fileName = path.split('/').last;
            final fixedFile = await _tryFixDraftImagePath(fileName);
            if (fixedFile != null) {
              fixedPaths.add(fixedFile.path);
              hasChanges = true;
              print('Repairing caption draft image path: $fileName -> ${fixedFile.path}');
            } else {
              fixedPaths.add(path); // Keep original path
            }
          } else {
            fixedPaths.add(path); // The path is valid, keep it
          }
        }
        
        // If this draft has path changes, update it
        if (hasChanges) {
          final updatedDraft = draft.copyWith(imagePaths: fixedPaths);
          await _captionBox.put(draft.id, updatedDraft);
        }
      }
      
      print('Fixed draft image path on startup');
    } catch (e) {
      print('Fix draft image path failed on startup: $e');
    }
  }
} 