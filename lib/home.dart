import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:shared_preferences/shared_preferences.dart';
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
  Stream<QuerySnapshot> chatsStream;
  String _now;
  Timer timer;

  @override
  void initState() {
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) => getChats());
    super.initState();
  }

  checkForNewWaves() {
    setState(() {
      _now = DateTime.now().second.toString();
    });
  }

  getChats() async {
    chatsStream = await DatabaseMethods()
        .fetchTotalChats(widget.user.uid)
        .timeout(Duration(seconds: 5))
        .onError((error, stackTrace) {
      return null;
    });

    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<PermissionStatus> _getPermission() async {
    PermissionStatus permission = await Permission.contacts.status;
    if (!permission.isGranted) {
      await Permission.contacts.request();
    }
    permission = await Permission.contacts.status;
    return permission;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
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
                TextButton(
                  style: TextButton.styleFrom(
                      primary: Colors.amber,
                      textStyle: TextStyle(fontSize: 16),
                      shape: ContinuousRectangleBorder(
                          borderRadius: BorderRadius.circular(32))),
                  child: Text(
                    'New Shout',
                  ),
                  onPressed: () async {
                    final PermissionStatus permissionStatus =
                        await _getPermission();
                    if (permissionStatus == PermissionStatus.granted) {
                      createNewShout(context);
                    } else {
                      final ScaffoldMessengerState scaffoldMessenger =
                          ScaffoldMessenger.of(context);
                      scaffoldMessenger.showSnackBar(SnackBar(
                          content: Text("Please grant contact permission.")));
                    }
                  },
                ),
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
            ),
            SliverPadding(
              padding: EdgeInsets.all(16),
              sliver: StreamBuilder(
                  stream: chatsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      if (snapshot.data.docs.length == 0) {
                        return SliverToBoxAdapter(
                            child: Text("No shouts yet!"));
                      }
                      return SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          childAspectRatio: 2 / 3,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                            DocumentSnapshot ds = snapshot.data.docs[index];
                            String partnerId = ds.id;
                            String userName = ds.data()['userName'].toString();
                            return ContactTile(
                              userName: userName,
                              partnerId: partnerId,
                              userId: widget.user.uid,
                            );
                          },
                          childCount: snapshot.data.docs.length,
                        ),
                      );
                    } else {
                      return SliverFillRemaining(
                        child: Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: new AlwaysStoppedAnimation<Color>(
                                  Colors.amber),
                            ),
                          ),
                        ),
                      );
                    }
                  }),
            )
          ],
        ));
  }

  createNewShout(context) {
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
                body: ContactListWrapper(),
              ),
            ),
          );
        });
  }
}
