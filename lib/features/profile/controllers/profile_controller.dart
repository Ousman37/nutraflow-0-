import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_profile_model.dart';

class ProfileController extends GetxController {
  final _authController = Get.find<AuthController>();

  UserProfileModel? get profile => _authController.userProfile.value;

  String get name => _authController.currentUserName;

  Future<void> signOut() async {
    await _authController.signOut();
  }
}
