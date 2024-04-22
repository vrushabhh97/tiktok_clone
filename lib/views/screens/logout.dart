import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone/constants.dart';
import 'package:tiktok_clone/controllers/auth_controller.dart';
import 'package:tiktok_clone/views/screens/authentication/login_screen.dart';

class LogoutPage extends StatelessWidget {
  LogoutPage({super.key});

  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logout Page'),
        backgroundColor: backgroundColor,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            authController.logout();
            // After logout, navigate to the login screen
            Get.offAll(() => LoginScreen());
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.red, // Button text color
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.exit_to_app),
              SizedBox(width: 8),
              Text('Logout'),
            ],
          ),
        ),
      ),
    );
  }
}
