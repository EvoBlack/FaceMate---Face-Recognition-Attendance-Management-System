import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CameraPreviewWidget extends StatefulWidget {
  final CameraController controller;
  final Function(Uint8List) onImageCaptured;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    required this.onImageCaptured,
  });

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  bool _isCapturing = false;

  Future<void> _captureImage() async {
    if (_isCapturing) return;
    
    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile image = await widget.controller.takePicture();
      final Uint8List imageBytes = await image.readAsBytes();
      widget.onImageCaptured(imageBytes);
    } catch (e) {
      developer.log('Error capturing image: $e', name: 'CameraPreview');
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera Preview
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: CameraPreview(widget.controller),
        ),
        
        // Face Detection Overlay
        Positioned.fill(
          child: CustomPaint(
            painter: FaceDetectionOverlayPainter(),
          ),
        ),
        
        // Capture Button
        Positioned(
          bottom: 20.h,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _captureImage,
              child: Container(
                width: 70.w,
                height: 70.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                ),
                child: _isCapturing
                    ? const CircularProgressIndicator()
                    : Icon(
                        Icons.camera_alt,
                        size: 30.w,
                        color: Colors.black54,
                      ),
              ),
            ),
          ),
        ),
        
        // Instructions
        Positioned(
          top: 16.h,
          left: 16.w,
          right: 16.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'Position face in frame and tap camera',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

class FaceDetectionOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw face detection frame
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.7,
      height: size.height * 0.5,
    );

    // Draw rounded rectangle
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawRRect(rrect, paint);

    // Draw corner indicators
    const cornerLength = 20.0;
    final cornerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Top-left corner
    canvas.drawLine(
      Offset(rect.left, rect.top + cornerLength),
      Offset(rect.left, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.top),
      Offset(rect.right, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(rect.left, rect.bottom - cornerLength),
      Offset(rect.left, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.bottom),
      Offset(rect.right, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right, rect.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}