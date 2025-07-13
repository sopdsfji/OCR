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

  @override
  void initState() {
    super.initState();
    _loadAssetAndRecognizeText();
  }

  Future<void> _loadAssetAndRecognizeText() async {
    try {
      // 1. Load image from asset
      final byteData = await rootBundle.load('assets/img/Korea+English.png');

      // 2. Write to a temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Korea+English.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      setState(() {
        _imageFile = file;
      });

      // 3. Perform OCR
      final inputImage = InputImage.fromFile(file);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
      final recognizedText = await textRecognizer.processImage(inputImage);

      setState(() {
        _recognizedText = recognizedText.text;
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
