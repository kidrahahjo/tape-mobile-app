import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'chatpage.dart';

class ContactListWrapper extends StatefulWidget {
  final String myUID;

  ContactListWrapper(this.myUID);

  @override
  _ContactListWrapperState createState() => _ContactListWrapperState();
}

class _ContactListWrapperState extends State<ContactListWrapper> {
  bool showLoading = true;

  List<String> _presentNumbers = [];
  List<String> _presentNames = [];
  List<String> _presentUIDs = [];



  @override
  void initState() {
    super.initState();
    getContacts();
  }


  @override
  void deactivate() {
    super.deactivate();
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
      } catch (e) {
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
        ? Center(
            child: CircularProgressIndicator(
              valueColor: new AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          )
        : _presentNumbers?.length == 0
            ? Center(
                child: Text("No contacts on wave, yet!"),
              )
            : ContactList(widget.myUID, _presentNumbers, _presentNames, _presentUIDs);
  }
}

class ContactList extends StatefulWidget {
  String myUID;
  List<String> mobile;
  List<String> name;
  List<String> uIDs = [];

  ContactList(this.myUID, this.mobile, this.name, this.uIDs);

  @override
  _ContactListState createState() => _ContactListState();
}

class _ContactListState extends State<ContactList> {
  openUserChatScreen(userUID, userName, context) async {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => ChatPage(widget.myUID, userUID, userName)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.mobile?.length ?? 0,
      itemBuilder: (BuildContext context, int index) {
        String phone = widget.mobile?.elementAt(index);
        String displayName = widget.name?.elementAt(index);
        String uid = widget.uIDs?.elementAt(index);
        return ListTile(
          onTap: () {
            openUserChatScreen(uid, displayName, context);
          },
          leading: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
                color: Colors.amber, borderRadius: BorderRadius.circular(100)),
            child: Center(
              child: Icon(
                Icons.person,
                color: Colors.white,
              ),
            ),
          ),
          title: Text(displayName),
          subtitle: Text(phone),
        );
      },
    );
  }
}
