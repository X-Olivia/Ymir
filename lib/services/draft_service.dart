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

  // 初始化 Hive
  static Future<void> init() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
    
    // 注册适配器
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DraftModelAdapter());
    }
    
    // 打开草稿盒子
    _draftBox = await Hive.openBox<DraftModel>(_draftBoxName);
    // 打开文案草稿盒子
    _captionDraftBox = await Hive.openBox<DraftModel>(_captionDraftBoxName);
  }

  // 获取草稿盒子
  static Box<DraftModel> get _box {
    if (_draftBox == null) {
      throw Exception('DraftService not initialized. Call DraftService.init() first.');
    }
    return _draftBox!;
  }

  // 获取文案草稿盒子
  static Box<DraftModel> get _captionBox {
    if (_captionDraftBox == null) {
      throw Exception('DraftService not initialized. Call DraftService.init() first.');
    }
    return _captionDraftBox!;
  }

  // 保存草稿
  static Future<DraftModel> saveDraft({
    String? draftId,
    required String title,
    required String description,
    required List<String> topics,
    required List<AssetEntity> selectedAssets,
    List<String>? existingImagePaths,
  }) async {
    try {
      // 保存新选择的图片到本地并获取路径
      List<String> newImagePaths = await _saveImagesToLocal(selectedAssets);
      
      // 合并已存在的图片路径和新图片路径
      List<String> allImagePaths = [
        ...(existingImagePaths ?? []),
        ...newImagePaths,
      ];
      
      final now = DateTime.now();
      
      DraftModel draft;
      
      if (draftId != null) {
        // 更新现有草稿
        final existingDraft = _box.get(draftId);
        if (existingDraft != null) {
          // 如果没有提供 existingImagePaths，则保留原有的图片
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
          // 如果找不到现有草稿，创建新的
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
        // 创建新草稿
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

      // 保存到 Hive
      await _box.put(draft.id, draft);
      return draft;
    } catch (e) {
      throw Exception('保存草稿失败: $e');
    }
  }

  // 获取所有草稿
  static List<DraftModel> getAllDrafts() {
    try {
      final drafts = _box.values.toList();
      // 按更新时间倒序排列
      drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return drafts;
    } catch (e) {
      print('获取草稿列表失败: $e');
      return [];
    }
  }

  // 获取单个草稿
  static DraftModel? getDraft(String id) {
    try {
      return _box.get(id);
    } catch (e) {
      print('获取草稿失败: $e');
      return null;
    }
  }

  // 删除草稿
  static Future<bool> deleteDraft(String id) async {
    try {
      final draft = _box.get(id);
      if (draft != null) {
        // 删除关联的图片文件
        await _deleteImageFiles(draft.imagePaths);
        // 从数据库删除
        await _box.delete(id);
        return true;
      }
      return false;
    } catch (e) {
      print('删除草稿失败: $e');
      return false;
    }
  }

  // 清空所有草稿
  static Future<void> clearAllDrafts() async {
    try {
      final drafts = getAllDrafts();
      // 删除所有图片文件
      for (final draft in drafts) {
        await _deleteImageFiles(draft.imagePaths);
      }
      // 清空数据库
      await _box.clear();
    } catch (e) {
      print('清空草稿失败: $e');
    }
  }

  // 获取当前草稿（最新的一个，用于恢复编辑状态）
  static DraftModel? getCurrentDraft() {
    try {
      final drafts = getAllDrafts();
      return drafts.isNotEmpty ? drafts.first : null;
    } catch (e) {
      print('获取当前草稿失败: $e');
      return null;
    }
  }

  // 将 AssetEntity 转换为本地文件路径
  static Future<List<String>> _saveImagesToLocal(List<AssetEntity> assets) async {
    List<String> imagePaths = [];
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${appDir.path}/draft_images');
      
      // 确保目录存在
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      for (int i = 0; i < assets.length; i++) {
        final asset = assets[i];
        final file = await asset.file;
        
        if (file != null) {
          // 创建唯一的文件名
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final localPath = '${imageDir.path}/$fileName';
          
          // 复制文件到应用目录
          await file.copy(localPath);
          imagePaths.add(localPath);
        }
      }
    } catch (e) {
      print('保存图片到本地失败: $e');
    }
    
    return imagePaths;
  }

  // 删除图片文件
  static Future<void> _deleteImageFiles(List<String> imagePaths) async {
    for (final path in imagePaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('删除图片文件失败: $path, error: $e');
      }
    }
  }

  // 从本地路径加载图片为 File 对象
  static Future<File?> getImageFile(String imagePath) async {
    try {
      final file = File(imagePath);
      if (file.existsSync()) {
        return file;
      }
      
      // 如果原路径的文件不存在，尝试在当前应用目录中查找
      final fileName = imagePath.split('/').last; // 获取文件名
      return await _tryFixDraftImagePath(fileName);
    } catch (e) {
      print('获取图片文件失败: $imagePath, error: $e');
      return null;
    }
  }

  // 尝试修复草稿图片路径
  static Future<File?> _tryFixDraftImagePath(String fileName) async {
    try {
      // 尝试在草稿图片目录中查找
      final appDir = await getApplicationDocumentsDirectory();
      final draftImageDir = Directory('${appDir.path}/draft_images');
      if (await draftImageDir.exists()) {
        final fixedPath = '${draftImageDir.path}/$fileName';
        final file = File(fixedPath);
        if (await file.exists()) {
          print('修复草稿图片路径成功: $fileName -> $fixedPath');
          return file;
        }
      }
    } catch (e) {
      print('修复草稿图片路径失败: $fileName, error: $e');
    }
    return null;
  }

  // 文案草稿相关方法
  
  // 保存文案草稿
  static Future<DraftModel> saveCaptionDraft({
    String? draftId,
    required String title,
    required String description,
    required List<String> topics,
    required List<AssetEntity> selectedAssets,
    List<String>? existingImagePaths,
  }) async {
    try {
      // 保存新选择的图片到本地并获取路径
      List<String> newImagePaths = await _saveImagesToLocal(selectedAssets);
      
      // 合并已存在的图片路径和新图片路径
      List<String> allImagePaths = [
        ...(existingImagePaths ?? []),
        ...newImagePaths,
      ];
      
      final now = DateTime.now();
      
      DraftModel draft;
      
      if (draftId != null) {
        // 更新现有草稿
        final existingDraft = _captionBox.get(draftId);
        if (existingDraft != null) {
          // 如果没有提供 existingImagePaths，则保留原有的图片
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
          // 如果找不到现有草稿，创建新的
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
        // 创建新草稿
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

      // 保存到文案草稿盒子
      await _captionBox.put(draft.id, draft);
      return draft;
    } catch (e) {
      throw Exception('保存文案草稿失败: $e');
    }
  }

  // 获取所有文案草稿
  static List<DraftModel> getAllCaptionDrafts() {
    try {
      final drafts = _captionBox.values.toList();
      // 按更新时间倒序排列
      drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return drafts;
    } catch (e) {
      print('获取文案草稿列表失败: $e');
      return [];
    }
  }

  // 获取单个文案草稿
  static DraftModel? getCaptionDraft(String id) {
    try {
      return _captionBox.get(id);
    } catch (e) {
      print('获取文案草稿失败: $e');
      return null;
    }
  }

  // 删除文案草稿
  static Future<bool> deleteCaptionDraft(String id) async {
    try {
      final draft = _captionBox.get(id);
      if (draft != null) {
        // 删除关联的图片文件
        await _deleteImageFiles(draft.imagePaths);
        // 从数据库删除
        await _captionBox.delete(id);
        return true;
      }
      return false;
    } catch (e) {
      print('删除文案草稿失败: $e');
      return false;
    }
  }

  // 清空所有文案草稿
  static Future<void> clearAllCaptionDrafts() async {
    try {
      final drafts = getAllCaptionDrafts();
      // 删除所有图片文件
      for (final draft in drafts) {
        await _deleteImageFiles(draft.imagePaths);
      }
      // 清空数据库
      await _captionBox.clear();
    } catch (e) {
      print('清空文案草稿失败: $e');
    }
  }

  // 获取当前文案草稿（最新的一个，用于恢复编辑状态）
  static DraftModel? getCurrentCaptionDraft() {
    try {
      final drafts = getAllCaptionDrafts();
      return drafts.isNotEmpty ? drafts.first : null;
    } catch (e) {
      print('获取当前文案草稿失败: $e');
      return null;
    }
  }

  // 关闭数据库
  static Future<void> close() async {
    try {
      await _draftBox?.close();
      await _captionDraftBox?.close();
      _draftBox = null;
      _captionDraftBox = null;
    } catch (e) {
      print('关闭草稿数据库失败: $e');
    }
  }

  // 启动时修复所有草稿的图片路径
  static Future<void> fixAllDraftImagePaths() async {
    try {
      // 修复图片草稿
      final imageDrafts = getAllDrafts();
      for (final draft in imageDrafts) {
        bool hasChanges = false;
        List<String> fixedPaths = [];
        
        for (final path in draft.imagePaths) {
          File imageFile = File(path);
          
          // 如果原路径的文件不存在，尝试修复
          if (!imageFile.existsSync()) {
            final fileName = path.split('/').last;
            final fixedFile = await _tryFixDraftImagePath(fileName);
            if (fixedFile != null) {
              fixedPaths.add(fixedFile.path);
              hasChanges = true;
              print('启动修复草稿图片路径: $fileName -> ${fixedFile.path}');
            } else {
              fixedPaths.add(path); // 保留原路径
            }
          } else {
            fixedPaths.add(path); // 路径有效，保留
          }
        }
        
        // 如果这个草稿有路径变化，更新它
        if (hasChanges) {
          final updatedDraft = draft.copyWith(imagePaths: fixedPaths);
          await _box.put(draft.id, updatedDraft);
        }
      }
      
      // 修复文案草稿
      final captionDrafts = getAllCaptionDrafts();
      for (final draft in captionDrafts) {
        bool hasChanges = false;
        List<String> fixedPaths = [];
        
        for (final path in draft.imagePaths) {
          File imageFile = File(path);
          
          // 如果原路径的文件不存在，尝试修复
          if (!imageFile.existsSync()) {
            final fileName = path.split('/').last;
            final fixedFile = await _tryFixDraftImagePath(fileName);
            if (fixedFile != null) {
              fixedPaths.add(fixedFile.path);
              hasChanges = true;
              print('启动修复文案草稿图片路径: $fileName -> ${fixedFile.path}');
            } else {
              fixedPaths.add(path); // 保留原路径
            }
          } else {
            fixedPaths.add(path); // 路径有效，保留
          }
        }
        
        // 如果这个草稿有路径变化，更新它
        if (hasChanges) {
          final updatedDraft = draft.copyWith(imagePaths: fixedPaths);
          await _captionBox.put(draft.id, updatedDraft);
        }
      }
      
      print('启动时修复了草稿图片路径');
    } catch (e) {
      print('启动时修复草稿图片路径失败: $e');
    }
  }
} 