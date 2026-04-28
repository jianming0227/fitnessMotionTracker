import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../services/hive_service.dart';
import '../../../services/models/workout_session.dart';
import '../controllers/squat_controller.dart';
import '../widgets/pose_painter.dart';

class PoseDetectorView extends StatefulWidget {
  const PoseDetectorView({super.key});

  @override
  State<PoseDetectorView> createState() => _PoseDetectorViewState();
}

class _PoseDetectorViewState extends State<PoseDetectorView>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  bool _isDetecting = false;
  bool _isCameraInitialized = false;
  Pose? _currentPose;
  Size? _imageSize;

  late final SquatController _squatController;
  late final Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _squatController = SquatController();
    _stopwatch = Stopwatch()..start();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.accurate,
      ),
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
      _cameraController!.startImageStream(_processFrame);
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isDetecting || _poseDetector == null) return;
    _isDetecting = true;

    try {
      final camera = _cameraController!.description;
      final rotation = InputImageRotationValue.fromRawValue(
            camera.sensorOrientation,
          ) ??
          InputImageRotation.rotation0deg;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return;

      final planes = image.planes;
      final bytes = planes[0].bytes;

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: planes[0].bytesPerRow,
        ),
      );

      final poses = await _poseDetector!.processImage(inputImage);

      if (poses.isNotEmpty && mounted) {
        setState(() {
          _currentPose = poses.first;
          _imageSize = Size(image.width.toDouble(), image.height.toDouble());
        });
        _squatController.processPose(poses.first);
      }
    } catch (e) {
      debugPrint('Pose detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  Future<void> _stopAndSave() async {
    _stopwatch.stop();
    await _cameraController?.stopImageStream();
    if (!mounted) return;
    final hive = context.read<HiveService>();
    final session = WorkoutSession(
      id: const Uuid().v4(),
      exerciseType: 'Squat',
      repCount: _squatController.repCount,
      durationSeconds: _stopwatch.elapsed.inSeconds,
      date: DateTime.now(),
      avgFormScore: null,
    );
    await hive.saveSession(session);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      _cameraController?.startImageStream(_processFrame);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _poseDetector?.close();
    _squatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _squatController,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_isCameraInitialized && _cameraController != null)
              CameraPreview(_cameraController!),

            if (_currentPose != null && _imageSize != null)
              Consumer<SquatController>(
                builder: (_, ctrl, __) => CustomPaint(
                  painter: PosePainter(
                    pose: _currentPose!,
                    imageSize: _imageSize!,
                    isFrontCamera: true,
                    formWarning: ctrl.lastResult?.formWarning ?? false,
                  ),
                ),
              ),

            // Top Bar
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StreamBuilder<int>(
                    stream: Stream.periodic(
                      const Duration(seconds: 1),
                      (i) => i,
                    ),
                    builder: (_, __) => _GlassChip(
                      icon: Icons.timer_outlined,
                      label: formatDuration(_stopwatch.elapsed),
                    ),
                  ),
                  GestureDetector(
                    onTap: _stopAndSave,
                    child: const _GlassChip(
                      icon: Icons.stop_circle_outlined,
                      label: 'Finish',
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),

            // Rep Counter & Feedback
            Positioned(
              bottom: 40,
              left: 16,
              right: 16,
              child: Consumer<SquatController>(
                builder: (_, ctrl, __) => Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: ctrl.lastResult?.formWarning == true
                              ? AppColors.error
                              : AppColors.primary,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${ctrl.repCount}',
                            style: AppTextStyles.counterDisplay,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('REPS', style: AppTextStyles.labelLarge),
                              Text(
                                _phaseLabel(ctrl.phase),
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        ctrl.lastResult?.feedbackMessage ??
                            'Get into position to start',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: ctrl.lastResult?.formWarning == true
                              ? AppColors.error
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _phaseLabel(SquatPhase phase) {
    switch (phase) {
      case SquatPhase.standing:
        return 'Standing';
      case SquatPhase.descending:
        return 'Going Down';
      case SquatPhase.bottom:
        return 'Deep Squat';
      case SquatPhase.ascending:
        return 'Coming Up';
    }
  }
}

class _GlassChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _GlassChip({
    required this.icon,
    required this.label,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
