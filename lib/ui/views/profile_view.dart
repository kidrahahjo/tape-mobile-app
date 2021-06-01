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
                centerTitle: false,
                title: Text(
                    model.titleName == null ? displayName : model.titleName),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              backgroundImage: model.downloadURL != null
                                  ? NetworkImage(model.downloadURL)
                                  : null,
                              radius: 80,
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
                            FloatingActionButton(
                              mini: true,
                              onPressed: () {
                                model.getImage(context);
                              },
                              child: Icon(PhosphorIcons.userCirclePlusFill),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        TextFormField(
                          onChanged: (name) => {model.updateTitle(name)},
                          onFieldSubmitted: (newName) =>
                              {model.updateDisplayName(newName)},
                          style: TextStyle(
                            fontSize: 24.0,
                          ),
                          maxLines: 1,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            hintText: "Your Name",
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            fillColor: Theme.of(context).primaryColorDark,
                            filled: true,
                            suffixIcon: Icon(
                              PhosphorIcons.pencilFill,
                              color: Theme.of(context).accentColor,
                            ),
                            border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          initialValue: displayName,
                        ),
                      ],
                    ),
                  ],
                ),
              ));
        });
  }
}
