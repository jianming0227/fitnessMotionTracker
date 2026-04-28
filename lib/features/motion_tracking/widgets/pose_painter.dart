import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../core/constants/app_colors.dart';

/// Renders the detected [Pose] skeleton on top of the camera preview.
///
/// [imageSize]  – the pixel dimensions of the camera frame.
/// [isFrontCamera] – mirrors X coordinates for selfie camera.
class PosePainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;
  final bool isFrontCamera;
  final bool formWarning;

  PosePainter({
    required this.pose,
    required this.imageSize,
    this.isFrontCamera = true,
    this.formWarning = false,
  });

  // Skeleton connectivity: list of landmark-pair indices for bone lines.
  static const List<List<PoseLandmarkType>> _connections = [
    // Torso
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    // Left arm
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    // Right arm
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    // Left leg
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    [PoseLandmarkType.leftAnkle, PoseLandmarkType.leftHeel],
    [PoseLandmarkType.leftHeel, PoseLandmarkType.leftFootIndex],
    // Right leg
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    [PoseLandmarkType.rightAnkle, PoseLandmarkType.rightHeel],
    [PoseLandmarkType.rightHeel, PoseLandmarkType.rightFootIndex],
  ];

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final linePaint = Paint()
      ..color = formWarning ? AppColors.skeletonWarning : AppColors.skeletonLine
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final jointPaint = Paint()
      ..color = formWarning ? AppColors.skeletonWarning : AppColors.skeletonJoint
      ..style = PaintingStyle.fill;

    final landmarks = pose.landmarks;

    // Draw bones
    for (final connection in _connections) {
      final start = landmarks[connection[0]];
      final end   = landmarks[connection[1]];
      if (start != null && end != null &&
          start.likelihood > 0.4 && end.likelihood > 0.4) {
        canvas.drawLine(
          _translate(start, canvasSize),
          _translate(end, canvasSize),
          linePaint,
        );
      }
    }

    // Draw joints
    for (final landmark in landmarks.values) {
      if (landmark.likelihood > 0.4) {
        canvas.drawCircle(_translate(landmark, canvasSize), 5, jointPaint);
      }
    }
  }

  Offset _translate(PoseLandmark landmark, Size canvasSize) {
    final scaleX = canvasSize.width  / imageSize.width;
    final scaleY = canvasSize.height / imageSize.height;
    double x = landmark.x * scaleX;
    if (isFrontCamera) x = canvasSize.width - x;
    final double y = landmark.y * scaleY;
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(PosePainter oldDelegate) =>
      oldDelegate.pose != pose || oldDelegate.formWarning != formWarning;
}
