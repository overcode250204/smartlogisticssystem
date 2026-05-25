import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraLivePreviewPage extends StatefulWidget {
  final CameraDescription camera;
  const CameraLivePreviewPage({super.key, required this.camera});

  @override
  State<CameraLivePreviewPage> createState() => _CameraLivePreviewPageState();
}

class _CameraLivePreviewPageState extends State<CameraLivePreviewPage> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _cameraController = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _cameraController.initialize();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Đặt giấy tờ vào khung hình',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Center(child: CameraPreview(_cameraController));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () async {
          try {
            await _initializeControllerFuture;

            final image = await _cameraController.takePicture();
            if (context.mounted) {
              // Trả file ảnh về cho màn hình Đăng ký
              Navigator.pop(context, image);
            }
          } catch (e) {
            print("Lỗi chụp ảnh: $e");
          }
        },
        child: const Icon(Icons.camera_alt, color: Colors.black),
      ),
    );
  }
}
