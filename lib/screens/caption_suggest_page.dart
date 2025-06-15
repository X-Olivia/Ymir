import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:io';

import '../services/draft_service.dart';
import '../services/notes_service.dart';
import '../models/draft_model.dart';
import '../models/post_model.dart';
import '../widgets/topic_selector_widget.dart';

class CaptionSuggestPage extends StatefulWidget {
  final Color? themeColor;
  final String? draftId; // 添加草稿ID参数，用于编辑现有草稿
  final VoidCallback? onBack; // 添加返回回调
  final Function(PostModel)? onPostPublished; // 添加发布回调
  
  const CaptionSuggestPage({super.key, this.themeColor, this.draftId, this.onBack, this.onPostPublished});

  @override
  State<CaptionSuggestPage> createState() => CaptionSuggestPageState();
}

class CaptionSuggestPageState extends State<CaptionSuggestPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // 选中的图片列表
  List<AssetEntity> _selectedAssets = [];
  
  // 选中的话题列表
  List<String> _selectedTopics = [];
  
  // 草稿相关状态
  String? _currentDraftId;
  bool _isLoadingDraft = false;
  List<File> _draftImages = []; // 从草稿加载的图片文件
  
  // 推荐话题列表
  final List<String> _recommendedTopics = [
    '日常生活',
    '美食分享',
    '旅行记录',
    '穿搭搭配',
    '风景摄影',
    '宠物日常',
    '健身运动',
    '美妆护肤',
    '家居装饰',
    '手工制作',
    '读书笔记',
    '音乐分享',
    '电影推荐',
    '咖啡时光',
    '夕阳美景',
    '街拍摄影',
    '花草植物',
    '甜品烘焙',
    '艺术创作',
    '心情随笔'
  ];

  // 获取主题色
  Color get themeColor => widget.themeColor ?? Theme.of(context).primaryColor;

  @override
  void initState() {
    super.initState();
    // 设置默认标题
    _titleController.text = '请帮我想想文案:D';
    _loadDraftIfNeeded();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // 加载草稿内容
  Future<void> _loadDraftIfNeeded() async {
    if (widget.draftId != null) {
      setState(() {
        _isLoadingDraft = true;
      });

      try {
        final draft = DraftService.getCaptionDraft(widget.draftId!);
        if (draft != null) {
          await _loadDraftContent(draft);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('加载草稿失败: $e')),
          );
        }
      }

      setState(() {
        _isLoadingDraft = false;
      });
    } else {
      // 如果没有指定草稿ID，尝试加载最新的草稿
      _loadLatestDraft();
    }
  }

  // 加载最新草稿
  Future<void> _loadLatestDraft() async {
    try {
      final latestDraft = DraftService.getCurrentCaptionDraft();
      if (latestDraft != null) {
        await _loadDraftContent(latestDraft);
      }
    } catch (e) {
      print('加载最新草稿失败: $e');
    }
  }

  // 加载草稿内容到编辑器
  Future<void> _loadDraftContent(DraftModel draft) async {
    _currentDraftId = draft.id;
    // 只有草稿有标题时才覆盖默认标题
    if (draft.title.isNotEmpty) {
      _titleController.text = draft.title;
    }
    _descriptionController.text = draft.description;
    _selectedTopics = List.from(draft.topics);

    // 加载草稿图片
    _draftImages.clear();
    for (final imagePath in draft.imagePaths) {
      final file = await DraftService.getImageFile(imagePath);
      if (file != null) {
        _draftImages.add(file);
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  // 从相册选择图片
  Future<void> _pickImageFromGallery() async {
    // 检查当前图片总数（草稿图片 + 已选择图片）
    final currentImageCount = _draftImages.length + _selectedAssets.length;
    if (currentImageCount >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('最多只能上传3张图片，因为开发者太穷了:)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final List<AssetEntity>? assets = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          maxAssets: 3 - _draftImages.length, // 动态计算可选择的图片数量
          selectedAssets: _selectedAssets,
          requestType: RequestType.image,
          textDelegate: const AssetPickerTextDelegate(),
          themeColor: themeColor, // 使用主题色
        ),
      );
      
      if (assets != null) {
        setState(() {
          _selectedAssets = assets;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择图片失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果正在加载草稿，显示加载指示器
    if (_isLoadingDraft) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: themeColor),
              const SizedBox(height: 16),
              const Text('正在加载草稿...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片选择区域
            _buildImageSelector(),
            const SizedBox(height: 24),
            
            // 标题输入
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: '请输入标题',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: themeColor, width: 2),
                ),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: themeColor),
                ),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            // 正文输入
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: '输入需求：）',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: themeColor, width: 2),
                ),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: themeColor),
                ),
              ),
              style: const TextStyle(fontSize: 16),
              maxLines: null,
              minLines: 3,
            ),
            const SizedBox(height: 24),
            
            // 标签区域
            TopicSelectorWidget(
              themeColor: themeColor,
              selectedTopics: _selectedTopics,
              onTopicsChanged: (topics) {
                setState(() {
                  _selectedTopics = topics;
                });
              },
              recommendedTopics: _recommendedTopics,
            ),
            const SizedBox(height: 24),
            
            // 底部留出空间给发布按钮
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // 构建图片选择器
  Widget _buildImageSelector() {
    // 合并草稿图片和新选择的图片
    List<Widget> imageWidgets = [];
    
    // 计算当前图片总数
    final currentImageCount = _draftImages.length + _selectedAssets.length;
    final canAddMore = currentImageCount < 3;
    
    // 添加草稿中的图片
    for (int i = 0; i < _draftImages.length; i++) {
      final imageFile = _draftImages[i];
      imageWidgets.add(
        Container(
          width: 100,
          height: 100,
          margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeColor.withOpacity(0.5), width: 2),
          ),
          child: Stack(
            children: [
              // 显示草稿图片
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  imageFile,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              // 删除按钮
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _draftImages.removeAt(i);
                    });
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
              // 草稿标识
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '草稿',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // 添加新选择的图片
    for (int i = 0; i < _selectedAssets.length; i++) {
      final asset = _selectedAssets[i];
      imageWidgets.add(
        Container(
          width: 100,
          height: 100,
          margin: EdgeInsets.only(left: (imageWidgets.isEmpty && i == 0) ? 0 : 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeColor.withOpacity(0.5), width: 2),
          ),
          child: Stack(
            children: [
              // 图片缩略图
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AssetEntityImage(
                  asset,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              // 删除按钮
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAssets.remove(asset);
                    });
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 图片数量提示
        if (currentImageCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '已选择 $currentImageCount/3 张图片${canAddMore ? '' : ' (已达上限)'}',
              style: TextStyle(
                fontSize: 12,
                color: canAddMore ? Colors.grey[600] : themeColor,
                fontWeight: canAddMore ? FontWeight.normal : FontWeight.bold,
              ),
            ),
          ),
        
        // 显示图片（草稿图片 + 新选择的图片）
        if (imageWidgets.isNotEmpty)
          Container(
            height: 100,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...imageWidgets,
                // 添加图片按钮（只有在未达到上限时显示）
                if (canAddMore)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: GestureDetector(
                      onTap: _pickImageFromGallery,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: themeColor.withOpacity(0.5), width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              size: 32,
                              color: themeColor,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '添加图片',
                              style: TextStyle(
                                fontSize: 10,
                                color: themeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          )
        else
          // 如果没有图片，只显示添加按钮
          Row(
            children: [
              GestureDetector(
                onTap: _pickImageFromGallery,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: themeColor.withOpacity(0.5), width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        size: 32,
                        color: themeColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // 构建底部栏
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            // 存草稿按钮
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _showSaveDraftDialog,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.drafts_outlined),
                  const SizedBox(width: 10),
                  const Text('存草稿', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            
            const Spacer(),
            
            // 发布笔记按钮
            SizedBox(
              width: 270,
              height: 45,
              child: ElevatedButton(
                onPressed: _publishPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('发布帖子', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 显示存草稿确认弹窗
  void _showSaveDraftDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '确认保存至草稿箱吗？',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '当前内容将保存到草稿箱，你可以稍后继续编辑。',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '取消',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // 关闭对话框
              _saveDraft();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '保存',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // 保存草稿
  void _saveDraft() async {
    try {
      // 检查是否有内容可以保存
      if (isContentEmpty()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('没有内容可以保存')),
        );
        return;
      }

      // 显示保存中提示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  '保存中...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // 准备已存在的图片路径
      List<String> existingImagePaths = _draftImages.map((file) => file.path).toList();

      // 保存草稿
      final draft = await DraftService.saveCaptionDraft(
        draftId: _currentDraftId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        topics: _selectedTopics,
        selectedAssets: _selectedAssets,
        existingImagePaths: existingImagePaths, // 传递已存在的图片路径
      );

      _currentDraftId = draft.id;

      // 关闭保存中提示
      if (mounted) {
        Navigator.of(context).pop();
      }

      // 显示保存成功提示
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: themeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Text(
                    '保存成功',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // 延迟返回主页面
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          Navigator.of(context).pop(); // 关闭提示对话框
          // 使用回调或简单返回
          if (widget.onBack != null) {
            widget.onBack!();
          } else {
            // 如果没有回调，尝试 pop 一次
            Navigator.of(context).pop();
          }
        }
      });

    } catch (e) {
      // 关闭保存中提示
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存草稿失败: $e')),
        );
      }
    }
  }

  // 检查内容是否为空
  bool isContentEmpty() {
    // 检查标题是否为默认标题
    final isDefaultTitle = _titleController.text.trim() == '请帮我想想文案:D';
    
    return isDefaultTitle && 
           _descriptionController.text.trim().isEmpty && 
           _selectedTopics.isEmpty && 
           _selectedAssets.isEmpty &&
           _draftImages.isEmpty;
  }

  // 静默保存草稿（不显示UI提示）
  Future<void> saveDraftSilently() async {
    try {
      // 准备已存在的图片路径
      List<String> existingImagePaths = _draftImages.map((file) => file.path).toList();

      // 保存草稿
      final draft = await DraftService.saveCaptionDraft(
        draftId: _currentDraftId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        topics: _selectedTopics,
        selectedAssets: _selectedAssets,
        existingImagePaths: existingImagePaths,
      );

      _currentDraftId = draft.id;
    } catch (e) {
      print('静默保存草稿失败: $e');
    }
  }

  // 发布帖子
  Future<void> _publishPost() async {
    try {
      // 验证必填内容 - 只检查标题是否为空
      if (_titleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入标题')),
        );
        return;
      }

      // 检查是否有图片
      List<File> allImages = [];
      
      // 添加草稿中的图片
      allImages.addAll(_draftImages);
      
      // 添加新选择的图片
      for (final asset in _selectedAssets) {
        final file = await asset.file;
        if (file != null) {
          allImages.add(file);
        }
      }

      if (allImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请至少选择一张图片')),
        );
        return;
      }

      // 创建帖子数据
      final postData = PostModel(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
        topics: _selectedTopics,
        images: allImages,
        source: PostSource.captionSuggest,
        createdAt: DateTime.now(),
        // 新字段使用默认值，会自动生成ID
      );

      // 保存帖子到笔记
      final savedPostData = await NotesService.savePostAsNote(postData);

      // 清空当前草稿
      await DraftService.clearAllCaptionDrafts();

      // 使用回调显示帖子详情页面，传递更新后的PostModel
      if (widget.onPostPublished != null) {
        widget.onPostPublished!(savedPostData);
      } else {
        // 如果没有回调，使用导航（向下兼容）
        if (mounted) {
          Navigator.pushReplacementNamed(
            context, 
            '/post_view',
            arguments: savedPostData,
          );
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发布失败: $e')),
        );
      }
    }
  }
} 