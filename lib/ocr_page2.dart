// 필요한 패키지들 import
import 'dart:async'; // 타이머 사용 (1초 간격 OCR)
import 'dart:io'; // 파일 저장 및 임시 파일 경로 접근
import 'dart:typed_data'; // 이미지 byte 변환
import 'dart:ui' as ui;  // 캡처된 이미지를 다루기 위한 UI 이미지 타입
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';// 임시 디렉토리 경로 가져오기
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';// MLKit OCR
import 'package:video_player/video_player.dart';// 영상 재생용 컨트롤러
import 'package:flutter/services.dart';// 시스템 처리용
import 'package:flutter/rendering.dart';// RepaintBoundary 관련


class OcrPage2 extends StatefulWidget {
  @override
  _OcrPage2State createState() => _OcrPage2State();// StatefulWidget 생성
}

class _OcrPage2State extends State<OcrPage2> {
  late VideoPlayerController _controller; // 영상 재생 컨트롤러
  final GlobalKey _videoKey = GlobalKey();// 영상 위젯을 캡처하기 위한 키
  String _recognizedText = '';// OCR로 인식한 텍스트를 저장할 변수
  Timer? _ocrTimer;// 1초마다 OCR 실행할 타이머
  bool _isDetecting = false;// OCR 중복 실행 방지를 위한 flag

  @override
  void initState() {
    super.initState();
    _initVideo();// 영상 초기화 및 OCR 타이머 시작
  }

  // 영상 컨트롤러 초기화 및 OCR 타이머 시작
  Future<void> _initVideo() async {
    _controller = VideoPlayerController.asset('assets/videos/sample.mp4');
    await _controller.initialize();// 영상 준비
    _controller.setLooping(true);// 반복 재생 설정
    await _controller.play();// 영상 재생 시작

    // 1초마다 OCR 실행
    _ocrTimer = Timer.periodic(Duration(seconds: 1), (_) => _performOcr());
    setState(() {}); // UI 갱신
  }

  // OCR 수행 함수: 현재 영상 프레임을 캡처하여 텍스트 인식
  Future<void> _performOcr() async {
    if (_isDetecting || !_controller.value.isPlaying) return; // OCR 중이면 중복 방지

    _isDetecting = true; // OCR 시작
    try {
      // 영상 위젯에서 render boundary 가져오기
      RenderRepaintBoundary boundary =
      _videoKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
      // 만약 아직 렌더링이 안 되었으면 대기
      if (boundary.debugNeedsPaint) {
        await Future.delayed(Duration(milliseconds: 100));
      }

      // boundary로부터 이미지 캡처
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      // ByteData를 파일로 저장 (OCR 입력용)
      final buffer = byteData.buffer;
      final tempDir = await getTemporaryDirectory();// 임시 디렉토리 경로 가져오기
      final file = await File('${tempDir.path}/frame.png')
          .writeAsBytes(buffer.asUint8List());

      // MLKit InputImage 생성
      final inputImage = InputImage.fromFile(file);
      // OCR 엔진 준비 (한국어 기준)
      final textRecognizer =
      TextRecognizer(script: TextRecognitionScript.korean);
      // OCR 수행
      final recognizedText = await textRecognizer.processImage(inputImage);

      // 결과 텍스트 업데이트
      setState(() {
        _recognizedText = recognizedText.text;
      });

      await textRecognizer.close();// OCR 종료 후 자원 정리
    } catch (e) {
      print('OCR 오류: $e');// 에러 출력
    } finally {
      _isDetecting = false;// OCR 종료 표시
    }
  }

  @override
  void dispose() {
    _ocrTimer?.cancel(); // 타이머 해제
    _controller.dispose();// 영상 컨트롤러 해제
    super.dispose();
  }

  // UI 화면
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('영상 OCR 실험')),// 앱바 타이틀
      body: Column(
        children: [
          // 영상 위젯을 감싸는 boundary: 캡처 대상
          RepaintBoundary(
            key: _videoKey,// 캡처에 사용할 key
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,// 영상 비율 유지
              child: VideoPlayer(_controller),// 영상 플레이어
            ),
          ),
          Divider(), // 구분선
          Padding(
            padding: const EdgeInsets.all(12),// 여백
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('인식된 텍스트:', style: TextStyle(fontWeight: FontWeight.bold)),// 제목
                SizedBox(height: 8),
                Text(_recognizedText),  // OCR 결과 출력
              ],
            ),
          ),
        ],
      ),
    );
  }
}

