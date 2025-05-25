// frontend/lib/screens/post_create_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/meal_model.dart';
import '../utils/date_utils.dart' as DateUtilsCustom;

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
  final _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  File? _selectedImage;
  String? _uploadedImageUrl;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  // 이미지 선택 함수
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      print('이미지 선택 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다')),
      );
    }
  }

  // 카메라로 사진 촬영
  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      print('사진 촬영 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진 촬영 중 오류가 발생했습니다')),
      );
    }
  }

  // 이미지 선택 옵션 표시
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  '이미지 선택',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.photo_library, color: Colors.blue),
                  ),
                  title: Text('갤러리에서 선택'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.photo_camera, color: Colors.green),
                  ),
                  title: Text('카메라로 촬영'),
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
                if (_selectedImage != null)
                  ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.delete, color: Colors.red),
                    ),
                    title: Text('이미지 제거', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
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

      // 이미지가 있다면 먼저 업로드
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await apiService.uploadImage(_selectedImage!);
        print('업로드된 이미지 URL: $imageUrl');
      }

      // 개선된 날짜 처리
      String formattedDate = DateUtilsCustom.DateUtils.formatToApiDate(widget.date);
      
      print('원본 날짜: ${widget.date}');
      print('포맷된 날짜: $formattedDate');

      await apiService.createPost(
        title: _titleController.text,
        content: _contentController.text,
        author: _authorController.text,
        mealDate: formattedDate,
        mealType: widget.meal.mealType,
        imageUrl: imageUrl,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('게시글이 작성되었습니다'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      print('게시글 작성 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('게시글 작성 중 오류가 발생했습니다: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
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
      elevation: 0,
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _savePost,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isLoading ? Colors.grey : Colors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isLoading ? '작성 중...' : '등록',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
    body: _isLoading
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('게시글을 작성 중입니다...'),
                if (_selectedImage != null) ...[
                  SizedBox(height: 8),
                  Text('이미지 업로드 중...', style: TextStyle(color: Colors.grey[600])),
                ],
              ],
            ),
          )
        : Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 메뉴 정보 표시 부분은 동일하게 유지
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getMealTypeColor(widget.meal.mealType).withOpacity(0.1),
                          _getMealTypeColor(widget.meal.mealType).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getMealTypeColor(widget.meal.mealType).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getMealTypeColor(widget.meal.mealType),
                            borderRadius: BorderRadius.circular(20),
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
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${DateUtilsCustom.DateUtils.formatForDisplay(widget.date)} 메뉴',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${widget.meal.mealType}에 대한 게시글을 작성합니다',
                                style: TextStyle(
                                  fontSize: 12, 
                                  color: Colors.grey[600]
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // 제목 입력
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: '제목',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      prefixIcon: Icon(Icons.title),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '닉네임을 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  
                  // 개선된 이미지 선택 및 미리보기
                  if (_selectedImage != null) ...[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,  // 4:3 비율로 설정
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.contain,  // 이미지 비율 유지하면서 컨테이너에 맞추기
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 16, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              '이미지가 선택되었습니다',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                  ],
                  
                  Container(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showImagePickerOptions,
                      icon: Icon(_selectedImage != null ? Icons.edit : Icons.camera_alt),
                      label: Text(_selectedImage != null ? '이미지 변경' : '이미지 추가'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: _selectedImage != null ? Colors.orange : Colors.blue,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // 내용 입력
                  Expanded(
                    child: TextFormField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        labelText: '내용',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        hintText: '메뉴에 대한 후기, 의견 등을 자유롭게 작성해주세요.\n\n예시:\n- 맛은 어땠나요?\n- 양은 충분했나요?\n- 추천하고 싶나요?',
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