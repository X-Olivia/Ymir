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
  bool _isRandomMode = false; // Custom mode by default
  Set<int> _selectedCharacters = {}; // Indices of selected characters
  List<Map<String, dynamic>> _randomSelectedCharacters = []; // Randomly selected characters

  // Get the current theme color
  Color get _themeColor => widget.themeColor ?? Theme.of(context).colorScheme.primary;

  // Mock AI character data
  final List<Map<String, dynamic>> _aiCharacters = [
    {
      'name': 'Primordial Chaos Y',
      'description': 'A nameless source born in the chasm between ice and fire, the beginning and end of every perspective.',
      'personality': '"They all look good to me."',
      'avatarColor': Colors.deepPurple,
      'avatar': 'assets/images/AI/\u6df7\u6c8c\u539f\u4f53Y.png',
    },
    {
      'name': 'Burn First, Consequences Later',
      'description': 'The first blast among the embers, always putting emotion before consequences.',
      'personality': '"That expression has attitude! Caption: \'I love how you can\'t stand me but can\'t do anything about it.\'"',
      'avatarColor': Colors.red,
      'avatar': 'assets/images/AI/\u70e7\u8d77\u6765\u4e0d\u987e\u540e\u679c.png',
    },
    {
      'name': 'Subzero Social Circle',
      'description': 'A merciless bubble-burster with a kind heart.',
      'personality': '"The filter in the third one hides the dark circles... but it does look good. Post it."',
      'avatarColor': Colors.cyan,
      'avatar': 'assets/images/AI/\u96f6\u4e0b\u793e\u4ea4\u5708.png',
    },
    {
      'name': 'Soft Snuggle Ball',
      'description': 'An empath who wields softness as a weapon and replaces words with a gentle touch.',
      'personality': '"Aww, that smile is so sweet! I want to pinch those cheeks! Caption: \'Today\'s dose of cuteness: loaded.\'"',
      'avatarColor': Colors.pink,
      'avatar': 'assets/images/AI/\u677e\u8f6f\u8d34\u8d34\u7403.png',
    },
    {
      'name': 'Middle Earth',
      'description': 'The realm bounded by Ymir\'s eyelashes, always spotting the strangest details.',
      'personality': '"The person behind you is making such a funny face. Are they rolling their eyes?"',
      'avatarColor': Colors.brown,
      'avatar': 'assets/images/AI/\u4e2d\u571f.png',
    },
    {
      'name': 'King of Inner Conflict',
      'description': 'A conversational persona born beneath the arms, forever finding the golden mean through internal conflict.',
      'personality': '"M: The lighting is better in this one. W: But that one makes you look slimmer... Forget it, let\'s draw lots."',
      'avatarColor': Colors.amber,
      'avatar': 'assets/images/AI/\u5de6\u53f3\u4e92\u640f\u738b.png',
    },
    {
      'name': 'Clouded Mind',
      'description': 'Mist drifting out of Ymir\'s mind, speaking only in riddles.',
      'personality': '"...Interesting."',
      'avatarColor': Colors.blueGrey,
      'avatar': 'assets/images/AI/\u9634\u4e91\u4e4b\u8111.png',
    },
    {
      'name': 'Canned Sky',
      'description': 'A dome carved from a giant\'s skull, drawn to epic scenes where backgrounds cut like blades and figures part like cream.',
      'personality': '"The scenery in the fifth one is incredible. Post it!"',
      'avatarColor': Colors.lightBlue,
      'avatar': 'assets/images/AI/\u5929\u7a7a\u7f50\u5934.png',
    },
    {
      'name': 'Ridgebone',
      'description': 'White bones piled into mountains, clear-minded and a champion of order under pressure.',
      'personality': '"This composition follows the rule of thirds. Estimated likes: +20%."',
      'avatarColor': Colors.grey,
      'avatar': 'assets/images/AI/\u5c71\u810a\u4e4b\u9aa8.png',
    },
    {
      'name': 'Beneath the Red Tide',
      'description': 'An oceanic current of emotion, gentle yet surging, finding beauty in every emotional wave.',
      'personality': '"The mood in this sunset is perfect! Caption: \'My heart is made of orange soda today.\'"',
      'avatarColor': Colors.redAccent,
      'avatar': 'assets/images/AI/\u7ea2\u6f6e\u4e4b\u4e0b.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load settings
  Future<void> _loadSettings() async {
    final isRandomMode = await AIService.getRandomMode();
    setState(() {
      _isRandomMode = isRandomMode;
      if (!_isRandomMode) {
        // Select all by default in custom mode
        _selectedCharacters = Set<int>.from(List.generate(_aiCharacters.length, (index) => index));
      }
    });
    
    // Load the saved selection
    await _loadSavedSelections();
  }
  
  // Load the saved selection
  Future<void> _loadSavedSelections() async {
    final selectedAIs = await AIService.getSelectedAIFriends();
    
    if (_isRandomMode) {
      // Random mode: rebuild the random selection from saved AI characters
      _randomSelectedCharacters = selectedAIs;
    } else {
      // Custom mode: rebuild the set of selected indices
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
    
    // Generate a new random selection if none was saved in random mode
    if (_isRandomMode && _randomSelectedCharacters.isEmpty) {
      _generateRandomSelection();
    }
  }

  // Randomly select 6 AI characters
  void _generateRandomSelection() {
    final shuffled = List<Map<String, dynamic>>.from(_aiCharacters);
    shuffled.shuffle();
    _randomSelectedCharacters = shuffled.take(6).toList();
    
    // Persist the indices of randomly selected AI characters
    final randomIndices = _randomSelectedCharacters.map((character) {
      return _aiCharacters.indexWhere((ai) => ai['name'] == character['name']);
    }).where((index) => index != -1).toSet();
    
    AIService.saveSelectedAIFriends(randomIndices);
  }

  // Toggle a character's selection state
  void _toggleCharacterSelection(int index) {
    setState(() {
      if (_selectedCharacters.contains(index)) {
        _selectedCharacters.remove(index);
      } else {
        // Check whether 6 characters are already selected
        if (_selectedCharacters.length < 6) {
          _selectedCharacters.add(index);
        } else {
          // Show a message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('You can select up to 6 AI characters'),
              backgroundColor: _themeColor,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
      }
    });
    // Save the selection state
    AIService.saveSelectedAIFriends(_selectedCharacters);
  }

  // Switch modes
  void _toggleMode(bool value) {
    setState(() {
      _isRandomMode = value;
      if (value) {
        // Generate a new random selection when switching to random mode
        _generateRandomSelection();
      }
    });
    // Save the mode setting
    AIService.saveRandomMode(_isRandomMode);
  }

  // Show character details
  void _showCharacterDetails(Map<String, dynamic> character, int currentIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int dialogCurrentIndex = currentIndex; // Current index within the dialog
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Get the currently displayed character list
            final currentList = _isRandomMode ? _randomSelectedCharacters : _aiCharacters;
            final currentCharacter = _isRandomMode 
                ? _randomSelectedCharacters[dialogCurrentIndex]
                : _aiCharacters[dialogCurrentIndex];
            
            return Stack(
              children: [
                // Main dialog
                Center(
                  child: Dialog(
                    backgroundColor: Colors.transparent, // Transparent background
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
                                  // Close button
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
                                  
                                  // Character avatar
                                  _buildDialogCharacterAvatar(currentCharacter, size: 120),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Character name
                                  Text(
                                    currentCharacter['name'],
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Character description
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
                                  
                                  // Personality heading
                                  Text(
                                    'They say',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.95),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // Personality details
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
                
                // Up arrow - frosted-glass effect
                if (dialogCurrentIndex > 0)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.05, // Above the dialog
                    left: MediaQuery.of(context).size.width / 2 - 25, // Center horizontally
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
                
                // Down arrow - frosted-glass effect
                if (dialogCurrentIndex < currentList.length - 1)
                  Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.05, // Below the dialog
                    left: MediaQuery.of(context).size.width / 2 - 25, // Center horizontally
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

  // Check whether any AI friends are selected
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
              // Mode selector
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Custom', style: TextStyle(fontSize: 16)),
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
                    const Text('Random', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              
              // Divider
              const Divider(),
              
              // Mode description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  _isRandomMode 
                      ? 'Random mode: 6 AI friends have been selected at random to generate comments for you'
                      : 'Custom mode: tap an avatar to select or deselect an AI friend, and tap the arrow to view details',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ),
              
              // Random character display in random mode
              if (_isRandomMode)
                _buildRandomModeWidget(),
              
              // Character list in custom mode
              if (!_isRandomMode)
                _buildCustomModeWidget(),
            ],
          ),
        ),
      ),
    );
  }
  
  // Random mode interface
  Widget _buildRandomModeWidget() {
    // Get the responsive column count
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
                'Pick Again',
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
                crossAxisCount: crossAxisCount, // Use the responsive column count
                childAspectRatio: ResponsiveUtils.isTablet(context) ? 1.1 : 1.2, // Slightly adjust the ratio on iPad
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
  
  // Custom mode interface
  Widget _buildCustomModeWidget() {
    final responsivePadding = ResponsiveUtils.getResponsivePadding(context, 16);
    final buttonPadding = ResponsiveUtils.getResponsivePadding(context, 20);
    final fontSize = ResponsiveUtils.getResponsiveFontSize(context, 16);
    
    return Expanded(
      child: Column(
        children: [
          // Select all / deselect all buttons
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
                      // Select all characters
                      _selectedCharacters = Set<int>.from(
                          List.generate(_aiCharacters.length, (index) => index));
                    });
                    // Save the selection state
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
                    'Select All',
                    style: TextStyle(fontSize: fontSize),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCharacters.clear();
                    });
                    // Save the selection state
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
                    'Deselect All',
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
  
  // Random mode character card
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
  
  // Custom mode character card
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
  
  // Character avatar
  Widget _buildCharacterAvatar(Map<String, dynamic> character, {double size = 60}) {
    // Check whether an image path is available
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
                offset: const Offset(0, 5.2), // Shift the image down by 5 pixels; this value can be adjusted
                child: Transform.scale(
                  scale: 1.1, // Image scale: 1.0 is original size, above 1.0 enlarges, below 1.0 shrinks
                  child: Image.asset(
                    character['avatar'],
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                    errorBuilder: (context, error, stackTrace) {
                      // Show a text avatar if the image fails to load
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

  // Character avatar in the custom dialog
  Widget _buildDialogCharacterAvatar(Map<String, dynamic> character, {double size = 120}) {
    // Check whether an image path is available
    final hasImage = character['avatar'] != null;
    
    return Container(
      constraints: BoxConstraints(
        maxWidth: size,
        maxHeight: size,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16), // Rounded border
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
              borderRadius: BorderRadius.circular(16), // Ensure the image also has rounded corners
              child: Image.asset(
                character['avatar'],
                fit: BoxFit.contain, // Show the full image while preserving its aspect ratio
                errorBuilder: (context, error, stackTrace) {
                  // Show a text avatar if the image fails to load
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