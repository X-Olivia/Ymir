import 'package:flutter/material.dart';
import 'dart:ui';
import '../widgets/floating_nav_bar.dart';
import '../widgets/water_glass_widget.dart';
import '../widgets/color_slider_widget.dart';
import 'image_post_page.dart';
import 'caption_suggest_page.dart';
import 'ai_character_select_page.dart';
import 'post_view_page.dart'; // Import PostViewPage
import '../services/draft_service.dart';
import '../models/post_model.dart'; // Import PostModel
import '../services/greeting_service.dart';
import '../services/background_comment_service.dart';
import '../services/user_service.dart'; // Import UserService
import 'chat_page.dart';
import '../utils/responsive_utils.dart'; // Import responsive utilities

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  // Theme color, blue by default
  Color _themeColor = const Color(0xFF2463b3);
  
  // Currently selected navigation item (visual highlight)
  int _selectedIndex = 0;
  
  // Currently active page
  int _activeIndex = 0;
  
  // GlobalKey for invoking ImagePostPage methods
  final GlobalKey<ImagePostPageState> _imagePostPageKey = GlobalKey<ImagePostPageState>();
  
  // GlobalKey for invoking CaptionSuggestPage methods
  final GlobalKey<CaptionSuggestPageState> _captionSuggestPageKey = GlobalKey<CaptionSuggestPageState>();
  
  // GlobalKey for invoking AICharacterSelectPage methods
  final GlobalKey<AICharacterSelectPageState> _aiCharacterSelectPageKey = GlobalKey<AICharacterSelectPageState>();
  
  // GlobalKey for invoking PostViewPage methods
  final GlobalKey<PostViewPageState> _postViewPageKey = GlobalKey<PostViewPageState>();
  
  // Available theme colors
  final List<Color> _themeColors = [
    const Color(0xFF2463b3), // Blue
    const Color(0xFFa18dc1), // Purple
    const Color(0xFF8bb179), // Green
    const Color(0xFFfbb93b), // Yellow
    const Color(0xFFfeabcd), // Pink
  ];
  
  // Current color index
  int _colorIndex = 0;
  
  // Post data for PostViewPage
  PostModel? _currentPostData;
  
  // Draft navigation
  String? _draftIdToLoad; // ID of the draft to load
  bool _isDraftNavigation = false; // Whether navigation originated from drafts
  
  // Water wave animation controller
  late AnimationController _waveController;
  late AnimationController _colorChangeController;
  late Animation<double> _waveAnimation;
  late Animation<double> _colorChangeAnimation;
  
  // Color ball bounce animation controller
  late AnimationController _ballBounceController;
  late Animation<Offset> _ballBounceAnimation;
  
  // Slider offset (used for collision detection)
  double _sliderOffset = 0.0;
  
  // Whether the color ball is being dragged
  bool _isBallBeingDragged = false;
  
  // Current color ball offset
  Offset _ballCurrentOffset = Offset.zero;
  
  @override
  void initState() {
    super.initState();
    
    // Check whether to show the greeting
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // [DEBUG] Clear all greeting records for easier debugging
      await GreetingService.clearAllGreetingRecords();
      _checkDailyGreeting();
    });
    
    // Initialize animation controllers
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _colorChangeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Color ball bounce animation controller
    _ballBounceController = AnimationController(
      duration: const Duration(milliseconds: 1000), // Shorter duration for a faster bounce
      vsync: this,
    );
    
    _waveAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_waveController);
    
    _colorChangeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _colorChangeController,
      curve: Curves.elasticOut,
    ));
    
    _ballBounceAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ballBounceController,
      curve: Curves.elasticOut,
    ));
    
    // Initialize pages - home content is handled separately rather than added to the list
    // Pages are now created dynamically instead of using a static list
  }

  // Check and show the daily greeting
  Future<void> _checkDailyGreeting() async {
    print('🔍 Checking daily greeting...');
    print('Greeting enabled: ${GreetingService.isGreetingEnabled()}');
    print('Should show greeting: ${GreetingService.shouldShowGreetingNow()}');
    
    if (GreetingService.shouldShowGreetingNow()) {
      // Get the user's nickname
      final userNickname = await UserService.getNickname();
      
      await showDialog(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Stack(
            children: [
              // Frosted-glass background
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title row
                        Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              color: _themeColor,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Daily Greeting',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Greeting content
                        Text(
                          'Have you said ${GreetingService.getGreetingMessage()} to $userNickname today?',
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Hint
                        Text(
                          'Turn off daily greetings in Settings > Privacy Settings',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Button row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Maybe Later',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                await GreetingService.markGreetingShown();
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _themeColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Yes, I Have'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Top-left reflection effect
              Positioned(
                left: 0,
                top: 0,
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                    ),
                    child: Container(
                      width: 150,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: const [0.0, 0.3, 1.0],
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.05),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Bottom-right reflection effect
              Positioned(
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(20),
                    ),
                    child: Container(
                      width: 120,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomRight,
                          end: Alignment.topLeft,
                          stops: const [0.0, 0.3, 1.0],
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.03),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      print('❌ No greeting needed');
    }
  }

  // Get pages dynamically so the theme color updates in real time
  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return Container(); // Home placeholder; never actually used
      case 1:
        return ImagePostPage(
          key: _imagePostPageKey,
          themeColor: _themeColor,
          draftId: _isDraftNavigation ? _draftIdToLoad : null, // Pass the draft ID
          onBack: () {
            // Return to the main page state
            setState(() {
              _activeIndex = 0;
              _selectedIndex = 0;
              _clearDraftNavigation(); // Clear the draft navigation state
            });
          },
          onPostPublished: (postData) {
            // Show post details after publishing
            _clearDraftNavigation(); // Clear the draft navigation state
            showPostView(postData, isNewlyPublished: true);
          },
        );
      case 2:
        return CaptionSuggestPage(
          key: _captionSuggestPageKey,
          themeColor: _themeColor,
          draftId: _isDraftNavigation ? _draftIdToLoad : null, // Pass the draft ID
          onBack: () {
            // Return to the main page state
            setState(() {
              _activeIndex = 0;
              _selectedIndex = 0;
              _clearDraftNavigation(); // Clear the draft navigation state
            });
          },
          onPostPublished: (postData) {
            // Show post details after publishing
            _clearDraftNavigation(); // Clear the draft navigation state
            showPostView(postData, isNewlyPublished: true);
          },
        );
      case 3:
        return AICharacterSelectPage(
          key: _aiCharacterSelectPageKey, 
          themeColor: _themeColor,
        );
      case 4: // PostViewPage
        return PostViewPage(
          key: _postViewPageKey,
          postData: _currentPostData,
          themeColor: _themeColor,
          onBack: () {
            // If opened after publishing, return to the main page
            setState(() {
              _activeIndex = 0;
              _selectedIndex = 0;
              _currentPostData = null; // Clear post data
            });
          },
        );
      default:
        return Container();
    }
  }

  // Get the background image path from the color index
  String _getBackgroundImagePath() {
    switch (_colorIndex) {
      case 0:
        return 'assets/images/back/blue.png';
      case 1:
        return 'assets/images/back/purple.png';
      case 2:
        return 'assets/images/back/green.png';
      case 3:
        return 'assets/images/back/orange.png';
      case 4:
        return 'assets/images/back/pink.png';
      default:
        return 'assets/images/back/blue.png';
    }
  }

  // Handle the back button
  Future<bool> _handleBackButton() async {
    // If currently on the post details page
    if (_activeIndex == 4) {
      // If opened after publishing, return to the main page
      setState(() {
        _activeIndex = 0;
        _selectedIndex = 0;
        _currentPostData = null; // Clear post data
      });
      return false; // Prevent the default back action
    }
    
    // If currently on the AI selection page
    if (_activeIndex == 3) {
      final aiCharacterSelectPageState = _aiCharacterSelectPageKey.currentState;
      if (aiCharacterSelectPageState != null) {
        // Check whether any AI friends are selected
        if (!aiCharacterSelectPageState.hasSelectedFriends()) {
          // Show a message when no friends are selected
          _showSelectFriendsDialog();
          return false; // Prevent going back
        }
      }
      
      // If friends are selected, allow returning to the main page
      setState(() {
        _activeIndex = 0;
        _selectedIndex = 0;
      });
      return false; // Prevent the default back action
    }
    
    // If currently on the image post page
    if (_activeIndex == 1) {
      final imagePostPageState = _imagePostPageKey.currentState;
      if (imagePostPageState != null) {
        // Check whether the content is empty
        final isEmpty = imagePostPageState.isContentEmpty();
        
        if (isEmpty) {
          // If empty, clear image drafts and return
          await DraftService.clearAllDrafts();
          setState(() {
            _activeIndex = 0;
            _selectedIndex = 0;
          });
          return false; // Prevent the default back action
        } else {
          // If not empty, ask whether to save
          final shouldSave = await _showSaveConfirmDialog();
          
          if (shouldSave == true) {
            // The user chose to save
            await imagePostPageState.saveDraftSilently();
          } else if (shouldSave == false) {
            // The user chose not to save; clear image drafts
            await DraftService.clearAllDrafts();
          }
          // If the user cancels (shouldSave == null), do not go back
          
          if (shouldSave != null) {
            setState(() {
              _activeIndex = 0;
              _selectedIndex = 0;
            });
          }
          
          return false; // Prevent the default back action
        }
      }
    }

    // If currently on the caption page
    if (_activeIndex == 2) {
      final captionSuggestPageState = _captionSuggestPageKey.currentState;
      if (captionSuggestPageState != null) {
        // Check whether the content is empty
        final isEmpty = captionSuggestPageState.isContentEmpty();
        
        if (isEmpty) {
          // If empty, clear caption drafts and return
          await DraftService.clearAllCaptionDrafts();
          setState(() {
            _activeIndex = 0;
            _selectedIndex = 0;
          });
          return false; // Prevent the default back action
        } else {
          // If not empty, ask whether to save
          final shouldSave = await _showSaveConfirmDialog();
          
          if (shouldSave == true) {
            // The user chose to save
            await captionSuggestPageState.saveDraftSilently();
          } else if (shouldSave == false) {
            // The user chose not to save; clear caption drafts
            await DraftService.clearAllCaptionDrafts();
          }
          // If the user cancels (shouldSave == null), do not go back
          
          if (shouldSave != null) {
            setState(() {
              _activeIndex = 0;
              _selectedIndex = 0;
            });
          }
          
          return false; // Prevent the default back action
        }
      }
    }
    
    // Allow the default back action in all other cases
    return true;
  }

  // Show the save confirmation dialog
  Future<bool?> _showSaveConfirmDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Save Draft?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'You have unsaved content. Would you like to save it to drafts?',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Don\'t Save',
              style: TextStyle(color: _themeColor, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _themeColor,
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

  // Show the AI friend selection dialog
  void _showSelectFriendsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Select AI Friends',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Select at least one AI friend to continue. Please return to the selection page.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _themeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Got It',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // Show the post details page
  void showPostView(PostModel postData, {bool isNewlyPublished = false}) async {
    // Navigate to the post details page immediately
    setState(() {
      _currentPostData = postData;
      _activeIndex = 4;
      _selectedIndex = 4;
    });
    
    // For a newly published post, generate AI comments asynchronously without blocking navigation
    if (isNewlyPublished) {
      print('🚀 New post published; starting AI comment generation asynchronously');
      // Run asynchronously without blocking this method
      BackgroundCommentService.startCommentGeneration(postData).catchError((error) {
        print('❌ Failed to start AI comment generation: $error');
      });
    }
  }

  // Handle draft navigation from drafts to the editor
  void navigateToDraft(String draftId, bool isCaptionDraft) {
    setState(() {
      _draftIdToLoad = draftId;
      _isDraftNavigation = true;
      if (isCaptionDraft) {
        _activeIndex = 2; // Caption suggestion page
        _selectedIndex = 2;
      } else {
        _activeIndex = 1; // Image post page
        _selectedIndex = 1;
      }
    });
  }

  // Clear the draft navigation state
  void _clearDraftNavigation() {
    _draftIdToLoad = null;
    _isDraftNavigation = false;
  }

  @override
  void dispose() {
    _waveController.dispose();
    _colorChangeController.dispose();
    _ballBounceController.dispose();
    super.dispose();
  }

  // Handle slider offset changes for collision detection
  void _handleSliderOffsetChanged(double offset) {
    setState(() {
      _sliderOffset = offset;
    });
    
    // Detect a collision when the slider moves upward beyond the threshold
    if (offset < -80) {
      // Enter drag mode so the color ball follows the slider
      if (!_isBallBeingDragged && !_ballBounceController.isAnimating) {
        _isBallBeingDragged = true;
      }
      
      // Move the color ball with the slider at a smaller scale to create a pushed effect
      if (_isBallBeingDragged) {
        final ballOffset = (offset + 80) * 0.6; // Move the color ball by 60% of the slider's distance
        setState(() {
          _ballCurrentOffset = Offset(0, ballOffset);
        });
      }
    } else {
      // Trigger the release effect when the slider returns to the safe area
      if (_isBallBeingDragged) {
        _triggerBallRelease();
        _isBallBeingDragged = false;
      }
    }
  }
  
  // Trigger the color ball release effect: move upward with inertia, then bounce back
  void _triggerBallRelease() {
    // Continue upward from the current position with inertia, then return to the origin
    final currentOffset = _ballCurrentOffset;
    final inertiaDistance = 40.0; // Upward inertia distance
    
    _ballBounceAnimation = TweenSequence<Offset>([
      // Phase 1: rapid upward inertial movement
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: currentOffset,
          end: Offset(0, currentOffset.dy - inertiaDistance),
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 25, // Spend 25% of the time moving upward
      ),
      // Phase 2: elastic return to the origin
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(0, currentOffset.dy - inertiaDistance),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 75, // Spend 75% of the time bouncing back
      ),
    ]).animate(_ballBounceController);
    
    // Add an animation listener to update the color ball's current position
    _ballBounceAnimation.addListener(() {
      setState(() {
        _ballCurrentOffset = _ballBounceAnimation.value;
      });
    });
    
    // Reset the state when the animation completes
    _ballBounceController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _ballCurrentOffset = Offset.zero;
          _isBallBeingDragged = false;
        });
        _ballBounceController.removeStatusListener((status) {});
      }
    });
    
    _ballBounceController.reset();
    _ballBounceController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _handleBackButton();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        // Use a gradient background
        body: Container(
          decoration: BoxDecoration(
            // Gradient background
            image: DecorationImage(
              image: AssetImage(_getBackgroundImagePath()),
              fit: ResponsiveUtils.isExtraLargeTablet(context) 
                  ? BoxFit.cover // Use cover for a larger background on the 13-inch iPad Pro
                  : BoxFit.cover,
              alignment: ResponsiveUtils.isExtraLargeTablet(context)
                  ? const Alignment(-0.5, -0.1) // Shift the background slightly up and right on the 13-inch iPad Pro
                  : const Alignment(0.15, 0), // Preserve the original offset on other devices
              scale: ResponsiveUtils.isExtraLargeTablet(context) 
                  ? 0.8// Use a smaller scale to enlarge the background on the 13-inch iPad Pro
                  : 1.0, // Use the default on other devices
            ),
          ),
          child: Stack(
            children: [
              // Frosted-glass effect layer
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              // Original content
              SafeArea(
                child: Stack(
                  children: [
                    // Top navigation buttons
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Chat button
                          IconButton(
                            icon: Icon(
                              Icons.chat_bubble_outline,
                              size: 28,
                              color: _themeColor,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(themeColor: _themeColor),
                                ),
                              );
                            },
                          ),
                          // Settings button
                          IconButton(
                            icon: Icon(
                              Icons.settings,
                              size: 28,
                              color: _themeColor,
                            ),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/settings',
                                arguments: _themeColor,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Page content - _activeIndex determines which page is shown
                    _activeIndex == 0 
                        ? _buildHomeContent() 
                        : Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              children: [
                                // Show a back button outside the home page
                                Padding(
                                  padding: const EdgeInsets.only(left: 16, top: 8),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.arrow_back_ios,
                                        color: _themeColor,
                                      ),
                                      onPressed: () async {
                                        await _handleBackButton();
                                      },
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _getPage(_activeIndex),
                                ),
                              ],
                            ),
                          ),
                    
                    // Bottom navigation bar
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Visibility(
                        // Show the navigation bar only on the home page (_activeIndex is 0)
                        visible: _activeIndex == 0,
                        child: FloatingNavBar(
                          activeIndex: _activeIndex,
                          selectedIndex: _selectedIndex,
                          onTap: (index) {
                            // Keep the index within the 4 navigation pages: 0, 1, 2, and 3
                            // PostViewPage (index 4) is not in the navigation bar and opens only after publishing
                            if (index >= 4) return;
                            
                            if (_selectedIndex == index) {
                              // Tapping the same icon again navigates to the page
                              setState(() {
                                _activeIndex = index;
                              });
                            } else {
                              // The first tap updates only the visual state
                              setState(() {
                                _selectedIndex = index;
                              });
                            }
                          },
                          themeColor: _themeColor,
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
    );
  }
  
  // Home content
  Widget _buildHomeContent() {
    // Get responsive parameters
    final isTablet = ResponsiveUtils.isTablet(context);
    final titleFontSize = ResponsiveUtils.getResponsiveFontSize(context, 55);
    final responsivePadding = ResponsiveUtils.getResponsivePadding(context, 16);
    final waterGlassSize = ResponsiveUtils.getResponsiveSize(context, const Size(300, 300));
    
    // Get iPad-specific layout parameters
    final layoutParams = ResponsiveUtils.getIPadHomeLayoutParams(context);
    
    return Padding(
      padding: EdgeInsets.fromLTRB(
        responsivePadding, 
        layoutParams['titleTopPadding']!, 
        responsivePadding, 
        layoutParams['navBarBottomPadding']!
      ), // Use iPad-specific top and bottom spacing
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title text - responsive font size
          Text(
            'YMIR',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              fontFamily: 'Library3AmSoft',
              color: _themeColor,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, 10)),
    
          SizedBox(height: layoutParams['titleToWaterGlassSpacing']!), // Use iPad-specific title-to-glass spacing
          
          // Slider color selector
          Padding(
            padding: EdgeInsets.symmetric(horizontal: layoutParams['horizontalPadding']!), // Use iPad-specific horizontal spacing
            child: Column(
              children: [
                // Water glass color preview - responsive size
                Transform.translate(
                  offset: _ballCurrentOffset, // Use the current offset directly
                  child: WaterGlassWidget(
                    waveAnimation: _waveAnimation,
                    colorChangeAnimation: _colorChangeAnimation,
                    themeColor: _themeColor,
                    size: waterGlassSize, // Use a responsive size
                  ),
                ),
                SizedBox(height: layoutParams['waterGlassToSliderSpacing']!), // Use iPad-specific glass-to-slider spacing
                
                // Discrete slider with drag movement and collision detection
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate maximum offsets in both directions
                    final screenHeight = MediaQuery.of(context).size.height;
                    final safeAreaTop = MediaQuery.of(context).padding.top;
                    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
                    final navBarHeight = layoutParams['navBarBottomPadding']!; // Use the iPad-specific navigation bar height
                    final safeMargin = ResponsiveUtils.getResponsivePadding(context, 20); // Responsive safe margin
                    
                    // Estimate the height used by current content with iPad-specific layout parameters
                    final usedHeight = layoutParams['titleTopPadding']! + // Top padding
                        titleFontSize + // Title height
                        ResponsiveUtils.getResponsivePadding(context, 10) + // Spacing below the title
                        layoutParams['titleToWaterGlassSpacing']! + // Title-to-glass spacing
                        waterGlassSize.height + // Glass height
                        layoutParams['waterGlassToSliderSpacing']! + // Glass-to-slider spacing
                        200 + // Slider height
                        100 + // Bottom padding
                        safeAreaBottom;
                    
                    // Calculate the maximum downward offset, optimized for iPad
                    // Calculate remaining available space
                    final remainingSpace = screenHeight - usedHeight - navBarHeight - safeMargin;
                    
                    // Allow greater drag distances on iPad, with the largest on the 13-inch iPad Pro
                    final baseMaxDownOffset = ResponsiveUtils.isExtraLargeTablet(context) ? 180.0 : 
                                            (ResponsiveUtils.isLargeTablet(context) ? 150.0 : 
                                            (isTablet ? 120.0 : 80.0));
                    final minDownOffset = ResponsiveUtils.isExtraLargeTablet(context) ? 120.0 : 
                                        (ResponsiveUtils.isLargeTablet(context) ? 100.0 : 
                                        (isTablet ? 80.0 : 50.0));
                    
                    // Adapt the downward offset to the device type
                    final maxDownOffset = remainingSpace > 0 
                        ? remainingSpace.clamp(minDownOffset, baseMaxDownOffset)
                        : minDownOffset;
                    
                    // Maximum upward offset, allowing a greater strike distance on iPad
                    final maxUpOffset = ResponsiveUtils.isExtraLargeTablet(context) ? 300.0 : 
                                      (ResponsiveUtils.isLargeTablet(context) ? 250.0 : 
                                      (isTablet ? 200.0 : 150.0));
                    
                    return ColorSliderWidget(
                      colors: _themeColors,
                      currentIndex: _colorIndex,
                      currentColor: _themeColor,
                      maxDownwardOffset: maxDownOffset,
                      maxUpwardOffset: maxUpOffset, // Independent upward offset
                      onOffsetChanged: _handleSliderOffsetChanged, // Offset change callback
                      onColorChanged: (index) {
                        setState(() {
                          _colorIndex = index;
                          _themeColor = _themeColors[_colorIndex];
                          // Trigger the color change animation
                          _colorChangeController.reset();
                          _colorChangeController.forward();
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 