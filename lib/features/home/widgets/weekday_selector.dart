import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/home_controller.dart';

class WeekdaySelector extends StatelessWidget {
  final HomeController ctrl;
  const WeekdaySelector({super.key, required this.ctrl});

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = ctrl.selectedDayIndex.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          // Each item is Expanded so it fills equal width — guaranteed 44px+
          // touch area on every screen size without overflow risk.
          children: List.generate(7, (i) {
            final isSelected = i == selected;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ctrl.selectDay(i);
                },
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: 44,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.12),
                      ),
                      child: Center(
                        child: Text(
                          _labels[i],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? const Color(0xFF3D60D8)
                                : Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    });
  }
}
