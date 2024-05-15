import 'package:get/get.dart';
import 'package:tiktok_clone/models/user.dart';

class UserController extends GetxController {
  var currentUser = Rxn<User>();

  void setUser(User user) {
    currentUser.value = user;
  }

  void clearUser() {
    currentUser.value = null;
  }

  String get currentUserId => currentUser.value?.uid ?? '';
}
