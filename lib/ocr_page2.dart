import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for rootBundle
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart'; // for temp file path

class OcrPage2 extends StatefulWidget {
  @override
  _OcrPage2State createState() => _OcrPage2State();
}

class _OcrPage2State extends State<OcrPage2> {
  File? _imageFile;
  String _recognizedText = '';
  bool _isUpsideDown = false;

  @override
  void initState() {
    super.initState();
    _loadAssetAndRecognizeText();
  }

  Future<void> _loadAssetAndRecognizeText() async {
    try {
      // 1. Load image from asset
      final byteData = await rootBundle.load('assets/img/upsidedown.png');

      // 2. Write to a temporary file
      // ML Kit의 InputImage.fromFile()은 File 타입을 요구하여
      // 다음 과정이 필요
      // 핵심 기능 : byteData를 실제 파일로 변환하기 위해 임시 디렉토리에 저장
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/upsidedown.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      setState(() {
        _imageFile = file;
      });

      // 3. Perform OCR
      final inputImage = InputImage.fromFile(file); // OCR 입력 형식
      // <ML Kit OCR 엔진 객체>
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean); //한국어 텍스트 특화
      final recognizedText = await textRecognizer.processImage(inputImage);

      // 거꾸로 되어 있는지 추정 (방법: 첫 블록의 위치가 이미지 아래쪽에 있는 경우)
      final blocks = recognizedText.blocks; // 첫번째 텍스트 블록의 좌표값 가져옴
      if (blocks.isNotEmpty) {
        final firstBlock = blocks.first;
        final top = firstBlock.boundingBox?.top ?? 0;  // 해당 값이 클수록 아랫부분에 있는 텍스트
        final height = firstBlock.boundingBox?.height ?? 0;

        // 화면 아래쪽에서 시작하면 거꾸로일 확률 높음
        if (top > 500) { // 화면 크기에 따라 조정 필요
          _isUpsideDown = true;
        }
      }

      setState(() {
        _recognizedText = _isUpsideDown
            ? '※ 거꾸로 되어있음!' // 거꾸로면 안내문
            : recognizedText.text;  // 인식된 텍스트 저장
      });

      textRecognizer.close();
    } catch (e) {
      setState(() {
        _recognizedText = '에러 발생: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("OCR 테스트 ")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _imageFile != null
                ? Image.file(_imageFile!)
                : Text("이미지를 불러오는 중입니다..."),
            SizedBox(height: 20),
            Text(
              "인식된 텍스트:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(_recognizedText),
          ],
        ),
      ),
    );
  }
}
