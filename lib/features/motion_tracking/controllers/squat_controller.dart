import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../core/utils/angle_utils.dart';

/// Phases of a squat repetition.
enum SquatPhase { standing, descending, bottom, ascending }

/// Result emitted on every processed frame.
class SquatAnalysisResult {
  final int repCount;
  final SquatPhase phase;
  final double kneeAngle;       // degrees at the knee joint
  final double hipAngle;        // degrees at the hip joint
  final bool formWarning;       // true if knee angle is dangerously acute
  final String feedbackMessage;

  const SquatAnalysisResult({
    required this.repCount,
    required this.phase,
    required this.kneeAngle,
    required this.hipAngle,
    required this.formWarning,
    required this.feedbackMessage,
  });
}

/// Stateful controller that analyses a stream of [Pose] objects and counts
/// squat repetitions while providing real-time form feedback.
///
/// Detection strategy (using the left-body landmarks; falls back to right):
///   1. Measure the knee angle (hip→knee→ankle).
///   2. Measure the hip angle (shoulder→hip→knee).
///   3. Transition through STANDING → DESCENDING → BOTTOM → ASCENDING → STANDING.
///   4. Increment rep count on each ASCENDING → STANDING transition.
class SquatController extends ChangeNotifier {
  // ── Thresholds ────────────────────────────────────────────────────────────
  static const double _standingKneeAngle = 160.0;  // near-straight legs
  static const double _squatDepthAngle   =  95.0;  // parallel or below
  static const double _formWarningAngle  =  55.0;  // dangerously acute knee

  int _repCount = 0;
  SquatPhase _phase = SquatPhase.standing;
  SquatAnalysisResult? _lastResult;

  int get repCount => _repCount;
  SquatPhase get phase => _phase;
  SquatAnalysisResult? get lastResult => _lastResult;

  void reset() {
    _repCount = 0;
    _phase = SquatPhase.standing;
    _lastResult = null;
    notifyListeners();
  }

  /// Call this once per camera frame with the detected [pose].
  void processPose(Pose pose) {
    final landmarks = pose.landmarks;

    // Prefer left side; fall back to right if landmarks are absent / low confidence.
    PoseLandmark? hip   = _pick(landmarks, PoseLandmarkType.leftHip,   PoseLandmarkType.rightHip);
    PoseLandmark? knee  = _pick(landmarks, PoseLandmarkType.leftKnee,  PoseLandmarkType.rightKnee);
    PoseLandmark? ankle = _pick(landmarks, PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle);
    PoseLandmark? shoulder = _pick(landmarks, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);

    if (hip == null || knee == null || ankle == null || shoulder == null) {
      return; // not enough landmarks visible
    }

    final kneeAngle = calculateAngle(hip, knee, ankle);
    final hipAngle  = calculateAngle(shoulder, hip, knee);

    final prevPhase = _phase;

    switch (_phase) {
      case SquatPhase.standing:
        if (kneeAngle < _standingKneeAngle) {
          _phase = SquatPhase.descending;
        }
        break;
      case SquatPhase.descending:
        if (kneeAngle <= _squatDepthAngle) {
          _phase = SquatPhase.bottom;
        } else if (kneeAngle >= _standingKneeAngle) {
          // User stood back up without reaching depth
          _phase = SquatPhase.standing;
        }
        break;
      case SquatPhase.bottom:
        if (kneeAngle > _squatDepthAngle) {
          _phase = SquatPhase.ascending;
        }
        break;
      case SquatPhase.ascending:
        if (kneeAngle >= _standingKneeAngle) {
          _repCount++;
          _phase = SquatPhase.standing;
        }
        break;
    }

    final formWarning = kneeAngle < _formWarningAngle;
    final feedback    = _buildFeedback(_phase, kneeAngle, hipAngle, formWarning);

    _lastResult = SquatAnalysisResult(
      repCount: _repCount,
      phase: _phase,
      kneeAngle: kneeAngle,
      hipAngle: hipAngle,
      formWarning: formWarning,
      feedbackMessage: feedback,
    );

    if (prevPhase != _phase || formWarning) {
      notifyListeners();
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  PoseLandmark? _pick(
    Map<PoseLandmarkType, PoseLandmark> map,
    PoseLandmarkType preferred,
    PoseLandmarkType fallback,
  ) {
    final a = map[preferred];
    final b = map[fallback];
    if (a != null && a.likelihood > 0.5) return a;
    if (b != null && b.likelihood > 0.5) return b;
    return null;
  }

  String _buildFeedback(
    SquatPhase phase,
    double kneeAngle,
    double hipAngle,
    bool formWarning,
  ) {
    if (formWarning) return '⚠️ Knees too far forward — protect your joints!';
    switch (phase) {
      case SquatPhase.standing:
        return 'Stand straight — ready to squat';
      case SquatPhase.descending:
        return 'Lower down — keep chest up';
      case SquatPhase.bottom:
        return 'Good depth! Now push up through heels';
      case SquatPhase.ascending:
        return 'Drive up — squeeze glutes at the top';
    }
  }
}
