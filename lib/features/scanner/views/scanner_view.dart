import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import '../../../core/constants/app_colors.dart';
import '../../meal/controllers/add_meal_controller.dart';
import '../../meal/services/barcode_lookup_service.dart';
import '../../../routes/app_routes.dart';

// The three states the live barcode camera can be in — the UI needs to
// distinguish "haven't asked yet" from "asked and refused" from "refused
// permanently", since only the last one gets an Open Settings action.
enum _CameraPermission { unknown, granted, denied, permanentlyDenied }

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  final _barcodeLookup = BarcodeLookupService();
  int _modeIndex = 0;
  bool _capturing = false;

  // Only created while Barcode mode is active — a live camera feed isn't
  // needed (and shouldn't keep running) for the still-photo modes.
  MobileScannerController? _barcodeController;
  bool _processingBarcode = false;
  _CameraPermission _cameraPermission = _CameraPermission.unknown;

  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  late final Animation<double> _pulseAnim = Tween<double>(
    begin: 0.85,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

  static const _modes = ['Scan Food', 'Barcode', 'Food Label', 'Library'];
  static const _barcodeModeIndex = 1;
  static const _labelModeIndex = 2;
  static const _libraryModeIndex = 3;

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _barcodeController?.dispose();
    super.dispose();
  }

  // ── Mode switching ──────────────────────────────────────────────────────────

  void _selectMode(int i) {
    HapticFeedback.selectionClick();
    setState(() => _modeIndex = i);

    if (i == _barcodeModeIndex) {
      // Never show the live MobileScanner widget until permission is
      // confirmed granted — showing it before that (or after a denial) is
      // exactly what produces a black/empty preview with no explanation.
      unawaited(_ensureCameraPermission());
    } else {
      // Stop the camera when leaving Barcode mode — no reason to keep it
      // running (battery, privacy) while the user is on another tab.
      _barcodeController?.dispose();
      _barcodeController = null;
      _cameraPermission = _CameraPermission.unknown;
    }

    if (i == _libraryModeIndex) _openGallery();
  }

  // Checks the current camera permission and requests it if it hasn't been
  // decided yet. Only creates (and starts) the MobileScannerController once
  // permission is confirmed granted — this is the actual fix for the black
  // preview, which happened because the live camera widget was previously
  // shown unconditionally, before permission was known to be granted.
  Future<void> _ensureCameraPermission() async {
    var status = await ph.Permission.camera.status;
    debugPrint('[Scanner] camera permission status: $status');

    if (status.isDenied) {
      status = await ph.Permission.camera.request();
      debugPrint('[Scanner] camera permission after request: $status');
    }

    if (!mounted) return;

    setState(() {
      if (status.isGranted || status.isLimited) {
        _cameraPermission = _CameraPermission.granted;
      } else if (status.isPermanentlyDenied || status.isRestricted) {
        _cameraPermission = _CameraPermission.permanentlyDenied;
      } else {
        _cameraPermission = _CameraPermission.denied;
      }
    });

    if (_cameraPermission == _CameraPermission.granted) {
      try {
        _barcodeController ??= MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
        );
      } catch (e, st) {
        // Never let a camera-initialization failure fall through silently —
        // log it and fall back to the same "unavailable" messaging the
        // errorBuilder shows for a running-camera failure.
        debugPrint('[Scanner] MobileScannerController failed to initialize: '
            '$e\n$st');
        if (mounted) {
          setState(() => _cameraPermission = _CameraPermission.denied);
        }
      }
    } else {
      debugPrint('[Scanner] camera permission not granted '
          '($_cameraPermission) — not starting the live camera.');
    }
  }

  // ── Barcode detection ────────────────────────────────────────────────────────

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_processingBarcode) return;
    final code = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _processingBarcode = true);
    HapticFeedback.mediumImpact();

    try {
      final result = await _barcodeLookup.lookup(code);
      if (!mounted) return;
      if (Get.isRegistered<AddMealController>()) {
        Get.find<AddMealController>().resetAnalysis();
      }
      await Get.toNamed(
        AppRoutes.addMeal,
        arguments: {'barcodeResult': result},
      );
    } on BarcodeProductNotFoundException {
      if (!mounted) return;
      Get.snackbar(
        'Product Not Found',
        'No nutrition data found for barcode $code. Try Scan Food or '
            'Library instead.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Lookup Failed',
        'Could not look up this product. Check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      if (mounted) setState(() => _processingBarcode = false);
    }
  }

  // ── Photo capture (Scan Food / Food Label) ───────────────────────────────────

  Future<void> _capture() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    HapticFeedback.heavyImpact();

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (!mounted) return;
      if (picked != null) {
        _navigateToAddMeal(File(picked.path), isLabel: _modeIndex == _labelModeIndex);
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showPermissionError(e);
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _openGallery() async {
    HapticFeedback.lightImpact();
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (!mounted) return;
      if (picked != null) {
        _navigateToAddMeal(File(picked.path));
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showPermissionError(e);
    }
  }

  void _showPermissionError(PlatformException e) {
    final isPhotoAccess = e.code.toLowerCase().contains('photo') ||
        e.code.toLowerCase().contains('gallery');
    Get.snackbar(
      'Permission Needed',
      isPhotoAccess
          ? 'Photo library access is required. Enable it in Settings to import meal photos.'
          : 'Camera access is required. Enable it in Settings to scan meals.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void _navigateToAddMeal(File image, {bool isLabel = false}) {
    // If AddMealController is already registered (from a previous visit),
    // reset it first so onInit picks up the new image.
    if (Get.isRegistered<AddMealController>()) {
      Get.find<AddMealController>().resetAnalysis();
    }
    Get.toNamed(
      AppRoutes.addMeal,
      arguments: {'image': image, if (isLabel) 'isLabel': true},
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;
    final isBarcodeMode = _modeIndex == _barcodeModeIndex;
    final needsCameraPermissionUi = isBarcodeMode &&
        (_cameraPermission == _CameraPermission.denied ||
            _cameraPermission == _CameraPermission.permanentlyDenied);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background — live camera in Barcode mode, decorative otherwise ──
          if (isBarcodeMode && _cameraPermission == _CameraPermission.granted &&
              _barcodeController != null)
            MobileScanner(
              controller: _barcodeController!,
              onDetect: _onBarcodeDetected,
              errorBuilder: (context, error) {
                debugPrint('[Scanner] MobileScanner errorBuilder: '
                    '${error.errorCode.name} ${error.errorDetails?.message}');
                return Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Camera unavailable (${error.errorCode.name}). '
                    'Enable camera access in Settings to scan barcodes.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                );
              },
            )
          else if (isBarcodeMode &&
              (_cameraPermission == _CameraPermission.denied ||
                  _cameraPermission == _CameraPermission.permanentlyDenied))
            _CameraPermissionNeeded(
              permanentlyDenied:
                  _cameraPermission == _CameraPermission.permanentlyDenied,
              onRetry: _ensureCameraPermission,
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

          // ── Top bar ─────────────────────────────────────────────────────
          Positioned(
            top: topPad + 12,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _IconBtn(
                    icon: Icons.close_rounded,
                    onTap: () => Get.back(),
                  ),
                  const Spacer(),
                  Text(
                    'NutraFlow Scanner',
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  // Real torch control in Barcode mode (the only mode with a
                  // live camera session this app controls); inert elsewhere,
                  // since photo modes hand off to the system camera, which
                  // has its own flash control this app can't drive.
                  if (isBarcodeMode && _barcodeController != null)
                    ValueListenableBuilder<MobileScannerState>(
                      valueListenable: _barcodeController!,
                      builder: (context, state, _) {
                        final on = state.torchState == TorchState.on;
                        return _IconBtn(
                          icon: on
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          onTap: () => _barcodeController!.toggleTorch(),
                        );
                      },
                    )
                  else
                    _IconBtn(
                      icon: Icons.flash_off_rounded,
                      onTap: null,
                    ),
                ],
              ),
            ),
          ),

          // ── Mode tabs ────────────────────────────────────────────────────
          Positioned(
            top: topPad + 68,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _modes.length,
                itemBuilder: (_, i) {
                  final active = i == _modeIndex;
                  return GestureDetector(
                    onTap: () => _selectMode(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 7),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _modes[i],
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: active
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Viewfinder frame — hidden while asking for camera permission,
          // so it doesn't visually clash with that message ───────────────
          if (!needsCameraPermissionUi)
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: _ViewfinderFrame(
                    size: size.width * 0.74,
                  ),
                ),
              ),
            ),

          // ── Hint text ───────────────────────────────────────────────────
          if (!needsCameraPermissionUi)
            Positioned(
              bottom: size.height * 0.28,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  _processingBarcode ? 'Looking up product…' : _hintText,
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // ── Bottom controls ──────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 32,
                top: 32,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Gallery button
                  _IconBtn(
                    icon: Icons.photo_library_outlined,
                    size: 48,
                    onTap: _openGallery,
                  ),

                  // Capture button — inert in Barcode mode, where detection
                  // is continuous and automatic instead of shutter-driven.
                  GestureDetector(
                    onTap: isBarcodeMode ? null : _capture,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: _capturing ? 66 : 72,
                      height: _capturing ? 66 : 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isBarcodeMode
                            ? Colors.white.withValues(alpha: 0.35)
                            : Colors.white,
                        boxShadow: isBarcodeMode
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                      ),
                      child: _capturing || _processingBarcode
                          ? const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary),
                                ),
                              ),
                            )
                          : Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isBarcodeMode
                                    ? Colors.transparent
                                    : AppColors.primary,
                              ),
                            ),
                    ),
                  ),

                  // Balances the gallery button so the shutter stays centered.
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _hintText {
    switch (_modeIndex) {
      case 0:
        return 'Point at your meal — AI will analyze it';
      case _barcodeModeIndex:
        return 'Align barcode within the frame — scans automatically';
      case _labelModeIndex:
        return 'Photograph the nutrition facts label';
      default:
        return 'Choose a photo from your library';
    }
  }
}

// ── Camera permission needed ──────────────────────────────────────────────────
// Shown instead of the live camera in Barcode mode when permission was
// denied — never renders the live camera view without permission, so this
// replaces what would otherwise be a black/empty preview with an actual
// explanation and a way to recover.

class _CameraPermissionNeeded extends StatelessWidget {
  final bool permanentlyDenied;
  final VoidCallback onRetry;

  const _CameraPermissionNeeded({
    required this.permanentlyDenied,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.videocam_off_rounded,
            size: 40,
            color: Colors.white.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 16),
          const Text(
            'Camera Access Needed',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            permanentlyDenied
                ? 'Camera access was denied. Enable it in Settings to scan barcodes.'
                : 'NutraFlow needs camera access to scan barcodes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.65),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              if (permanentlyDenied) {
                ph.openAppSettings();
              } else {
                onRetry();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                permanentlyDenied ? 'Open Settings' : 'Allow Camera Access',
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Viewfinder frame ──────────────────────────────────────────────────────────

class _ViewfinderFrame extends StatelessWidget {
  final double size;
  const _ViewfinderFrame({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const r = 22.0;
    const len = 36.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, len + r)
        ..lineTo(0, r)
        ..arcToPoint(Offset(r, 0), radius: const Radius.circular(r))
        ..lineTo(len + r, 0),
      paint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len - r, 0)
        ..lineTo(size.width - r, 0)
        ..arcToPoint(Offset(size.width, r), radius: const Radius.circular(r))
        ..lineTo(size.width, len + r),
      paint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - len - r)
        ..lineTo(0, size.height - r)
        ..arcToPoint(Offset(r, size.height), radius: const Radius.circular(r))
        ..lineTo(len + r, size.height),
      paint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len - r, size.height)
        ..lineTo(size.width - r, size.height)
        ..arcToPoint(Offset(size.width, size.height - r),
            radius: const Radius.circular(r))
        ..lineTo(size.width, size.height - len - r),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Icon button ───────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: onTap == null ? 0.06 : 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: onTap == null ? 0.35 : 1.0),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
