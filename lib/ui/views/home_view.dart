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
          onModelReady: (viewModel) => viewModel.initialise(),
          builder: (context, model, child) {
            return Scaffold(
              floatingActionButton: ContactsButton(),
              body: RefreshIndicator(
                onRefresh: () async {
                  model.refreshPage();
                  return;
                },
                child: CustomScrollView(
                  physics: BouncingScrollPhysics(),
                  slivers: <Widget>[
                    CustomSliverAppBar(),
                    SliverToBoxAdapter(
                        child: Divider(
                      height: 1,
                    )),
                    AllChatsView(),
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
      leading: GestureDetector(
        onLongPressStart: (details) async {
          //SECRET LOGOUT BUTTON FOR TESTING!!!
          viewModel.signOut();
        },
        child: IconButton(
          onPressed: null,
          icon: Icon(
            PhosphorIcons.eject,
            color: Colors.transparent,
          ),
        ),
      ),
      elevation: 1,
      expandedHeight: 120,
      pinned: true,
      stretch: true,
      actions: <Widget>[
        SizedBox(width: 8),
        GestureDetector(
          onTap: viewModel.goToProfileView,
          child: CircleAvatar(
            backgroundImage: viewModel.myProfilePic != null
                ? NetworkImage(viewModel.myProfilePic)
                : null,
            radius: 20,
            child: viewModel.myProfilePic == null
                ? Text(
                    viewModel.myDisplayName != null
                        ? viewModel.myDisplayName[0]
                        : "",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
        SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Chats',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        titlePadding: EdgeInsets.all(16),
      ),
    );
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
              indent: 72,
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
    return GestureDetector(
        onTap: () async {
          viewModel.goToContactScreen(yourUID);
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage:
                yourProfilePic != null ? NetworkImage(yourProfilePic) : null,
            radius: 24,
            child: yourProfilePic == null
                ? Text(
                    '${yourName[0]}'.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          title: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  viewModel.getUserName(yourUID),
                  style: TextStyle(),
                ),
                viewModel.getUserOnlineState(yourUID)
                    ? Icon(
                        PhosphorIcons.circleFill,
                        color: Colors.green,
                        size: 12,
                      )
                    : SizedBox(),
              ]),
          subtitle: viewModel.isRecording(yourUID)
              ? Text(
                  "Recording...",
                  style: TextStyle(
                      color: Theme.of(context).accentColor,
                      fontWeight: FontWeight.bold),
                )
              : viewModel.getSubtitle(yourUID, context),
        ));
  }
}

class ContactsButton extends ViewModelWidget<HomeViewModel> {
  ContactsButton() : super(reactive: true);

  @override
  Widget build(BuildContext context, HomeViewModel viewModel) {
    return FloatingActionButton(
      child: Icon(PhosphorIcons.plus),
      onPressed: () async {
        bool contactPermissionGranted = await getContactPermission();
        if (contactPermissionGranted) {
          final myModel = Provider.of<HomeViewModel>(context, listen: false);
          showModalBottomSheet<void>(
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              context: context,
              enableDrag: true,
              builder: (BuildContext context) {
                return ListenableProvider.value(
                  value: myModel,
                  child: ContactModalSheet(),
                );
              });
        } else {
          final ScaffoldMessengerState scaffoldMessenger =
              ScaffoldMessenger.of(context);
          scaffoldMessenger.showSnackBar(
              SnackBar(content: Text("Please grant contact permission.")));
        }
      },
    );
  }
}

class ContactModalSheet extends ViewModelWidget<HomeViewModel> {
  @override
  Widget build(BuildContext context, HomeViewModel viewModel) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 480,
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              "Contacts",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            actions: [
              viewModel.isFetchingContacts
                  ? CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ))
                  : TextButton(
                      onPressed: () {
                        viewModel.refreshContacts();
                      },
                      child: Text("Refresh",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          )),
                    ),
              SizedBox(
                width: 8,
              )
            ],
          ),
          body: ContactsList(),
        ),
      ),
    );
  }
}

class ContactsList extends ViewModelWidget<HomeViewModel> {
  @override
  Widget build(BuildContext context, HomeViewModel viewModel) {
    return ListView.builder(
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
                PhosphorIcons.user,
              ),
            ),
            title: Text(viewModel.getUserName(uid)),
            subtitle: Text(viewModel.getPhoneNumber(uid)),
          ),
          Divider(
            height: 1,
            indent: 72,
            endIndent: 16,
          ),
        ]);
      },
    );
  }
}
