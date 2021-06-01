import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tapemobileapp/services/authentication_service.dart';
import 'package:tapemobileapp/services/firebase_analytics_service.dart';
import 'package:tapemobileapp/services/firebase_storage_service.dart';
import 'package:tapemobileapp/services/firestore_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tapemobileapp/viewmodel/base_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as ImageCompress;
import '../app/locator.dart';

class ProfileViewModel extends BaseModel {
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final FirestoreService _firestoreService = locator<FirestoreService>();
  final FirebaseStorageService _firebaseStorageService =
      locator<FirebaseStorageService>();
  final FirebaseAnalyticsService _firebaseAnalyticsService =
      locator<FirebaseAnalyticsService>();

  File selectedPic;
  String downloadURL;
  bool uploadingProfilePic = false;
  String titleName;

  File imageFile;
  final picker = ImagePicker();

  ProfileViewModel(String downloadURL) {
    this.downloadURL = downloadURL;
  }

  String get myUID => _authenticationService.currentUser.uid;

  Future updateDisplayName(String newName) async {
    logEvent("Profile", {"type": "displayName"});
    await _firestoreService.saveUserInfo(myUID, {"displayName": newName});
    notifyListeners();
  }

  updateTitle(name) {
    titleName = name;
    notifyListeners();
  }

  Future getImage(BuildContext context) async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      selectedPic = File(pickedFile.path);
      showCropView(context);
    } else {
      print('No image selected.');
    }
  }

  // Analytics Methods
  void logEvent(String eventName, Map<String, dynamic> data) {
    _firebaseAnalyticsService.logEvent(eventName, parameters: data);
  }

  Future<Null> showCropView(BuildContext context) async {
    File croppedFile = await ImageCropper.cropImage(
        compressQuality: 100,
        sourcePath: selectedPic.path,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        androidUiSettings: AndroidUiSettings(
            cropFrameColor: Colors.white,
            cropFrameStrokeWidth: 2,
            showCropGrid: false,
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            hideBottomControls: true,
            lockAspectRatio: true),
        iosUiSettings: IOSUiSettings(
          rotateClockwiseButtonHidden: true,
          rotateButtonsHidden: true,
          resetAspectRatioEnabled: false,
          aspectRatioLockEnabled: false,
          minimumAspectRatio: 1,
          aspectRatioPickerButtonHidden: true,
          title: 'Crop Image',
        ));

    if (croppedFile != null) {
      compressImage(context, croppedFile);
    }
  }

  Future compressImage(BuildContext context, File cropped) async {
    uploadingProfilePic = true;
    notifyListeners();
    var tempDir = await getTemporaryDirectory();
    String profilePicPath = '${tempDir.path}/$myUID.jpg';
    ImageCompress.Image toResize =
        ImageCompress.decodeJpg(File(cropped.path).readAsBytesSync());

    final thumbnail = ImageCompress.copyResize(toResize, width: 500);

    File(profilePicPath).writeAsBytesSync(ImageCompress.encodeJpg(thumbnail));

    _uploadProfilePic(profilePicPath);
    notifyListeners();
  }

  _uploadProfilePic(String filePath) async {
    logEvent("Profile", {"type": "displayImage"});
    File file = File(filePath);
    await _firebaseStorageService
        .getProfilePicLocationReference(myUID)
        .putFile(file)
        .whenComplete(() async {
      downloadURL = await _firebaseStorageService
          .getProfilePicLocationReference(myUID)
          .getDownloadURL();
      _firestoreService.saveUserInfo(myUID, {"displayImageURL": downloadURL});
      uploadingProfilePic = false;
      notifyListeners();
    });
  }
}
