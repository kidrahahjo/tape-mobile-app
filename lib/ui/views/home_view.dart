import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:stacked/stacked.dart';
import 'package:wavemobileapp/permissions.dart';
import 'package:wavemobileapp/viewmodel/home_view_model.dart';

class HomeView extends StatelessWidget {
  final String userUID;
  final String phoneNumber;

  HomeView(this.userUID, this.phoneNumber);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>.nonReactive(
      viewModelBuilder: () => HomeViewModel(userUID, phoneNumber),
      builder: (context, model, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).primaryColor,
          floatingActionButton: ContactsButton(),
          body: CustomScrollView(
            slivers: <Widget>[
              CustomSliverAppBar(),
              SliverToBoxAdapter(
                  child: Divider(
                height: 1,
              )),
              AllChatsView(),
            ],
          ),
        );
      },
    );
  }
}

class CustomSliverAppBar extends ViewModelWidget<HomeViewModel> {
  CustomSliverAppBar() : super(reactive: false);

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
            // color: Colors.transparent,
          ),
        ),
      ),
      elevation: 1,
      expandedHeight: 120,
      pinned: true,
      stretch: true,
      backgroundColor: Theme.of(context).primaryColor,
      // actions: <Widget>[
      // StatusChip(),
      // SizedBox(width: 16),
      // ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'shouts',
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
          var data = viewModel.chatsList.elementAt(index);
          return Column(children: [
            ContactTile(
              data['yourUID'],
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

class ContactTile extends ViewModelWidget<HomeViewModel> {
  final String yourUID;

  ContactTile(this.yourUID) : super(reactive: true);

  @override
  Widget build(BuildContext context, HomeViewModel viewModel) {
    return GestureDetector(
        onTap: () async {
          viewModel.goToContactScreen(yourUID);
        },
        child: ListTile(
          trailing: Icon(PhosphorIcons.megaphoneLight),
          leading: CircleAvatar(
            child: Icon(
              PhosphorIcons.user,
              color: Colors.white,
            ),
            backgroundColor: Colors.white12,
          ),
          title: Text(
            viewModel.userUIDNameMapping[yourUID],
            style: TextStyle(),
          ),
          subtitle: Text('Vibing'),
        ));
  }
}

class ContactsButton extends ViewModelWidget<HomeViewModel> {
  ContactsButton() : super(reactive: true);

  @override
  Widget build(BuildContext context, HomeViewModel viewModel) {
    return FloatingActionButton(
      elevation: 0,
      child: Icon(PhosphorIcons.plusBold),
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
                return ListenableProvider.value(value: myModel, child: ContactModalSheet(),);
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
        height: 640,
        child: Scaffold(
          appBar: AppBar(
            elevation: 1,
            automaticallyImplyLeading: false,
            title: Text(
              'New Shout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () {
                  viewModel.refreshContacts();
                },
                child: Center(
                  child: viewModel.isFetchingContacts
                      ? CircularProgressIndicator()
                      : Text("Refresh",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          )),
                ),
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
        var data = viewModel.contactsMap.elementAt(index);
        String phone = data['yourPhoneNumber'];
        String displayName = data['yourName'];
        String uid = data['yourUID'];
        return Column(children: [
          ListTile(
            onTap: () {
              viewModel.goToContactScreen(uid);
            },
            leading: CircleAvatar(
              backgroundColor: Colors.white12,
              child: Icon(
                PhosphorIcons.user,
                color: Colors.white,
              ),
            ),
            title: Text(displayName),
            subtitle: Text(phone),
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
