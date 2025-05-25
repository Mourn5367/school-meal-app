// frontend/lib/screens/post_create_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/meal_model.dart';

class PostCreateScreen extends StatefulWidget {
  final Meal meal;
  final String date;

  const PostCreateScreen({
    Key? key,
    required this.meal,
    required this.date,
  }) : super(key: key);

  @override
  _PostCreateScreenState createState() => _PostCreateScreenState();
}

class _PostCreateScreenState extends State<PostCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _authorController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  // 게시글 저장 함수
  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      await apiService.createPost(
        title: _titleController.text,
        content: _contentController.text,
        author: _authorController.text,
        mealDate: widget.date,
        mealType: widget.meal.mealType,
      );

      // 게시글 작성 성공
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글이 작성되었습니다')),
      );
      
      // 이전 화면으로 돌아가기
      Navigator.pop(context, true);
    } catch (e) {
      // 오류 발생 시 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글 작성 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('게시글 작성'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePost,
            child: Text(
              '등록',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // 메뉴 정보 표시
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getMealTypeColor(widget.meal.mealType),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.meal.mealType,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${widget.meal.date} 메뉴에 대한 게시글',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // 제목 입력
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: '제목',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '제목을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // 닉네임 입력
                    TextFormField(
                      controller: _authorController,
                      decoration: InputDecoration(
                        labelText: '닉네임',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '닉네임을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // 내용 입력
                    Expanded(
                      child: TextFormField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          labelText: '내용',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '내용을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType) {
      case '아침':
        return Colors.orange;
      case '점심':
        return Colors.green;
      case '저녁':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}