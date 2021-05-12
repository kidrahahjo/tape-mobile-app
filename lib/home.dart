import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wavemobileapp/permissions.dart';
import 'contact_tile.dart';
import 'contacts.dart';
import 'authenticate.dart';
import 'database.dart';

class Home extends StatefulWidget {
  final User user;

  Home(this.user);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool showLoading = false;
  Stream<QuerySnapshot> allChatsStream;
  StreamSubscription<QuerySnapshot> allChatStreamSubscription;
  Queue<Map<String, String>> chatQueue = new Queue();
  Map<String, String> userUIDNameMapping = {};
  Timer timer;

  @override
  void initState() {
    allChatsStream = DatabaseMethods().getTotalChats(widget.user.uid);
    allChatStreamSubscription = allChatsStream.listen((event) async {
      Queue<Map<String, String>> listenChat = new Queue();
      for (QueryDocumentSnapshot element in event.docs) {
        listenChat.add({
          'yourUID': element.id,
          'yourName': userUIDNameMapping.containsKey(element.id)
              ? userUIDNameMapping[element.id]
              : await DatabaseMethods()
                  .fetchUserDetailFromDatabase(element.id)
                  .then((value) {
                  return value.get('displayName');
                }),
        });
      }
      if (listenChat.length != 0) {
        if (this.mounted) {
          setState(() {
            this.chatQueue = listenChat;
          });
        }
      }
    });
    super.initState();
  }

  @override
  void deactivate() {
    allChatStreamSubscription?.cancel();
    super.deactivate();
  }

  @override
  void dispose() {
    allChatStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: <Widget>[
            sliverAppBar(),
            homeView(),
          ],
        ));
  }

  Widget sliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.white,
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.emoji_emotions_outlined),
          color: Colors.amber,
          onPressed: () {},
        ),
        newShoutButton(context),
        SizedBox(
          width: 8,
        )
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Shouts',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        titlePadding: EdgeInsets.all(16),
      ),
    );
  }

  Widget newShoutButton(context) {
    return TextButton(
      style: TextButton.styleFrom(
          primary: Colors.amber,
          textStyle: TextStyle(fontSize: 16),
          shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(32))),
      child: Text(
        'New Shout',
      ),
      onPressed: () async {
        bool contactPermissionGranted = await getContactPermission();
        if (contactPermissionGranted) {
          getUsersFromContacts(context);
        } else {
          final ScaffoldMessengerState scaffoldMessenger =
              ScaffoldMessenger.of(context);
          scaffoldMessenger.showSnackBar(
              SnackBar(content: Text("Please grant contact permission.")));
        }
      },
    );
  }

  Widget homeView() {
    return SliverPadding(
        padding: EdgeInsets.all(16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            childAspectRatio: 2 / 3,
          ),
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              var data = chatQueue.elementAt(index);
              return ContactTile(
                myUID: widget.user.uid,
                yourUID: data['yourUID'],
                yourName: data['yourName'],
              );
            },
            childCount: chatQueue.length,
          ),
        ));
  }

  getUsersFromContacts(context) {
    showModalBottomSheet<void>(
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        context: context,
        enableDrag: true,
        builder: (BuildContext context) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 640,
              child: Scaffold(
                backgroundColor: Colors.white,
                appBar: AppBar(
                  elevation: 1,
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.white,
                  title: Text(
                    'New Shout',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                body: ContactListWrapper(widget.user.uid),
              ),
            ),
          );
        });
  }
}
