// frontend/lib/screens/home_screen.dart - 게시판 탭 제거 버전
import 'package:flutter/material.dart';
import 'menu_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('학식 메뉴 앱'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: MenuScreen(), // 메뉴 화면만 직접 표시
    );
  }
}