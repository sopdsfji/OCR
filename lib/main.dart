import 'package:flutter/material.dart';
//import 'ocr_page.dart';
import 'ocr_page2.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OCR 프로젝트',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: OcrPage2(), // OCR 화면을 첫 화면으로 설정
    );
  }
}
