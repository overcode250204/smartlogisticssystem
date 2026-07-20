import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/feature/authentication/screens/camera_live_preview_page.dart';

/// Opens the device camera (reusing the app's existing CameraLivePreviewPage)
/// and returns the captured proof photo, or null if cancelled/unavailable.
Future<XFile?> captureProofPhoto(BuildContext context) async {
  final cameras = await availableCameras();
  if (cameras.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy camera trên thiết bị')),
      );
    }
    return null;
  }
  if (!context.mounted) return null;
  return Navigator.push<XFile>(
    context,
    MaterialPageRoute(
      builder: (context) => CameraLivePreviewPage(camera: cameras.first),
    ),
  );
}
