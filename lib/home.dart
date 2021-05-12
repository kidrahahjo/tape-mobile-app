import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
        floatingActionButton: FloatingActionButton(
          elevation: 0,
          child: Icon(PhosphorIcons.plusBold),
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
        ),
        backgroundColor: Theme.of(context).primaryColor,
        body: CustomScrollView(
          slivers: <Widget>[
            sliverAppBar(),
            SliverToBoxAdapter(
                child: Divider(
              height: 1,
            )),
            homeView(),
          ],
        ));
  }

  Widget sliverAppBar() {
    return SliverAppBar(
      elevation: 1,
      expandedHeight: 120,
      pinned: true,
      stretch: true,
      backgroundColor: Theme.of(context).primaryColor,
      actions: <Widget>[
        GestureDetector(
          onTap: () {
            showDialog(
                context: context,
                builder: (_) => SimpleDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TextField(
                            decoration:
                                InputDecoration(hintText: 'What\'s happening?'),
                          ),
                        ),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.white10,
                            child: Icon(PhosphorIcons.fireFill,
                                color: Theme.of(context).accentColor),
                          ),
                          title: Text('Watching Game of Thrones'),
                        ),
                        ListTile(
                          selected: true,
                          leading: CircleAvatar(
                            backgroundColor: Colors.white10,
                            child: Icon(PhosphorIcons.fireFill,
                                color: Theme.of(context).accentColor),
                          ),
                          title: Text('I made Coffee :3'),
                        ),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.white10,
                            child: Icon(PhosphorIcons.fireFill,
                                color: Theme.of(context).accentColor),
                          ),
                          title: Text('Snacc Time'),
                        ),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.white10,
                            child: Icon(PhosphorIcons.fireFill,
                                color: Theme.of(context).accentColor),
                          ),
                          title: Text('Comfortably Numb - Gilmour OP'),
                        ),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.white10,
                            child: Icon(PhosphorIcons.fireFill,
                                color: Theme.of(context).accentColor),
                          ),
                          title: Text('Ded in Bed.'),
                        ),
                      ],
                    ),
                barrierDismissible: true);
          },
          child: Chip(
            avatar: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Icon(PhosphorIcons.fireFill,
                  color: Theme.of(context).accentColor),
            ),
            label: Text('What\'s happening?'),
            elevation: 0,
            labelStyle: TextStyle(),
          ),
        ),
        SizedBox(width: 16),
      ],
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
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          var data = chatQueue.elementAt(index);
          return Column(children: [
            ContactTile(
              myUID: widget.user.uid,
              yourUID: data['yourUID'],
              yourName: data['yourName'],
            ),
            Divider(
              height: 1,
              indent: 72,
              endIndent: 16,
            ),
          ]);
        },
        childCount: chatQueue.length,
      ),
    );
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
                ),
                body: ContactListWrapper(widget.user.uid),
              ),
            ),
          );
        });
  }
}
