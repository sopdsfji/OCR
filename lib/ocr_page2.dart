import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as flutter; // Flutter UI용 Image 위젯
import 'package:flutter/services.dart'; // for rootBundle
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart'; // for temp file path
import 'package:image/image.dart' as img; // img.Image 로 사용

class OcrPage2 extends StatefulWidget {
  @override
  _OcrPage2State createState() => _OcrPage2State();
}

class _OcrPage2State extends State<OcrPage2> {
  File? _imageFile;
  String _recognizedText = '';  // 인식된 텍스트
  bool _isUpsideDown = false;   // 거꾸로 인식 여부

  @override
  void initState() {
    super.initState();
    _loadAssetAndRecognizeText();
  }

  Future<void> _loadAssetAndRecognizeText() async {
    try {
      // 1. Load image from asset
      final byteData = await rootBundle.load('assets/img/upsidedown.png');
      final Uint8List originalBytes = byteData.buffer.asUint8List();

      // 2. Decode and rotate image
      img.Image originalImage = img.decodeImage(originalBytes)!;
      img.Image rotatedImage = img.copyRotate(originalImage, angle: 180); // 180도 회전

      // 3. Save rotated image to temp
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/rotated.png');
      await file.writeAsBytes(img.encodePng(rotatedImage));

      setState(() {
        _imageFile = file;
      });

      // 4. OCR
      final inputImage = InputImage.fromFile(file);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
      final recognizedText = await textRecognizer.processImage(inputImage);

      // 5. 블록 정렬
      final blocks = recognizedText.blocks;
      blocks.sort((a, b) =>
          (a.boundingBox?.top ?? 0).compareTo(b.boundingBox?.top ?? 0));
      final sortedText = blocks.map((b) => b.text).join('\n');

      setState(() {
        _isUpsideDown = true;
        _recognizedText = '※ 거꾸로 되어있음!\n\n$sortedText';
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
      appBar: AppBar(title: Text("OCR 테스트")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _imageFile != null
                ? flutter.Image.file(_imageFile!)
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