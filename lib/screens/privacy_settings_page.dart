import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import '../services/greeting_service.dart';
import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';

class PrivacySettingsPage extends StatefulWidget {
  final Color? themeColor;

  const PrivacySettingsPage({
    super.key,
    this.themeColor,
  });

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  // System permission status
  Map<Permission, PermissionStatus> _permissionStatus = {};
  // Daily greeting setting
  bool _greetingEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _initPermissions();
    _loadSettings();
  }

  // Load settings
  Future<void> _loadSettings() async {
    setState(() {
      _greetingEnabled = GreetingService.isGreetingEnabled();
    });
  }

  // Initialize permission statuses
  Future<void> _initPermissions() async {
    final permissions = [
      Permission.camera,
      Permission.photos,
      Permission.microphone,
      Permission.storage,
    ];

    final statuses = await Future.wait(
      permissions.map((permission) => permission.status),
    );

    setState(() {
      for (var i = 0; i < permissions.length; i++) {
        _permissionStatus[permissions[i]] = statuses[i];
      }
    });
  }

  // Request permission
  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    
    setState(() {
      _permissionStatus[permission] = status;
    });
  }

  // Open system settings
  Future<void> _openSettings() async {
    try {
      if (Platform.isAndroid) {
        final AndroidIntent intent = AndroidIntent(
          action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
          data: 'package:${Platform.environment['PACKAGE_NAME']}',
        );
        await intent.launch();
      } else if (Platform.isIOS) {
        await openAppSettings();
      }
    } catch (e) {
      print('Unable to open system settings: $e');
    }
  }

  // Get the permission status icon
  IconData _getPermissionIcon(PermissionStatus? status) {
    switch (status) {
      case PermissionStatus.granted:
        return Icons.check_circle;
      case PermissionStatus.denied:
        return Icons.block;
      case PermissionStatus.restricted:
      case PermissionStatus.limited:
        return Icons.warning;
      case PermissionStatus.permanentlyDenied:
        return Icons.not_interested;
      default:
        return Icons.help;
    }
  }

  // Get the permission status color
  Color _getPermissionColor(PermissionStatus? status) {
    switch (status) {
      case PermissionStatus.granted:
        return Colors.green;
      case PermissionStatus.denied:
        return widget.themeColor ?? Colors.blue;
      case PermissionStatus.restricted:
      case PermissionStatus.limited:
        return Colors.orange;
      case PermissionStatus.permanentlyDenied:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Build a permission setting item
  Widget _buildPermissionItem(String title, Permission permission) {
    final status = _permissionStatus[permission];
    
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getPermissionIcon(status),
            color: _getPermissionColor(status),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
        ],
      ),
      onTap: () async {
        if (status == PermissionStatus.permanentlyDenied) {
          await _openSettings();
        } else {
          await _requestPermission(permission);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.themeColor ?? Colors.blue;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              themeColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // Top app bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white.withOpacity(0.1),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Privacy Settings',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ),

            // System permission settings
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: const Text(
                  'System Permissions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    _buildPermissionItem('Camera', Permission.camera),
                    const Divider(height: 1),
                    _buildPermissionItem('Photos', Permission.photos),
                    const Divider(height: 1),
                    _buildPermissionItem('Microphone', Permission.microphone),
                    const Divider(height: 1),
                    _buildPermissionItem('Storage', Permission.storage),
                  ],
                ),
              ),
            ),

            // Daily greeting setting
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: const Text(
                  'Other Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Daily Greeting'),
                      subtitle: const Text('Remind me to wish myself a good morning, afternoon, and evening every day'),
                      value: _greetingEnabled,
                      activeColor: widget.themeColor ?? Colors.blue,
                      onChanged: (bool value) async {
                        await GreetingService.setGreetingEnabled(value);
                        setState(() {
                          _greetingEnabled = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Additional app permission settings
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('System Permission Settings'),
                      subtitle: const Text('Open system settings to change app permissions'),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      onTap: _openSettings,
                    ),
                  ],
                ),
              ),
            ),

            // Legal documents
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: const Text(
                  'Legal Documents',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Privacy Policy'),
                      subtitle: const Text('Learn how we protect your privacy'),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PrivacyPolicyPage(
                              themeColor: widget.themeColor,
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Terms of Service'),
                      subtitle: const Text('Please read the terms before using the app'),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TermsOfServicePage(
                              themeColor: widget.themeColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }
} 