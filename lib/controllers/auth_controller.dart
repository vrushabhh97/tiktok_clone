import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:tiktok_clone/constants.dart';
import 'package:tiktok_clone/models/user.dart' as model;
import 'package:tiktok_clone/views/screens/authentication/login_screen.dart';
import 'package:tiktok_clone/views/screens/home_screen.dart';

class AuthController extends GetxController {
  static AuthController instance = Get.find();
  CameraController? cameraController;
  List<CameraDescription>? cameras;
  late Rx<User?> _user;
  Rx<File?> _pickedImage = Rx<File?>(null);
  File? get profilePhoto => _pickedImage.value;

  @override
  void onReady() {
    super.onReady();
    _user = Rx<User?>(firebaseAuth.currentUser);
    _user.bindStream(firebaseAuth.authStateChanges());
    ever(_user, _setInitialScreen);
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    cameraController = CameraController(
      cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras!.first),
      ResolutionPreset.medium,
    );
    await cameraController!.initialize();
  }

  Future<void> startRecording() async {
    try {
      if (cameraController != null &&
          !cameraController!.value.isRecordingVideo) {
        await cameraController!.startVideoRecording();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to start recording: $e');
    }
  }

  Future<void> stopRecordingAndSave() async {
    if (cameraController != null && cameraController!.value.isRecordingVideo) {
      try {
        final videoFile = await cameraController!.stopVideoRecording();
        await GallerySaver.saveVideo(videoFile.path);
      } catch (e) {
        Get.snackbar('Error', 'Failed to stop recording and save video: $e');
      }
    }
  }

  void _setInitialScreen(User? user) {
    if (user == null) {
      // User logged out
      stopRecordingAndSave().then((_) {
        Get.offAll(() => LoginScreen());
        if (cameraController != null) {
          cameraController!.dispose();
          cameraController = null;
        }
      });
    } else {
      // User logs in or switches accounts
      if (cameraController == null) {
        initializeCamera().then((_) {
          startRecording();
        });
      } else {
        startRecording();
      }
      Get.offAll(() => HomeScreen());
    }
  }

  void pickImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      _pickedImage.value = File(pickedImage.path);
      Get.snackbar('Profile Picture',
          'You have successfully selected your profile picture!');
    }
  }

  Future<String> _uploadToStorage(File image) async {
    Reference ref = firebaseStorage
        .ref()
        .child('profilePics')
        .child(firebaseAuth.currentUser!.uid);
    UploadTask uploadTask = ref.putFile(image);
    TaskSnapshot snap = await uploadTask;
    return await snap.ref.getDownloadURL();
  }

  Future<void> registerUser(
      String username, String email, String password, String guestId) async {
    if (username.isNotEmpty &&
        email.isNotEmpty &&
        password.isNotEmpty &&
        guestId.isNotEmpty) {
      try {
        UserCredential cred = await firebaseAuth.createUserWithEmailAndPassword(
            email: email, password: password);
        model.User user = model.User(
            name: username,
            email: email,
            guestId: guestId,
            uid: cred.user!.uid);
        await firestore
            .collection('users')
            .doc(cred.user!.uid)
            .set(user.toJson());
      } catch (e) {
        Get.snackbar('Error Creating Account', e.toString());
      }
    } else {
      Get.snackbar('Error Creating Account', 'Please enter all the fields');
    }
  }

  void loginUser(String email, String password) async {
    if (email.isNotEmpty && password.isNotEmpty) {
      try {
        await firebaseAuth.signInWithEmailAndPassword(
            email: email, password: password);
      } catch (e) {
        Get.snackbar('Error Logging in', e.toString());
      }
    } else {
      Get.snackbar('Error Logging in Account', 'Please enter all the fields');
    }
  }

  Future<void> logout() async {
    try {
      await stopRecordingAndSave();
      await cameraController?.dispose();
      cameraController = null;
      await firebaseAuth.signOut();
      Get.offAll(() => LoginScreen());
    } catch (e) {
      Get.snackbar('Error Logging Out', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void loginWithGuestId(String guestId) async {
    if (guestId.isNotEmpty) {
      try {
        var userSnapshot = await firestore
            .collection('users')
            .where('guestId', isEqualTo: guestId)
            .limit(1)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          if (cameraController == null) {
            await initializeCamera();
          }
          startRecording();
          Get.offAll(() => HomeScreen());
        } else {
          Get.snackbar('Error', 'Guest ID not found');
        }
      } catch (e) {
        Get.snackbar("Login Error", 'Failed to log in with Guest ID: $e');
      }
    } else {
      Get.snackbar("Error", "Guest ID cannot be empty");
    }
  }
}
