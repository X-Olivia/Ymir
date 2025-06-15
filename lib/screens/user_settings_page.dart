import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/user_service.dart';
import '../services/notes_service.dart';
import '../services/draft_service.dart';
import '../models/post_model.dart';
import '../models/draft_model.dart';
import '../widgets/avatar_picker_dialog.dart';
import '../widgets/edit_profile_dialog.dart';
import '../widgets/note_item_widget.dart';
import '../widgets/draft_item_widget.dart';
import 'privacy_settings_page.dart';
import 'post_view_page.dart';
import 'dart:io';

class UserSettingsPage extends StatefulWidget {
  final Color? themeColor;
  final Function(PostModel)? onNavigateToPost; // 添加导航到帖子的回调
  final Function(DraftModel, bool)? onNavigateToDraft; // 添加导航到草稿的回调
  
  const UserSettingsPage({
    super.key,
    this.themeColor,
    this.onNavigateToPost,
    this.onNavigateToDraft,
  });

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> with SingleTickerProviderStateMixin {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String _ymirId = '';
  
  String _avatarPlaceholder = 'U';
  late Color _avatarColor;
  bool _isLoading = true;
  String? _selectedAvatarPath;
  
  // 添加性别选择
  String _selectedGender = 'none'; // 'male', 'female', 'none', 'alien', 'robot', 'cat', 'star'
  
  // 模拟用户统计数据
  int _followingCount = 274;
  int _followersCount = 38;
  int _likesCount = 380;
  
  // 可选的头像颜色
  final List<Color> _avatarColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  // 添加 TabController
  late TabController _tabController;
  
  // 笔记相关状态
  List<Map<String, dynamic>> _notes = [];
  bool _isLoadingNotes = false;
  
  // 草稿相关状态
  List<DraftModel> _imageDrafts = [];
  List<DraftModel> _captionDrafts = [];
  bool _isLoadingDrafts = false;
  
  @override
  void initState() {
    super.initState();
    _avatarColor = widget.themeColor ?? Colors.blue;
    _loadUserInfo();
    _loadNotes();
    _loadDrafts();
    // 初始化 TabController
    _tabController = TabController(length: 2, vsync: this);
  }

  // 加载用户信息
  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await UserService.getUserInfo();
      setState(() {
        _nicknameController.text = userInfo['nickname'];
        _avatarPlaceholder = userInfo['avatarPlaceholder'];
        _avatarColor = widget.themeColor ?? Colors.blue;
        _selectedAvatarPath = userInfo['avatarPath'];
        _ymirId = userInfo['ymirId'];
        _selectedGender = userInfo['gender'] ?? 'none'; // 加载性别设置
        _isLoading = false;
        
        // 模拟加载其他信息
        _bioController.text = '个性签名。';
      });
    } catch (e) {
      print('加载用户信息失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 加载笔记
  Future<void> _loadNotes() async {
    setState(() {
      _isLoadingNotes = true;
    });
    
    try {
      final notes = await NotesService.getAllNotes();
      setState(() {
        _notes = notes;
        _isLoadingNotes = false;
      });
    } catch (e) {
      print('加载笔记失败: $e');
      setState(() {
        _isLoadingNotes = false;
      });
    }
  }

  // 加载草稿
  Future<void> _loadDrafts() async {
    setState(() {
      _isLoadingDrafts = true;
    });

    try {
      final imageDrafts = await DraftService.getAllDrafts();
      final captionDrafts = await DraftService.getAllCaptionDrafts();
      
      setState(() {
        _imageDrafts = imageDrafts;
        _captionDrafts = captionDrafts;
        _isLoadingDrafts = false;
      });
    } catch (e) {
      print('加载草稿失败: $e');
      setState(() {
        _isLoadingDrafts = false;
      });
    }
  }

  // 删除笔记
  Future<void> _deleteNote(String noteId) async {
    try {
      await NotesService.deleteNote(noteId);
      await _loadNotes(); // 重新加载笔记列表
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('笔记已删除'),
            backgroundColor: _avatarColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 删除草稿
  Future<void> _deleteDraft(DraftModel draft, bool isCaptionDraft) async {
    try {
      if (isCaptionDraft) {
        await DraftService.deleteCaptionDraft(draft.id);
      } else {
        await DraftService.deleteDraft(draft.id);
      }
      
      // 重新加载草稿列表
      await _loadDrafts();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('草稿已删除')),
      );
    } catch (e) {
      print('删除草稿失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('删除草稿失败')),
      );
    }
  }

  // 点击笔记，导航到帖子详情页面
  void _handleNoteTap(Map<String, dynamic> note) async {
    // 使用NotesService的createPostFromNote方法创建PostModel
    final post = await NotesService.createPostFromNote(note);
    
    if (post == null) {
      // 如果创建失败（比如图片文件不存在），显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('无法打开笔记，图片文件可能已丢失'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // 使用回调函数进行导航，实现内嵌显示
    if (widget.onNavigateToPost != null) {
      widget.onNavigateToPost!(post);
    } else {
      // 向下兼容：如果没有回调，使用传统导航
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostViewPage(
            postData: post,
            themeColor: widget.themeColor,
          ),
        ),
      );
    }
  }

  // 处理草稿点击
  void _handleDraftTap(DraftModel draft, bool isCaptionDraft) {
    if (widget.onNavigateToDraft != null) {
      widget.onNavigateToDraft!(draft, isCaptionDraft);
    }
  }

  // 保存用户信息
  Future<void> _saveUserInfo() async {
    try {
      await UserService.saveUserInfo(
        nickname: _nicknameController.text.trim(),
        avatarPlaceholder: _avatarPlaceholder,
        avatarColor: widget.themeColor ?? Colors.blue,
        avatarPath: _selectedAvatarPath,
        gender: _selectedGender, // 保存性别设置
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // 显示头像选择弹窗
  Future<void> _showAvatarPicker() async {
    final selectedPath = await showDialog<String>(
      context: context,
      builder: (context) => AvatarPickerDialog(themeColor: _avatarColor),
    );

    if (selectedPath != null) {
      setState(() {
        _selectedAvatarPath = selectedPath;
      });
    }
  }
  
  // 获取性别图标
  IconData _getGenderIcon() {
    switch (_selectedGender) {
      case 'male':
        return Icons.male;
      case 'female':
        return Icons.female;
      case 'alien':
        return Icons.rocket_launch;
      case 'robot':
        return Icons.smart_toy;
      case 'cat':
        return Icons.pets;
      case 'star':
        return Icons.star;
      case 'rainbow':
        return Icons.palette;
      case 'fire':
        return Icons.local_fire_department;
      default:
        return Icons.help_outline;
    }
  }
  
  // 获取性别颜色
  Color _getGenderColor() {
    switch (_selectedGender) {
      case 'male':
        return Colors.blue;
      case 'female':
        return Colors.pink;
      case 'alien':
        return Colors.green;
      case 'robot':
        return Colors.grey;
      case 'cat':
        return Colors.orange;
      case 'star':
        return Colors.amber;
      case 'rainbow':
        return Colors.purple;
      case 'fire':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  // 获取性别文本
  String _getGenderText() {
    switch (_selectedGender) {
      case 'male':
        return '男';
      case 'female':
        return '女';
      case 'alien':
        return '外星人';
      case 'robot':
        return '机器人';
      case 'cat':
        return '猫咪';
      case 'star':
        return '星星';
      case 'rainbow':
        return '彩虹';
      case 'fire':
        return '火焰';
      default:
        return '保密';
    }
  }
  
  // 显示性别选择弹窗
  Future<void> _showGenderPicker() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => Stack(
        children: [
          // 背景模糊层（不变暗）
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: Colors.white.withOpacity(0.1), // 轻微提亮背景
              ),
            ),
          ),
          // 弹窗
          Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 350,
                maxHeight: 500, // 减少最大高度
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.65),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.65),
                          Colors.white.withOpacity(0.45),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 标题
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '选一个就行了',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.grey[700]),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 选项列表 - 使用 Flexible 和 ListView 使其可滚动
                        Flexible(
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              _buildGenderOption('male', Icons.male, Colors.blue, '男'),
                              _buildGenderOption('female', Icons.female, Colors.pink, '女'),
                              _buildGenderOption('alien', Icons.rocket_launch, Colors.green, '外星人'),
                              _buildGenderOption('robot', Icons.smart_toy, Colors.grey, '机器人'),
                              _buildGenderOption('cat', Icons.pets, Colors.orange, '猫咪'),
                              _buildGenderOption('star', Icons.star, Colors.amber, '星星'),
                              _buildGenderOption('rainbow', Icons.palette, Colors.purple, '彩虹'),
                              _buildGenderOption('fire', Icons.local_fire_department, Colors.red, '火焰'),
                              _buildGenderOption('none', Icons.help_outline, Colors.grey, '保密'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _selectedGender = result;
      });
    }
  }

  // 构建性别选项
  Widget _buildGenderOption(String value, IconData icon, Color color, String label) {
    final isSelected = _selectedGender == value;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? _avatarColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? _avatarColor.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? _avatarColor : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: isSelected ? Icon(Icons.check, color: _avatarColor) : null,
        onTap: () => Navigator.pop(context, value),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  // 分享个人资料
  Future<void> _shareProfile() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('个人资料分享功能'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _avatarColor,
      ),
    );
  }
  
  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _avatarColor.withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Scaffold(
      body: WillPopScope(
        onWillPop: () async {
          await _saveUserInfo();
          return true;
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _avatarColor.withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: CustomScrollView(
            slivers: [
              // 自定义顶部区域
              SliverAppBar(
                expandedHeight: 300,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                  onPressed: () async {
                    await _saveUserInfo();
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
                actions: [
                  // 隐私设置按钮在右上角
                  IconButton(
                    icon: Icon(
                      Icons.privacy_tip_outlined,
                      color: _avatarColor,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PrivacySettingsPage(
                            themeColor: _avatarColor,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    padding: const EdgeInsets.fromLTRB(15, 140, 20, 20),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 头像和用户名区域
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 头像区域
                              Stack(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _selectedAvatarPath == null ? _avatarColor : null,
                                      image: _selectedAvatarPath != null ? DecorationImage(
                                        image: AssetImage(_selectedAvatarPath!),
                                        fit: BoxFit.cover,
                                      ) : null,
                                    ),
                                    child: _selectedAvatarPath == null ? Center(
                                      child: Text(
                                        _avatarPlaceholder,
                                        style: const TextStyle(
                                          fontSize: 28,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ) : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _showAvatarPicker,
                                      child: Container(
                                        width: 23,
                                        height: 23,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.edit,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              
                              // 用户名和信息区域
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    // 用户名和下拉图标
                                    Row(
                                      children: [
                                        Flexible(
                                          child: GestureDetector(
                                            onTap: () => _showEditDialog(
                                              title: '修改昵称',
                                              initialValue: _nicknameController.text,
                                              hintText: '请输入昵称',
                                              maxLength: 20,
                                              onConfirm: (value) {
                                                setState(() {
                                                  _nicknameController.text = value;
                                                  if (value.isNotEmpty) {
                                                    _avatarPlaceholder = value[0].toUpperCase();
                                                  }
                                                });
                                              },
                                            ),
                                            child: Text(
                                              _nicknameController.text.isNotEmpty 
                                                  ? _nicknameController.text 
                                                  : '用户昵称',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.keyboard_arrow_down,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // 用户ID
                                    Text(
                                      'Ymir号：$_ymirId',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // 性别和分享按钮行
                          Row(
                            children: [
                              const SizedBox(width: 6),
                              // 分享按钮
                              GestureDetector(
                                onTap: _shareProfile,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _avatarColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.share_outlined,
                                        size: 16,
                                        color: _avatarColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '分享',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // 性别选择
                              GestureDetector(
                                onTap: _showGenderPicker,
                                child: Icon(
                                  _getGenderIcon(),
                                  size: 20,
                                  color: _getGenderColor(),
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // 个性签名
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: GestureDetector(
                              onTap: () => _showEditDialog(
                                title: '修改个性签名',
                                initialValue: _bioController.text,
                                hintText: '介绍一下自己吧...',
                                maxLength: 100,
                                maxLines: 3,
                                onConfirm: (value) {
                                  setState(() {
                                    _bioController.text = value;
                                  });
                                },
                              ),
                              child: Text(
                                _bioController.text,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 统一的内容容器
              SliverFillRemaining(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 顶部装饰条
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // TabBar
                      TabBar(
                        controller: _tabController,
                        labelColor: _avatarColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: _avatarColor,
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.label,
                        tabs: const [
                          Tab(text: '笔记'),
                          Tab(text: '草稿箱'),
                        ],
                      ),
                      // TabBarView 内容
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // 笔记内容
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  // 笔记列表或空状态
                                  Expanded(
                                    child: _isLoadingNotes
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : _notes.isEmpty
                                            ? Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.note_alt_outlined,
                                                      size: 64,
                                                      color: Colors.grey[300],
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      '还没有笔记',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.grey[500],
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      '发布帖子后会自动保存到这里',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[400],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Transform.translate(
                                                offset: const Offset(0, -42),
                                                child: GridView.builder(
                                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: 2,
                                                    crossAxisSpacing: 12,
                                                    mainAxisSpacing: 12,
                                                    childAspectRatio: 0.85, // 调整比例
                                                  ),
                                                  itemCount: _notes.length,
                                                  itemBuilder: (context, index) {
                                                    final note = _notes[index];
                                                    return NoteItemWidget(
                                                      noteData: note,
                                                      themeColor: _avatarColor,
                                                      onTap: () => _handleNoteTap(note),
                                                      onDelete: () => _showDeleteConfirmDialog(note['id']),
                                                    );
                                                  },
                                                ),
                                              ),
                                  ),
                                ],
                              ),
                            ),
                            // 草稿箱内容
                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: _isLoadingDrafts
                                  ? const Center(child: CircularProgressIndicator())
                                  : _imageDrafts.isEmpty && _captionDrafts.isEmpty
                                      ? const Center(
                                          child: Text(
                                            '暂无草稿',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        )
                                      : Transform.translate(
                                          offset: const Offset(0, -42),
                                          child: GridView.builder(
                                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              crossAxisSpacing: 12,
                                              mainAxisSpacing: 12,
                                              childAspectRatio: 0.85,
                                            ),
                                            itemCount: _imageDrafts.length + _captionDrafts.length,
                                            itemBuilder: (context, index) {
                                              if (index < _imageDrafts.length) {
                                                // 显示图片草稿
                                                final draft = _imageDrafts[index];
                                                return DraftItemWidget(
                                                  draft: draft,
                                                  themeColor: _avatarColor,
                                                  onTap: () => _handleDraftTap(draft, false),
                                                  onDelete: () => _deleteDraft(draft, false),
                                                );
                                              } else {
                                                // 显示文字草稿
                                                final draft = _captionDrafts[index - _imageDrafts.length];
                                                return DraftItemWidget(
                                                  draft: draft,
                                                  themeColor: _avatarColor,
                                                  onTap: () => _handleDraftTap(draft, true),
                                                  onDelete: () => _deleteDraft(draft, true),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                            ),
                          ],
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

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingSection(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: _avatarColor),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  // 添加显示编辑弹窗的方法
  Future<void> _showEditDialog({
    required String title,
    required String initialValue,
    required String hintText,
    int? maxLength,
    int? maxLines,
    required Function(String) onConfirm,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => EditProfileDialog(
        title: title,
        initialValue: initialValue,
        hintText: hintText,
        maxLength: maxLength,
        maxLines: maxLines,
        themeColor: _avatarColor,
      ),
    );

    if (result != null) {
      onConfirm(result);
    }
  }

  // 添加显示删除确认对话框的方法
  Future<void> _showDeleteConfirmDialog(String noteId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条笔记吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteNote(noteId);
    }
  }
} 