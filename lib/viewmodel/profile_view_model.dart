import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:tapemobileapp/services/authentication_service.dart';
import 'package:tapemobileapp/services/firebase_storage_service.dart';
import 'package:tapemobileapp/services/firestore_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tapemobileapp/viewmodel/base_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop/crop.dart';
import 'package:image/image.dart' as ImageCompress;
import '../app/locator.dart';

class ProfileViewModel extends BaseModel {
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final FirestoreService _firestoreService = locator<FirestoreService>();
  final FirebaseStorageService _firebaseStorageService =
      locator<FirebaseStorageService>();

  File selectedPic;
  String downloadURL;
  bool uploadingProfilePic = false;

  final picker = ImagePicker();
  final cropController = new CropController(
    aspectRatio: 1,
  );

  ProfileViewModel(String downloadURL) {
    this.downloadURL = downloadURL;
  }

  String get myUID => _authenticationService.currentUser.uid;

  Future getImage(BuildContext context) async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      selectedPic = File(pickedFile.path);
      showCropView(context);
    } else {
      print('No image selected.');
    }
  }

  showCropView(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Crop Image'),
            centerTitle: true,
            actions: <Widget>[
              TextButton(
                child: Text(
                  "Done",
                  style: TextStyle(
                      color: Theme.of(context).accentColor, fontSize: 16),
                ),
                onPressed: () {
                  cropImage(context);
                  Navigator.pop(context);
                },
              )
            ],
          ),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Container(
                    color: Colors.black,
                    padding: EdgeInsets.all(8),
                    child: Crop(
                      onChanged: (decomposition) {
                        print(
                            "Scale : ${decomposition.scale}, Rotation: ${decomposition.rotation}, translation: ${decomposition.translation}");
                      },
                      controller: cropController,
                      shape: BoxShape.rectangle,
                      child: Image.file(
                        selectedPic,
                        fit: BoxFit.cover,
                      ),
                      /* It's very important to set `fit: BoxFit.cover`.
                     Do NOT remove this line.*/
                      helper: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    SizedBox(width: 8),
                    TextButton(
                      child: Text(
                        'Reset',
                        style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).iconTheme.color),
                      ),
                      onPressed: () {
                        cropController.rotation = 0;
                        cropController.scale = 1;
                        cropController.offset = Offset.zero;
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future cropImage(BuildContext context) async {
    uploadingProfilePic = true;
    notifyListeners();
    var tempDir = await getTemporaryDirectory();
    String profilePicPath = '${tempDir.path}/$myUID.jpg';
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final cropped = await cropController.crop(pixelRatio: pixelRatio);

    var byteData = await cropped.toByteData(format: ui.ImageByteFormat.png);
    File(profilePicPath).writeAsBytesSync(byteData.buffer.asUint8List());

    final image =
        ImageCompress.decodeImage(File(profilePicPath).readAsBytesSync());

    final thumbnail = ImageCompress.copyResize(image, width: 500);

    File(profilePicPath).writeAsBytesSync(ImageCompress.encodeJpg(thumbnail));

    _uploadProfilePic(profilePicPath);
    notifyListeners();
  }

  _uploadProfilePic(String filePath) async {
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
