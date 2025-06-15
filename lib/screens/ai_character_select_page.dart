import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import '../services/ai_service.dart';
import '../utils/responsive_utils.dart';

class AICharacterSelectPage extends StatefulWidget {
  final Color? themeColor;
  
  const AICharacterSelectPage({super.key, this.themeColor});

  @override
  State<AICharacterSelectPage> createState() => AICharacterSelectPageState();
}

class AICharacterSelectPageState extends State<AICharacterSelectPage> {
  bool _isRandomMode = false; // 默认为自定义模式
  Set<int> _selectedCharacters = {}; // 选中的角色索引
  List<Map<String, dynamic>> _randomSelectedCharacters = []; // 随机选中的角色

  // 获取当前主题色
  Color get _themeColor => widget.themeColor ?? Theme.of(context).colorScheme.primary;

  // 模拟AI角色数据
  final List<Map<String, dynamic>> _aiCharacters = [
    {
      'name': '混沌原体Y',
      'description': '生于冰火鸿沟的无名之源，一切视角的起点与终点。',
      'personality': '"我看，个个都好"',
      'avatarColor': Colors.deepPurple,
      'avatar': 'assets/images/AI/混沌原体Y.png',
    },
    {
      'name': '烧起来不顾后果',
      'description': '余烬中的第一声爆炸，情绪永远在前，后果在后。',
      'personality': '"这张表情够拽！配文：\'就喜欢你看不惯我又干不掉我的样子\'。"',
      'avatarColor': Colors.red,
      'avatar': 'assets/images/AI/烧起来不顾后果.png',
    },
    {
      'name': '零下社交圈',
      'description': '无情的拆台机器，但是善良。',
      'personality': '"第三章的滤镜遮住了黑眼圈……但确实好看，发吧。"',
      'avatarColor': Colors.cyan,
      'avatar': 'assets/images/AI/零下社交圈.png',
    },
    {
      'name': '松软贴贴球',
      'description': '柔软是一种武器，用轻触代替言语的共情体。',
      'personality': '"啊啊啊这张笑得好甜！想捏脸！配文：\'今日份可爱已加载\'。"',
      'avatarColor': Colors.pink,
      'avatar': 'assets/images/AI/松软贴贴球.png',
    },
    {
      'name': '中土',
      'description': 'Ymir的睫毛所限之地，总能发现奇怪的细节。',
      'personality': '"你背后那人的表情好搞笑，他是不是在翻白眼？"',
      'avatarColor': Colors.brown,
      'avatar': 'assets/images/AI/中土.png',
    },
    {
      'name': '左右互搏王',
      'description': '生于腋下的对话体人格，永远在自我拉扯中找到黄金中值。',
      'personality': '"M：这张光线好；W：但那张显瘦……算了，抓阄吧。"',
      'avatarColor': Colors.amber,
      'avatar': 'assets/images/AI/左右互搏王.png',
    },
    {
      'name': '阴云之脑',
      'description': 'Ymir脑中逸出的雾气，谜语人。',
      'personality': '"……有意思。"',
      'avatarColor': Colors.blueGrey,
      'avatar': 'assets/images/AI/阴云之脑.png',
    },
    {
      'name': '天空罐头',
      'description': '从巨人头骨中凿出的穹顶，喜欢大场面，背景如刀锋般锋利，人物如奶油般划开。',
      'personality': '"第五张风景很绝，发！"',
      'avatarColor': Colors.lightBlue,
      'avatar': 'assets/images/AI/天空罐头.png',
    },
    {
      'name': '山脊之骨',
      'description': '白骨成山，逻辑清晰，是冷静中的秩序派代表。',
      'personality': '"这张构图符合三分法则，点赞率预估+20%"',
      'avatarColor': Colors.grey,
      'avatar': 'assets/images/AI/山脊之骨.png',
    },
    {
      'name': '红潮之下',
      'description': '海洋般的情绪流动者，温柔且汹涌，情绪波动即美感本身。',
      'personality': '"这张夕阳的氛围绝了！配文：\'今天的心是橘子汽水做的\'。"',
      'avatarColor': Colors.redAccent,
      'avatar': 'assets/images/AI/红潮之下.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // 加载设置
  Future<void> _loadSettings() async {
    final isRandomMode = await AIService.getRandomMode();
    setState(() {
      _isRandomMode = isRandomMode;
      if (!_isRandomMode) {
        // 自定义模式默认全选
        _selectedCharacters = Set<int>.from(List.generate(_aiCharacters.length, (index) => index));
      }
    });
    
    // 加载已保存的选择
    await _loadSavedSelections();
  }
  
  // 加载已保存的选择
  Future<void> _loadSavedSelections() async {
    final selectedAIs = await AIService.getSelectedAIFriends();
    
    if (_isRandomMode) {
      // 随机模式：根据保存的AI重建随机选择列表
      _randomSelectedCharacters = selectedAIs;
    } else {
      // 自定义模式：重建选择的索引集合
      final selectedIndices = <int>{};
      for (final selectedAI in selectedAIs) {
        final index = _aiCharacters.indexWhere((ai) => ai['name'] == selectedAI['name']);
        if (index != -1) {
          selectedIndices.add(index);
        }
      }
      setState(() {
        _selectedCharacters = selectedIndices;
      });
    }
    
    // 如果随机模式下没有保存的选择，则生成新的随机选择
    if (_isRandomMode && _randomSelectedCharacters.isEmpty) {
      _generateRandomSelection();
    }
  }

  // 随机选择6个AI角色
  void _generateRandomSelection() {
    final shuffled = List<Map<String, dynamic>>.from(_aiCharacters);
    shuffled.shuffle();
    _randomSelectedCharacters = shuffled.take(6).toList();
    
    // 保存随机选择的AI索引到持久化存储
    final randomIndices = _randomSelectedCharacters.map((character) {
      return _aiCharacters.indexWhere((ai) => ai['name'] == character['name']);
    }).where((index) => index != -1).toSet();
    
    AIService.saveSelectedAIFriends(randomIndices);
  }

  // 切换角色选择状态
  void _toggleCharacterSelection(int index) {
    setState(() {
      if (_selectedCharacters.contains(index)) {
        _selectedCharacters.remove(index);
      } else {
        // 检查是否已经选择了6个角色
        if (_selectedCharacters.length < 6) {
          _selectedCharacters.add(index);
        } else {
          // 显示提示信息
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('最多只能选择6个AI角色'),
              backgroundColor: _themeColor,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
      }
    });
    // 保存选择状态
    AIService.saveSelectedAIFriends(_selectedCharacters);
  }

  // 切换模式
  void _toggleMode(bool value) {
    setState(() {
      _isRandomMode = value;
      if (value) {
        // 切换到随机模式时重新生成随机选择
        _generateRandomSelection();
      }
    });
    // 保存模式设置
    AIService.saveRandomMode(_isRandomMode);
  }

  // 显示角色详细信息
  void _showCharacterDetails(Map<String, dynamic> character, int currentIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int dialogCurrentIndex = currentIndex; // 弹窗内部的当前索引
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // 获取当前显示的角色列表
            final currentList = _isRandomMode ? _randomSelectedCharacters : _aiCharacters;
            final currentCharacter = _isRandomMode 
                ? _randomSelectedCharacters[dialogCurrentIndex]
                : _aiCharacters[dialogCurrentIndex];
            
            return Stack(
              children: [
                // 主弹窗
                Center(
                  child: Dialog(
                    backgroundColor: Colors.transparent, // 透明背景
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      height: MediaQuery.of(context).size.height * 0.7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // 关闭按钮
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: IconButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // 角色头像
                                  _buildDialogCharacterAvatar(currentCharacter, size: 120),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // 角色名称
                                  Text(
                                    currentCharacter['name'],
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // 角色描述
                                  Text(
                                    currentCharacter['description'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.9),
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // 性格特点标题
                                  Text(
                                    'TA说',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.95),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // 性格特点内容
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Text(
                                        currentCharacter['personality'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.85),
                                          height: 1.6,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // 上箭头 - 磨砂玻璃效果
                if (dialogCurrentIndex > 0)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.05, // 在弹窗上方
                    left: MediaQuery.of(context).size.width / 2 - 25, // 水平居中
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                dialogCurrentIndex = dialogCurrentIndex - 1;
                              });
                            },
                            icon: const Icon(
                              Icons.keyboard_arrow_up,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // 下箭头 - 磨砂玻璃效果
                if (dialogCurrentIndex < currentList.length - 1)
                  Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.05, // 在弹窗下方
                    left: MediaQuery.of(context).size.width / 2 - 25, // 水平居中
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                dialogCurrentIndex = dialogCurrentIndex + 1;
                              });
                            },
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // 检查是否有选中的AI好友
  bool hasSelectedFriends() {
    if (_isRandomMode) {
      return _randomSelectedCharacters.isNotEmpty;
    } else {
      return _selectedCharacters.isNotEmpty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _themeColor.withOpacity(0.25),
              _themeColor.withOpacity(0.08),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 模式切换区域
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('自定义', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Switch(
                      value: _isRandomMode,
                      onChanged: _toggleMode,
                      activeColor: _themeColor,
                      activeTrackColor: _themeColor.withOpacity(0.3),
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.grey.withOpacity(0.3),
                    ),
                    const SizedBox(width: 8),
                    const Text('随机', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              
              // 分隔线
              const Divider(),
              
              // 模式说明文字
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  _isRandomMode 
                      ? '随机模式：系统已随机选择6位AI好友为你生成评论' 
                      : '自定义模式：点击头像选择/取消选择AI好友，点击箭头查看详细信息',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ),
              
              // 随机模式下的随机角色展示
              if (_isRandomMode)
                _buildRandomModeWidget(),
              
              // 自定义模式下的角色列表
              if (!_isRandomMode)
                _buildCustomModeWidget(),
            ],
          ),
        ),
      ),
    );
  }
  
  // 随机模式界面
  Widget _buildRandomModeWidget() {
    // 获取响应式列数
    final crossAxisCount = ResponsiveUtils.getResponsiveColumns(context, 2);
    final responsivePadding = ResponsiveUtils.getResponsivePadding(context, 16);
    final responsiveSpacing = ResponsiveUtils.getResponsivePadding(context, 12);
    
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(responsivePadding),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _generateRandomSelection();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _themeColor,
                foregroundColor: Colors.white,
                elevation: 3,
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getResponsivePadding(context, 24), 
                  vertical: ResponsiveUtils.getResponsivePadding(context, 12)
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '重新随机选择',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                ),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: responsivePadding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount, // 使用响应式列数
                childAspectRatio: ResponsiveUtils.isTablet(context) ? 1.1 : 1.2, // iPad上稍微调整比例
                crossAxisSpacing: responsiveSpacing,
                mainAxisSpacing: responsiveSpacing,
              ),
              itemCount: _randomSelectedCharacters.length,
              itemBuilder: (context, index) {
                final character = _randomSelectedCharacters[index];
                return _buildRandomCharacterCard(character, index);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  // 自定义模式界面
  Widget _buildCustomModeWidget() {
    final responsivePadding = ResponsiveUtils.getResponsivePadding(context, 16);
    final buttonPadding = ResponsiveUtils.getResponsivePadding(context, 20);
    final fontSize = ResponsiveUtils.getResponsiveFontSize(context, 16);
    
    return Expanded(
      child: Column(
        children: [
          // 全选/全不选按钮
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsivePadding, 
              vertical: ResponsiveUtils.getResponsivePadding(context, 8)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      // 全选所有角色
                      _selectedCharacters = Set<int>.from(
                          List.generate(_aiCharacters.length, (index) => index));
                    });
                    // 保存选择状态
                    AIService.saveSelectedAIFriends(_selectedCharacters);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: _themeColor,
                    backgroundColor: _themeColor.withOpacity(0.2),
                    padding: EdgeInsets.symmetric(
                      horizontal: buttonPadding, 
                      vertical: ResponsiveUtils.getResponsivePadding(context, 10)
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '全选',
                    style: TextStyle(fontSize: fontSize),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCharacters.clear();
                    });
                    // 保存选择状态
                    AIService.saveSelectedAIFriends(_selectedCharacters);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: _themeColor,
                    backgroundColor: _themeColor.withOpacity(0.1),
                    padding: EdgeInsets.symmetric(
                      horizontal: buttonPadding, 
                      vertical: ResponsiveUtils.getResponsivePadding(context, 10)
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '全不选',
                    style: TextStyle(fontSize: fontSize),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _aiCharacters.length,
              itemBuilder: (context, index) {
                final character = _aiCharacters[index];
                final isSelected = _selectedCharacters.contains(index);
                final canSelect = _selectedCharacters.length < 6 || isSelected;
                return _buildCharacterCard(character, index, isSelected, canSelect);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  // 随机模式角色卡片
  Widget _buildRandomCharacterCard(Map<String, dynamic> character, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.15),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.08),
                ],
              ),
            ),
            child: InkWell(
              onTap: () => _showCharacterDetails(character, index),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCharacterAvatar(character, size: 50),
                    const SizedBox(height: 8),
                    Text(
                      character['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      character['description'],
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // 自定义模式角色卡片
  Widget _buildCharacterCard(Map<String, dynamic> character, int index, bool isSelected, [bool canSelect = true]) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.15),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSelected ? [
                  Colors.white.withOpacity(0.18),
                  Colors.white.withOpacity(0.12),
                ] : canSelect ? [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.05),
                ] : [
                  Colors.grey.withOpacity(0.05),
                  Colors.grey.withOpacity(0.03),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: canSelect ? () => _toggleCharacterSelection(index) : null,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isSelected ? 1.0 : canSelect ? 0.4 : 0.2,
                      child: _buildCharacterAvatar(character),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isSelected ? 1.0 : canSelect ? 0.6 : 0.3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            character['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.black : canSelect ? Colors.grey[600] : Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            character['description'],
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected ? Colors.grey[700] : canSelect ? Colors.grey[500] : Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showCharacterDetails(character, index),
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: isSelected ? Colors.grey[600] : canSelect ? Colors.grey[400] : Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // 角色头像
  Widget _buildCharacterAvatar(Map<String, dynamic> character, {double size = 60}) {
    // 检查是否有图片路径
    final hasImage = character['avatar'] != null;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: character['avatarColor'],
      ),
      child: hasImage
          ? ClipOval(
              child: Transform.translate(
                offset: const Offset(0, 5.2), // 图片向下偏移5像素，可以调整这个值
                child: Transform.scale(
                  scale: 1.1, // 图片缩放比例，1.0为原始大小，大于1.0放大，小于1.0缩小
                  child: Image.asset(
                    character['avatar'],
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                    errorBuilder: (context, error, stackTrace) {
                      // 图片加载失败时显示文字头像
                      return Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: character['avatarColor'],
                        ),
                        child: Center(
                          child: Text(
                            character['name'][0],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: size * 0.4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                character['name'][0],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }

  // 自定义对话框角色头像
  Widget _buildDialogCharacterAvatar(Map<String, dynamic> character, {double size = 120}) {
    // 检查是否有图片路径
    final hasImage = character['avatar'] != null;
    
    return Container(
      constraints: BoxConstraints(
        maxWidth: size,
        maxHeight: size,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16), // 圆角边框
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: hasImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16), // 确保图片也是圆角
              child: Image.asset(
                character['avatar'],
                fit: BoxFit.contain, // 显示完整图片，保持原始比例
                errorBuilder: (context, error, stackTrace) {
                  // 图片加载失败时显示文字头像
                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: character['avatarColor'],
                    ),
                    child: Center(
                      child: Text(
                        character['name'][0],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size * 0.4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          : Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: character['avatarColor'],
              ),
              child: Center(
                child: Text(
                  character['name'][0],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
    );
  }
} 