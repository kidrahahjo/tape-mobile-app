import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';

class StatusChip extends StatefulWidget {
  @override
  _StatusChipState createState() => _StatusChipState();
}

class _StatusChipState extends State<StatusChip> {
  List<String> statusList = [];
  String currentStatus = 'What\'s happening?';

  final statusTextController = TextEditingController();
  void initState() {
    statusTextController.addListener(() {
      statusTextController.text.trim() != ""
          ? setState(() {
              currentStatus = statusTextController.text.trim();
            })
          : statusList.isNotEmpty
              ? setState(() {
                  currentStatus = statusList.reversed.elementAt(0);
                })
              : setState(() {
                  currentStatus = "What\'s happening?";
                });
    });
  }

  @override
  void dispose() {
    statusTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showStatusOptions();
      },
      child: Chip(
        avatar: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: Icon(PhosphorIcons.fireFill,
              color: Theme.of(context).accentColor),
        ),
        label: Text(currentStatus),
        elevation: 0,
        labelStyle: TextStyle(),
      ),
    );
  }

  showStatusOptions() {
    showDialog(
            context: context,
            builder: (context) => SimpleDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        onSubmitted: (value) => Navigator.pop(context),
                        autofocus: true,
                        maxLength: 32,
                        controller: statusTextController,
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: Icon(PhosphorIcons.x),
                            onPressed: () {
                              statusTextController.clear();
                            },
                          ),
                          hintText: 'What\'s happening?',
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: statusList.reversed
                          .map((i) => ListTile(
                                trailing: IconButton(
                                  icon: Icon(PhosphorIcons.minus),
                                  onPressed: () {
                                    statusList.remove(i);
                                  },
                                ),
                                selected: i == statusTextController.text,
                                onTap: () {
                                  setState(() {
                                    statusTextController.text = i;
                                    // statusList.remove(i);
                                    // statusList.add(i);
                                  });
                                  Navigator.pop(context);
                                },
                                leading: CircleAvatar(
                                  backgroundColor: Colors.white10,
                                  child: Icon(PhosphorIcons.fireFill,
                                      color: Theme.of(context).accentColor),
                                ),
                                title: Text(i),
                              ))
                          .toList(),
                    )
                  ],
                ),
            barrierDismissible: true)
        .then((value) => updateStatus());
  }

  updateStatus() {
    if (!statusList.contains(statusTextController.text.trim()) &&
        statusTextController.text.trim() != "") {
      setState(() {
        statusList.add(statusTextController.text.trim());
        statusTextController.text = statusTextController.text.trim();
      });
    }
  }
}
