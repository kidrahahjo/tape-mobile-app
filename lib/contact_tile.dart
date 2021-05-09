import 'package:flutter/material.dart';
import 'chatpage.dart';

class ContactTile extends StatefulWidget {
  ContactTile({
    this.partnerId,
    this.userId,
    this.userName,
  });
  final String userId, partnerId, userName;
  @override
  _ContactTileState createState() => _ContactTileState();
}

class _ContactTileState extends State<ContactTile> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChatPage(
                    widget.userId, widget.partnerId, widget.userName)));
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
          widget.userName,
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
