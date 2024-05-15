import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:tiktok_clone/constants.dart';
import 'package:tiktok_clone/controllers/auth_controller.dart';
import 'package:tiktok_clone/views/screens/authentication/login_screen.dart';
import 'package:tiktok_clone/views/screens/authentication/signup_screen.dart';
import 'package:tiktok_clone/views/screens/home_screen.dart';
import 'package:tiktok_clone/views/screens/video_stats_provider.dart';
import 'package:tiktok_clone/controllers/user_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp().then((value) {
    Get.put(AuthController());
    Get.put(UserController());
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VideoStatsProvider>(
      create: (_) => VideoStatsProvider(),
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TikTok Clone',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: backgroundColor,
        ),
        home: SignupScreen(), // Adjust based on auth state as necessary
      ),
    );
  }
}
