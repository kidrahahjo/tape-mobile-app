import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:stacked/stacked.dart';
import 'package:tapemobileapp/viewmodel/profile_view_model.dart';

class ProfileView extends StatelessWidget {
  final String downloadURL;
  final String displayName;

  ProfileView(this.downloadURL, this.displayName);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ProfileViewModel>.reactive(
        viewModelBuilder: () => ProfileViewModel(downloadURL),
        builder: (context, model, child) {
          return Scaffold(
            appBar: AppBar(
              leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(PhosphorIcons.caretLeft)),
              title: Text('Profile Picture'),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                model.getImage(context);
              },
              child: Icon(PhosphorIcons.userCirclePlus),
            ),
            body: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: CircleAvatar(
                      backgroundImage: model.downloadURL != null
                          ? NetworkImage(model.downloadURL)
                          : null,
                      radius: 64,
                      child: model.uploadingProfilePic
                          ? Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : model.downloadURL == null
                              ? Text(
                                  displayName != null
                                      ? displayName[0]
                                      : "Profile Pic",
                                  style: TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
