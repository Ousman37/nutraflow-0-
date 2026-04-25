import 'package:flutter/services.dart';
import 'package:get/get.dart';

class WelcomeController extends GetxController {
  final RxList<String> selectedCategories = <String>[].obs;

  bool isSelected(String label) => selectedCategories.contains(label);

  void toggle(String label) {
    HapticFeedback.selectionClick();
    if (selectedCategories.contains(label)) {
      selectedCategories.remove(label);
    } else {
      selectedCategories.add(label);
    }
  }
}
