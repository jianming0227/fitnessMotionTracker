import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Calculates the angle (in degrees) at point B formed by rays B→A and B→C.
double calculateAngle(
  PoseLandmark a,
  PoseLandmark b,
  PoseLandmark c,
) {
  final radians = math.atan2(c.y - b.y, c.x - b.x) -
      math.atan2(a.y - b.y, a.x - b.x);
  double angle = radians.abs() * (180 / math.pi);
  if (angle > 180) angle = 360 - angle;
  return angle;
}

/// Returns the midpoint Y coordinate between two landmarks.
double midpointY(PoseLandmark a, PoseLandmark b) => (a.y + b.y) / 2;

/// Normalises a landmark coordinate to [0,1] relative to image dimensions.
double normaliseX(double x, double imageWidth) => x / imageWidth;
double normaliseY(double y, double imageHeight) => y / imageHeight;
