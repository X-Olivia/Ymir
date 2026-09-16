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
  final String? draftId; // Draft ID for editing an existing draft
  final VoidCallback? onBack; // Back callback
  final Function(PostModel)? onPostPublished; // Publish callback
  
  const CaptionSuggestPage({super.key, this.themeColor, this.draftId, this.onBack, this.onPostPublished});

  @override
  State<CaptionSuggestPage> createState() => CaptionSuggestPageState();
}

class CaptionSuggestPageState extends State<CaptionSuggestPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Selected images
  List<AssetEntity> _selectedAssets = [];
  
  // Selected topics
  List<String> _selectedTopics = [];
  
  // Draft state
  String? _currentDraftId;
  bool _isLoadingDraft = false;
  List<File> _draftImages = []; // Image files loaded from the draft
  
  // Recommended topics
  final List<String> _recommendedTopics = [
    'Daily Life',
    'Food',
    'Travel',
    'Outfits',
    'Landscape Photography',
    'Pets',
    'Fitness',
    'Beauty and Skincare',
    'Home Decor',
    'Crafts',
    'Book Notes',
    'Music',
    'Movie Recommendations',
    'Coffee Time',
    'Sunsets',
    'Street Photography',
    'Plants and Flowers',
    'Desserts and Baking',
    'Art',
    'Personal Reflections'
  ];

  // Get the theme color
  Color get themeColor => widget.themeColor ?? Theme.of(context).primaryColor;

  @override
  void initState() {
    super.initState();
    // Set the default title
    _titleController.text = 'Help me come up with a caption :D';
    _loadDraftIfNeeded();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Load draft content
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
            SnackBar(content: Text('Failed to load draft: $e')),
          );
        }
      }

      setState(() {
        _isLoadingDraft = false;
      });
    } else {
      // If no draft ID is specified, try loading the latest draft
      _loadLatestDraft();
    }
  }

  // Load the latest draft
  Future<void> _loadLatestDraft() async {
    try {
      final latestDraft = DraftService.getCurrentCaptionDraft();
      if (latestDraft != null) {
        await _loadDraftContent(latestDraft);
      }
    } catch (e) {
      print('Failed to load the latest draft: $e');
    }
  }

  // Load draft content into the editor
  Future<void> _loadDraftContent(DraftModel draft) async {
    _currentDraftId = draft.id;
    // Override the default title only when the draft has a title
    if (draft.title.isNotEmpty) {
      _titleController.text = draft.title;
    }
    _descriptionController.text = draft.description;
    _selectedTopics = List.from(draft.topics);

    // Load draft images
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

  // Select images from the photo library
  Future<void> _pickImageFromGallery() async {
    // Check the current image count (draft images + selected images)
    final currentImageCount = _draftImages.length + _selectedAssets.length;
    if (currentImageCount >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You can upload up to 3 images because the developer is broke :)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final List<AssetEntity>? assets = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          maxAssets: 3 - _draftImages.length, // Calculate the available selection count dynamically
          selectedAssets: _selectedAssets,
          requestType: RequestType.image,
          textDelegate: const AssetPickerTextDelegate(),
          themeColor: themeColor, // Use the theme color
        ),
      );
      
      if (assets != null) {
        setState(() {
          _selectedAssets = assets;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select images: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while the draft is loading
    if (_isLoadingDraft) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: themeColor),
              const SizedBox(height: 16),
              const Text('Loading draft...', style: TextStyle(fontSize: 16)),
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
            // Image selection area
            _buildImageSelector(),
            const SizedBox(height: 24),
            
            // Title input
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Enter a title',
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
            
            // Body input
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'Describe what you need :)',
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
            
            // Topic area
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
            
            // Leave space at the bottom for the publish button
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // Build the image picker
  Widget _buildImageSelector() {
    // Combine draft images with newly selected images
    List<Widget> imageWidgets = [];
    
    // Calculate the current image count
    final currentImageCount = _draftImages.length + _selectedAssets.length;
    final canAddMore = currentImageCount < 3;
    
    // Add images from the draft
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
              // Display the draft image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  imageFile,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              // Delete button
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
              // Draft badge
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
                    'Draft',
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
    
    // Add newly selected images
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
              // Image thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AssetEntityImage(
                  asset,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              // Delete button
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
        // Image count
        if (currentImageCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '$currentImageCount/3 images selected${canAddMore ? '' : ' (limit reached)'}',
              style: TextStyle(
                fontSize: 12,
                color: canAddMore ? Colors.grey[600] : themeColor,
                fontWeight: canAddMore ? FontWeight.normal : FontWeight.bold,
              ),
            ),
          ),
        
        // Display images (draft images + newly selected images)
        if (imageWidgets.isNotEmpty)
          Container(
            height: 100,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...imageWidgets,
                // Add image button (shown only below the limit)
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
                              'Add Images',
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
          // If there are no images, show only the add button
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

  // Build the bottom bar
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            // Save draft button
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _showSaveDraftDialog,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.drafts_outlined),
                  const SizedBox(width: 10),
                  const Text('Save Draft', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            
            const Spacer(),
            
            // Publish post button
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
                child: const Text('Publish Post', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show the save draft confirmation dialog
  void _showSaveDraftDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Save to drafts?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'The current content will be saved to drafts so you can continue editing later.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
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
              'Save',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // Save the draft
  void _saveDraft() async {
    try {
      // Check whether there is content to save
      if (isContentEmpty()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('There is no content to save')),
        );
        return;
      }

      // Show the saving indicator
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
                  'Saving...',
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

      // Prepare existing image paths
      List<String> existingImagePaths = _draftImages.map((file) => file.path).toList();

      // Save the draft
      final draft = await DraftService.saveCaptionDraft(
        draftId: _currentDraftId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        topics: _selectedTopics,
        selectedAssets: _selectedAssets,
        existingImagePaths: existingImagePaths, // Pass existing image paths
      );

      _currentDraftId = draft.id;

      // Close the saving indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show the success message
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
                    'Saved',
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

      // Return to the main page after a delay
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          Navigator.of(context).pop(); // Close the message dialog
          // Use the callback or simply return
          if (widget.onBack != null) {
            widget.onBack!();
          } else {
            // If there is no callback, try popping once
            Navigator.of(context).pop();
          }
        }
      });

    } catch (e) {
      // Close the saving indicator
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show an error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save draft: $e')),
        );
      }
    }
  }

  // Check whether the content is empty
  bool isContentEmpty() {
    // Check whether the title is the default title
    final isDefaultTitle = _titleController.text.trim() == 'Help me come up with a caption :D';
    
    return isDefaultTitle && 
           _descriptionController.text.trim().isEmpty && 
           _selectedTopics.isEmpty && 
           _selectedAssets.isEmpty &&
           _draftImages.isEmpty;
  }

  // Save the draft silently without showing UI feedback
  Future<void> saveDraftSilently() async {
    try {
      // Prepare existing image paths
      List<String> existingImagePaths = _draftImages.map((file) => file.path).toList();

      // Save the draft
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
      print('Failed to save draft silently: $e');
    }
  }

  // Publish the post
  Future<void> _publishPost() async {
    try {
      // Validate required content - only check whether the title is empty
      if (_titleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a title')),
        );
        return;
      }

      // Check whether there are any images
      List<File> allImages = [];
      
      // Add images from the draft
      allImages.addAll(_draftImages);
      
      // Add newly selected images
      for (final asset in _selectedAssets) {
        final file = await asset.file;
        if (file != null) {
          allImages.add(file);
        }
      }

      if (allImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one image')),
        );
        return;
      }

      // Create post data
      final postData = PostModel(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
        topics: _selectedTopics,
        images: allImages,
        source: PostSource.captionSuggest,
        createdAt: DateTime.now(),
        // New fields use defaults, and the ID is generated automatically
      );

      // Save the post to posts
      final savedPostData = await NotesService.savePostAsNote(postData);

      // Clear the current draft
      await DraftService.clearAllCaptionDrafts();

      // Use the callback to show post details with the updated PostModel
      if (widget.onPostPublished != null) {
        widget.onPostPublished!(savedPostData);
      } else {
        // If no callback is provided, use navigation for backward compatibility
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
          SnackBar(content: Text('Failed to publish: $e')),
        );
      }
    }
  }
} 