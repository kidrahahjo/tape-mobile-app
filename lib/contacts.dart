import 'package:contacts_service/contacts_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wavemobileapp/chatpage.dart';
import 'package:wavemobileapp/shared_preferences_helper.dart';

class ContactsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ContactsState();
  }
}

class NoContactsFound extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("No contacts on wave, yet!"),
    );
  }
}

class ContactsList extends StatefulWidget {
  List<String> mobile;
  List<String> name;
  List<String> UIDs = [];

  ContactsList(@required this.mobile, @required this.name, @required this.UIDs);

  @override
  State<StatefulWidget> createState() {
    return _ContactsListState(mobile, name, UIDs);
  }
}

class _ContactsListState extends State<ContactsList> {
  List<String> mobile;
  List<String> name;
  List<String> UIDs = [];

  _ContactsListState(
      @required this.mobile, @required this.name, @required this.UIDs);

  openUserChatScreen(userUID, userName, context) async {
    String myUID = await FirebaseAuth.instance.currentUser.uid;
    String myName = await FirebaseAuth.instance.currentUser.displayName;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChatPage(myUID, userUID, userName, myName)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: mobile?.length ?? 0,
      itemBuilder: (BuildContext context, int index) {
        String phone = mobile?.elementAt(index);
        String displayName = name?.elementAt(index);
        String uid = UIDs?.elementAt(index);
        return InkWell(
          onTap: () {
            openUserChatScreen(uid, displayName, context);
          },
          child: Container(
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.symmetric(horizontal: 10),
            padding: EdgeInsets.symmetric(horizontal: 25),
            decoration:
                BoxDecoration(border: Border(bottom: BorderSide(width: 1))),
            height: 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  displayName,
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 20),
                ),
                Text(
                  phone,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ContactsState extends State<ContactsPage> {
  bool showLoading = true;

  List<String> _presentNumbers = [];
  List<String> _presentNames = [];
  List<String> _presentUIDs = [];

  @override
  void initState() {
    super.initState();
    getContacts();
  }

  String fetchCorrectPhone(String phone) {
    phone = phone.replaceAll(" ", "");
    if (phone.startsWith('+91')) {
      return phone;
    } else if (phone.startsWith('+')) {
      return 'Null';
    } else {
      try {
        String num = '+91' + int.parse(phone).toString();
        if (num.length == 13) {
          return num;
        }
      } catch (e){
        return 'Null';
      }
    }
    return 'Null';
  }

  Future<void> getContacts() async {
    final Iterable<Contact> contacts = await ContactsService.getContacts();
    Set<String> phoneNumbers = <String>{};
    List<String> presentNumbers = [];
    List<String> presentNames = [];
    List<String> presentUIDs = [];

    CollectionReference collection =
        await FirebaseFirestore.instance.collection('users');
    for (Contact contact in contacts) {
      for (Item phone in contact.phones) {
        String mobile = fetchCorrectPhone(phone.value);
        if (mobile != 'Null') {
          phoneNumbers.add(mobile);
        }
      }
    }

    await collection.get().then((value) => {
          value.docs.forEach((element) {
            String num = element['phoneNumber'];
            if (phoneNumbers.contains(num)) {
              presentUIDs.add(element.id);
              presentNumbers.add(element['phoneNumber']);
              presentNames.add(element['displayName']);
            }
          })
        });
    setState(() {
      _presentNames = presentNames;
      _presentNumbers = presentNumbers;
      _presentUIDs = presentUIDs;
      showLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return showLoading
        ? Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: Text("Contacts"),
            ),
            body: _presentNumbers?.length == 0
                ? NoContactsFound()
                : ContactsList(_presentNumbers, _presentNames, _presentUIDs),
          );
  }
}
