import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:stacked/stacked.dart';
import 'package:tapemobileapp/app/permissions.dart';
import 'package:tapemobileapp/viewmodel/home_view_model.dart';

class HomeView extends StatelessWidget {
  final String userUID;
  final String phoneNumber;

  HomeView(this.userUID, this.phoneNumber);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          SystemNavigator.pop();
          return true;
        },
        child: ViewModelBuilder<HomeViewModel>.reactive(
          viewModelBuilder: () => HomeViewModel(userUID, phoneNumber),
          fireOnModelReadyOnce: false,
          builder: (context, model, child) {
            return Scaffold(
              resizeToAvoidBottomInset: true,
              body: RefreshIndicator(
                color: Theme.of(context).accentColor,
                onRefresh: () async {
                  model.refreshPage();
                  return;
                },
                child: CustomScrollView(
                  physics: BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  slivers: <Widget>[
                    CustomSliverAppBar(),
                    SliverToBoxAdapter(
                        child: Divider(
                      endIndent: 16,
                      indent: 16,
                      height: 1,
                    )),
                    model.isLoading
                        ? SliverFillRemaining(
                            child: Center(
                              child:
                                  Text("Hang in there! Getting your Tapes..."),
                            ),
                          )
                        : model.chatsList.isEmpty
                            ? SliverFillRemaining(
                                child: Center(
                                    child: Text(
                                        "It's feels lonely here. Send a Tape!")),
                              )
                            : AllChatsView(),
                  ],
                ),
              ),
            );
          },
        ));
  }
}

class CustomSliverAppBar extends ViewModelWidget<HomeViewModel> {
  CustomSliverAppBar() : super(reactive: true);

  @override
  Widget build(BuildContext context, HomeViewModel viewModel) {
    return SliverAppBar(
        elevation: 1,
        pinned: true,
        expandedHeight: 144,
        stretch: true,
        actions: <Widget>[
          TextButton(
              onPressed: () async {
                bool contactPermissionGranted = await getContactPermission();
                if (contactPermissionGranted) {
                  final myModel =
                      Provider.of<HomeViewModel>(context, listen: false);

                  Navigator.of(context).push(new MaterialPageRoute<Null>(
                      builder: (BuildContext context) {
                        return ListenableProvider.value(
                          value: myModel,
                          child: ContactModalSheet(),
                        );
                      },
                      fullscreenDialog: true));
                } else {
                  final ScaffoldMessengerState scaffoldMessenger =
                      ScaffoldMessenger.of(context);
                  scaffoldMessenger.showSnackBar(SnackBar(
                      content: Text("Please grant contact permission.")));
                }
              },
              child: Text(
                "New Tape",
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).accentColor,
                ),
              )),
          SizedBox(width: 8),
          GestureDetector(
            onTap: viewModel.goToProfileView,
            child: Center(
              child: CircleAvatar(
                backgroundImage: viewModel.myProfilePic != null
                    ? ResizeImage(NetworkImage(viewModel.myProfilePic),
                        height: 200, width: 200)
                    : null,
                radius: 20,
                child: viewModel.myProfilePic == null
                    ? Text(
                        viewModel.myDisplayName != null
                            ? viewModel.myDisplayName[0]
                            : "",
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(width: 16),
        ],
        flexibleSpace: FlexibleSpaceBar(
          titlePadding: EdgeInsets.only(bottom: 10, left: 16),
          title: Text(
            'Tapes',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
        ));
  }
}

class AllChatsView extends ViewModelWidget<HomeViewModel> {
  AllChatsView() : super(reactive: true);

  @override
  Widget build(BuildContext context, HomeViewModel viewModel) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          String uid = viewModel.chatsList.elementAt(index);
          return Column(children: [
            ChatTile(
              uid,
            ),
            Divider(
              height: 1,
              indent: 88,
              endIndent: 16,
            ),
          ]);
        },
        childCount: viewModel.chatsList.length,
      ),
    );
  }
}

class ChatTile extends ViewModelWidget<HomeViewModel> {
  final String yourUID;

  ChatTile(this.yourUID) : super(reactive: true);

  @override
  Widget build(BuildContext context, HomeViewModel viewModel) {
    final String yourName = viewModel.getUserName(yourUID);
    final String yourProfilePic = viewModel.getProfilePic(yourUID);
    return ListTile(
      onTap: () async {
        viewModel.goToContactScreen(yourUID);
      },
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      trailing: viewModel.showPoke(yourUID)
          ? Icon(
              PhosphorIcons.handWavingFill,
              color: Theme.of(context).accentColor,
              size: 28,
            )
          : Text(
              viewModel.getUserMood(yourUID) == null
                  ? ""
                  : viewModel.getUserMood(yourUID),
              style: TextStyle(fontSize: 28),
            ),
      leading: CircleAvatar(
        backgroundImage: yourProfilePic != null
            ? ResizeImage(NetworkImage(yourProfilePic), width: 200, height: 200)
            : null,
        radius: 28,
        child: yourProfilePic == null
            ? Text(
                '${yourName[0]}'.toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                ),
              )
            : null,
      ),
      title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            LimitedBox(
              maxWidth: MediaQuery.of(context).size.width * 0.5,
              child: Text(
                viewModel.getUserName(yourUID),
                style: TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8),
            viewModel.getUserOnlineState(yourUID)
                ? Icon(
                    PhosphorIcons.circleFill,
                    color: Colors.green,
                    size: 8,
                  )
                : Icon(
                    PhosphorIcons.circleFill,
                    color: Colors.transparent,
                    size: 8,
                  ),
          ]),
      subtitle: viewModel.isRecording(yourUID)
          ? Text(
              "Recording...",
              style: TextStyle(
                  color: Theme.of(context).accentColor,
                  fontWeight: FontWeight.bold),
            )
          : viewModel.getSubtitle(yourUID, context),
    );
  }
}

class ContactModalSheet extends ViewModelWidget<HomeViewModel> {
  @override
  Widget build(BuildContext context, HomeViewModel viewModel) {
    return RefreshIndicator(
      color: Theme.of(context).accentColor,
      onRefresh: () async {
        viewModel.refreshContacts();
        return;
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Text("Send a Tape..."),
          actions: [
            viewModel.isFetchingContacts
                ? Center(
                    child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.transparent,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        )),
                  )
                : TextButton(
                    onPressed: () {
                      viewModel.refreshContacts();
                    },
                    child: Text("Refresh",
                        style: TextStyle(
                          color: Theme.of(context).accentColor,
                          fontSize: 16,
                        )),
                  ),
            SizedBox(
              width: 16,
            )
          ],
        ),
        body: viewModel.contactsMap.length > 0
            ? ContactsList()
            : Center(
                child: Text(viewModel.isFetchingContacts
                    ? "Looking for your friends on Tape, just a sec!"
                    : "No contacts on Tape, yet."),
              ),
      ),
    );
  }
}

class ContactsList extends ViewModelWidget<HomeViewModel> {
  @override
  Widget build(BuildContext context, HomeViewModel viewModel) {
    return ListView.builder(
      physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemCount: viewModel.contactsMap.length,
      itemBuilder: (BuildContext context, int index) {
        String uid = viewModel.contactsMap.elementAt(index);
        return Column(children: [
          ListTile(
            onTap: () {
              viewModel.goToContactScreen(uid);
              Navigator.pop(context);
            },
            leading: CircleAvatar(
              child: Icon(
                PhosphorIcons.userFill,
              ),
            ),
            title: Text(viewModel.getUserName(uid)),
            subtitle: Text(viewModel.getPhoneNumber(uid)),
          ),
          Divider(
            indent: 72,
            endIndent: 16,
          ),
        ]);
      },
    );
  }
}
