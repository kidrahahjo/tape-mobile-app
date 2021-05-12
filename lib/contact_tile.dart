import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:wavemobileapp/permissions.dart';
import 'chatpage.dart';

class ContactTile extends StatefulWidget {
  final String myUID, yourUID, yourName;
  ContactTile({
    this.myUID,
    this.yourUID,
    this.yourName,
  });
  @override
  _ContactTileState createState() => _ContactTileState();
}

class _ContactTileState extends State<ContactTile> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () async {
          bool micPermissionGranted = await getMicrophonePermission();
          bool storagePermissionGranted = await getStoragePermission();
          if (micPermissionGranted && storagePermissionGranted) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ChatPage(
                        widget.myUID, widget.yourUID, widget.yourName)));
          } else {
            String message;
            if (micPermissionGranted) {
              message = "storage permission";
            } else if (storagePermissionGranted) {
              message = "microphone permission";
            } else {
              message = "microphone and storage permissions";
            }
            final ScaffoldMessengerState scaffoldMessenger =
                ScaffoldMessenger.of(context);
            scaffoldMessenger.showSnackBar(
                SnackBar(content: Text("Please grant $message.")));
          }
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
            widget.yourName,
            style: TextStyle(),
          ),
          subtitle: Text('Vibing'),
        ));
  }
}
