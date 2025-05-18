import 'package:flutter/material.dart';

class BoardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.orange),
          SizedBox(height: 16),
          Text(
            '게시판 기능 준비 중입니다.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            '조금만 기다려주세요!',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}