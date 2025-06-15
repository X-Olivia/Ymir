// Ymir应用的基础widget测试
//
// 测试应用的基本功能和UI组件

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ymir/main.dart';

void main() {
  testWidgets('Ymir app smoke test', (WidgetTester tester) async {
    // 构建应用并触发一帧
    await tester.pumpWidget(const MyApp());

    // 验证应用能够正常启动
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // 等待应用完全加载
    await tester.pumpAndSettle();
  });
}
