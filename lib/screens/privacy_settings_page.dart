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
  // 系统权限状态
  Map<Permission, PermissionStatus> _permissionStatus = {};
  // 每日问候设置
  bool _greetingEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _initPermissions();
    _loadSettings();
  }

  // 加载设置
  Future<void> _loadSettings() async {
    setState(() {
      _greetingEnabled = GreetingService.isGreetingEnabled();
    });
  }

  // 初始化权限状态
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

  // 请求权限
  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    
    setState(() {
      _permissionStatus[permission] = status;
    });
  }

  // 打开系统设置
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
      print('无法打开系统设置: $e');
    }
  }

  // 获取权限状态图标
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

  // 获取权限状态颜色
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

  // 构建权限设置项
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
            // 顶部应用栏
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
                  '隐私设置',
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

            // 系统权限设置
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: const Text(
                  '系统权限',
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
                    _buildPermissionItem('相机', Permission.camera),
                    const Divider(height: 1),
                    _buildPermissionItem('相册', Permission.photos),
                    const Divider(height: 1),
                    _buildPermissionItem('麦克风', Permission.microphone),
                    const Divider(height: 1),
                    _buildPermissionItem('存储空间', Permission.storage),
                  ],
                ),
              ),
            ),

            // 每日问候设置
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: const Text(
                  '其他设置',
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
                      title: const Text('每日问候'),
                      subtitle: const Text('每天提醒我跟自己说早安午安晚安'),
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

            // 其他应用权限设置
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
                      title: const Text('系统权限设置'),
                      subtitle: const Text('前往系统设置修改应用权限'),
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

            // 法律文档
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: const Text(
                  '法律文档',
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
                      title: const Text('隐私政策'),
                      subtitle: const Text('了解我们如何保护您的隐私'),
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
                      title: const Text('服务条款'),
                      subtitle: const Text('使用应用前请阅读服务条款'),
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

            // 底部间距
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }
} 