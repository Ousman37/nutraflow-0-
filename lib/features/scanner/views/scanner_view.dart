import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../meal/controllers/add_meal_controller.dart';
import '../../../routes/app_routes.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  int _modeIndex = 0;
  bool _flashOn = false;
  bool _capturing = false;

  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  late final Animation<double> _pulseAnim = Tween<double>(
    begin: 0.85,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

  static const _modes = ['Scan Food', 'Barcode', 'Food Label', 'Library'];

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    HapticFeedback.heavyImpact();

    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (!mounted) return;
    setState(() => _capturing = false);

    if (picked != null) {
      _navigateToAddMeal(File(picked.path));
    }
  }

  Future<void> _openGallery() async {
    HapticFeedback.lightImpact();
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (!mounted) return;
    if (picked != null) {
      _navigateToAddMeal(File(picked.path));
    }
  }

  void _navigateToAddMeal(File image) {
    // If AddMealController is already registered (from a previous visit),
    // reset it first so onInit picks up the new image.
    if (Get.isRegistered<AddMealController>()) {
      Get.find<AddMealController>().resetAnalysis();
    }
    Get.toNamed(
      AppRoutes.addMeal,
      arguments: {'image': image},
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background (dark camera-preview-like) ───────────────────────
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
                  _IconBtn(
                    icon: _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    onTap: () => setState(() => _flashOn = !_flashOn),
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
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _modeIndex = i);
                      if (i == 3) _openGallery();
                    },
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

          // ── Viewfinder frame ─────────────────────────────────────────────
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
          Positioned(
            bottom: size.height * 0.28,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                _hintText,
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

                  // Capture button
                  GestureDetector(
                    onTap: _capture,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: _capturing ? 66 : 72,
                      height: _capturing ? 66 : 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: _capturing
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
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                  ),

                  // Flip/info button (placeholder)
                  _IconBtn(
                    icon: Icons.flip_camera_ios_outlined,
                    size: 48,
                    onTap: () => HapticFeedback.lightImpact(),
                  ),
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
      case 1:
        return 'Align barcode within the frame';
      case 2:
        return 'Photograph the nutrition facts label';
      default:
        return 'Choose a photo from your library';
    }
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
  final VoidCallback onTap;
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
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
