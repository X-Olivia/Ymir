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
  final Function(PostModel)? onNavigateToPost; // Callback for navigating to a post
  final Function(DraftModel, bool)? onNavigateToDraft; // Callback for navigating to a draft
  
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
  
  // Gender selection
  String _selectedGender = 'none'; // 'male', 'female', 'none', 'alien', 'robot', 'cat', 'star'
  
  // Mock user statistics
  int _followingCount = 274;
  int _followersCount = 38;
  int _likesCount = 380;
  
  // Available avatar colors
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

  // Tab controller
  late TabController _tabController;
  
  // Post state
  List<Map<String, dynamic>> _notes = [];
  bool _isLoadingNotes = false;
  
  // Draft state
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
    // Initialize the tab controller
    _tabController = TabController(length: 2, vsync: this);
  }

  // Load user information
  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await UserService.getUserInfo();
      setState(() {
        _nicknameController.text = userInfo['nickname'];
        _avatarPlaceholder = userInfo['avatarPlaceholder'];
        _avatarColor = widget.themeColor ?? Colors.blue;
        _selectedAvatarPath = userInfo['avatarPath'];
        _ymirId = userInfo['ymirId'];
        _selectedGender = userInfo['gender'] ?? 'none'; // Load the gender setting
        _isLoading = false;
        
        // Mock loading other information
        _bioController.text = 'Personal bio.';
      });
    } catch (e) {
      print('Failed to load user information: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load posts
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
      print('Failed to load posts: $e');
      setState(() {
        _isLoadingNotes = false;
      });
    }
  }

  // Load drafts
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
      print('Failed to load drafts: $e');
      setState(() {
        _isLoadingDrafts = false;
      });
    }
  }

  // Delete a post
  Future<void> _deleteNote(String noteId) async {
    try {
      await NotesService.deleteNote(noteId);
      await _loadNotes(); // Reload the post list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Post deleted'),
            backgroundColor: _avatarColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Delete a draft
  Future<void> _deleteDraft(DraftModel draft, bool isCaptionDraft) async {
    try {
      if (isCaptionDraft) {
        await DraftService.deleteCaptionDraft(draft.id);
      } else {
        await DraftService.deleteDraft(draft.id);
      }
      
      // Reload the draft list
      await _loadDrafts();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft deleted')),
      );
    } catch (e) {
      print('Failed to delete draft: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete draft')),
      );
    }
  }

  // Navigate to post details when a post is tapped
  void _handleNoteTap(Map<String, dynamic> note) async {
    // Create a PostModel with NotesService.createPostFromNote
    final post = await NotesService.createPostFromNote(note);
    
    if (post == null) {
      // Show an error if creation fails, for example when an image file is missing
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to open the post. Its image file may be missing.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // Use the callback to navigate within the embedded view
    if (widget.onNavigateToPost != null) {
      widget.onNavigateToPost!(post);
    } else {
      // Backward compatibility: use standard navigation when no callback is provided
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

  // Handle a draft tap
  void _handleDraftTap(DraftModel draft, bool isCaptionDraft) {
    if (widget.onNavigateToDraft != null) {
      widget.onNavigateToDraft!(draft, isCaptionDraft);
    }
  }

  // Save user information
  Future<void> _saveUserInfo() async {
    try {
      await UserService.saveUserInfo(
        nickname: _nicknameController.text.trim(),
        avatarPlaceholder: _avatarPlaceholder,
        avatarColor: widget.themeColor ?? Colors.blue,
        avatarPath: _selectedAvatarPath,
        gender: _selectedGender, // Save the gender setting
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Show the avatar picker
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
  
  // Get the gender icon
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
  
  // Get the gender color
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
  
  // Get the gender label
  String _getGenderText() {
    switch (_selectedGender) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'alien':
        return 'Alien';
      case 'robot':
        return 'Robot';
      case 'cat':
        return 'Cat';
      case 'star':
        return 'Star';
      case 'rainbow':
        return 'Rainbow';
      case 'fire':
        return 'Fire';
      default:
        return 'Prefer not to say';
    }
  }
  
  // Show the gender picker
  Future<void> _showGenderPicker() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => Stack(
        children: [
          // Background blur layer (without dimming)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: Colors.white.withOpacity(0.1), // Slightly brighten the background
              ),
            ),
          ),
          // Dialog
          Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 350,
                maxHeight: 500, // Reduced maximum height
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
                        // Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Just pick one',
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
                        // Option list - use Flexible and ListView for scrolling
                        Flexible(
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              _buildGenderOption('male', Icons.male, Colors.blue, 'Male'),
                              _buildGenderOption('female', Icons.female, Colors.pink, 'Female'),
                              _buildGenderOption('alien', Icons.rocket_launch, Colors.green, 'Alien'),
                              _buildGenderOption('robot', Icons.smart_toy, Colors.grey, 'Robot'),
                              _buildGenderOption('cat', Icons.pets, Colors.orange, 'Cat'),
                              _buildGenderOption('star', Icons.star, Colors.amber, 'Star'),
                              _buildGenderOption('rainbow', Icons.palette, Colors.purple, 'Rainbow'),
                              _buildGenderOption('fire', Icons.local_fire_department, Colors.red, 'Fire'),
                              _buildGenderOption('none', Icons.help_outline, Colors.grey, 'Prefer not to say'),
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

  // Build a gender option
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
  
  // Share the profile
  Future<void> _shareProfile() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile sharing'),
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
              // Custom header
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
                  // Privacy settings button in the top-right corner
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
                          // Avatar and username area
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar area
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
                              
                              // Username and information area
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    // Username and dropdown icon
                                    Row(
                                      children: [
                                        Flexible(
                                          child: GestureDetector(
                                            onTap: () => _showEditDialog(
                                              title: 'Change Nickname',
                                              initialValue: _nicknameController.text,
                                              hintText: 'Enter a nickname',
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
                                                  : 'Username',
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
                                    
                                    // User ID
                                    Text(
                                      'Ymir ID: $_ymirId',
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
                          
                          // Gender and share button row
                          Row(
                            children: [
                              const SizedBox(width: 6),
                              // Share button
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
                                        'Share',
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
                              // Gender selector
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
                          
                          // Bio
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: GestureDetector(
                              onTap: () => _showEditDialog(
                                title: 'Edit Bio',
                                initialValue: _bioController.text,
                                hintText: 'Tell us about yourself...',
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

              // Unified content container
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
                      // Top accent bar
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
                          Tab(text: 'Posts'),
                          Tab(text: 'Drafts'),
                        ],
                      ),
                      // TabBarView content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Post content
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  // Post list or empty state
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
                                                      'No posts yet',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.grey[500],
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Published posts will be saved here automatically',
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
                                                    childAspectRatio: 0.85, // Adjust the aspect ratio
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
                            // Draft content
                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: _isLoadingDrafts
                                  ? const Center(child: CircularProgressIndicator())
                                  : _imageDrafts.isEmpty && _captionDrafts.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'No drafts yet',
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
                                                // Display an image draft
                                                final draft = _imageDrafts[index];
                                                return DraftItemWidget(
                                                  draft: draft,
                                                  themeColor: _avatarColor,
                                                  onTap: () => _handleDraftTap(draft, false),
                                                  onDelete: () => _deleteDraft(draft, false),
                                                );
                                              } else {
                                                // Display a text draft
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

  // Show the edit dialog
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

  // Show the delete confirmation dialog
  Future<void> _showDeleteConfirmDialog(String noteId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteNote(noteId);
    }
  }
} 