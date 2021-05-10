import 'package:flutter/material.dart';
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
      child: Column(children: [
        AspectRatio(
          aspectRatio: 1,
          child: Material(
              color: Colors.black12,
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              )),
        ),
        SizedBox(height: 8),
        Text(
          widget.yourName,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 2),
        Text(
          'Vibing',
          style: TextStyle(color: Colors.grey),
        ),
      ]),
    );
  }
}
