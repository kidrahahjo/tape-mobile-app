import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:stacked/stacked.dart';
import 'package:tapemobileapp/viewmodel/chat_view_model.dart';

import 'package:flutter_svg/flutter_svg.dart';

class ChatPageView extends StatelessWidget {
  final String yourUID;
  final String yourName;

  ChatPageView(this.yourUID, this.yourName);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ChatViewModel>.reactive(
      viewModelBuilder: () => ChatViewModel(yourUID, yourName),
      builder: (context, model, child) {
        return Scaffold(
          body: Column(children: [
            Expanded(
              child: CustomScrollView(
                controller: model.scrollController,
                physics: BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 360,
                    actions: [PokeButton()],
                    leading: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(PhosphorIcons.caretLeft)),
                    pinned: true,
                    stretch: true,
                    flexibleSpace: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: FlexibleSpaceBar(
                        collapseMode: CollapseMode.pin,
                        stretchModes: [StretchMode.fadeTitle, StretchMode.zoomBackground],
                        centerTitle: true,
                        background: Padding(
                          padding: EdgeInsets.fromLTRB(0, 64, 0, 64),
                          child: ProfilePic(yourName),
                        ),
                        title: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                                children: [
                                  Icon(
                                    PhosphorIcons.circleFill,
                                    color: Colors.transparent,
                                    size: 12,
                                  ),
                                  Text(
                                    yourName,
                                    style: TextStyle(fontWeight: FontWeight.bold)
                                  ),
                                  Icon(
                                    PhosphorIcons.circleFill,
                                    color: model.youAreOnline ? Colors.green : Colors.transparent,
                                    size: 12,
                                  )
                                ],
                        ),
                      ),
                    ),
                  ),
                  TapeArea(),
                ],
              ),
            ),
            Footer(),
          ]),
        );
      },
    );
  }
}

class ProfilePic extends ViewModelWidget<ChatViewModel> {
  final String yourName;
  ProfilePic(this.yourName);
  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return CircleAvatar(
      child: viewModel.profilePic == null
          ? Text(
              '${this.yourName[0]}'.toUpperCase(),
              style: TextStyle(
                fontSize: 100,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
      backgroundImage: viewModel.profilePic == null
          ? null
          : NetworkImage(viewModel.profilePic),
    );
  }
}

class Footer extends ViewModelWidget<ChatViewModel> {
  Footer() : super(reactive: true);
  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return AnimatedContainer(
      decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          )),
      height: viewModel.drawerHeight,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: AnimatedCrossFade(
                    crossFadeState: viewModel.drawerOpen
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: Duration(milliseconds: 300),
                    sizeCurve: Curves.easeInCubic,
                    firstChild: Center(
                      child: Text('Hold to talk',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    secondChild: Center(
                        child: Text(
                      "Recording... ${viewModel.recordingTimer}",
                      style: TextStyle(
                          color: Theme.of(context).accentColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    )),
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [RecordButton()],
                ),
              ]),
        ),
      ),
    );
  }
}

class TapeArea extends ViewModelWidget<ChatViewModel> {
  TapeArea() : super(reactive: true);

  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            return Column(
              children: [
                SizedBox(height: viewModel.getGap(index)),
                viewModel.showTape(index, context),
              ],
            );
          },
          childCount: viewModel.allTapes.length,
        ),
      ),
    );
  }
}

class PokeButton extends ViewModelWidget<ChatViewModel> {
  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return SizedBox(
        width: 64,
        height: 64,
        child: RawMaterialButton(
          onPressed: () {
            viewModel.poke();
          },
          shape: CircleBorder(),
          child: Icon(
            PhosphorIcons.handWaving,
          ),
        ));
  }
}

class RecordButton extends ViewModelWidget<ChatViewModel> {
  RecordButton() : super(reactive: true);
  final String tapeIcon = 'assets/icon/tape_icon.svg';

  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return GestureDetector(
        onTapDown: (details) {
          viewModel.startRecording();
        },
        onTapUp: (details) {
          viewModel.stopRecording();
        },
        onVerticalDragEnd: (value) {
          viewModel.stopRecording();
        },
        onHorizontalDragEnd: (value) {
          viewModel.stopRecording();
        },
        child: SizedBox(
          height: 64,
          width: 64,
          child: RawMaterialButton(
            shape: CircleBorder(),
            fillColor: Theme.of(context).accentColor,
            onPressed: null,
            child: SvgPicture.asset(
              tapeIcon,
              semanticsLabel: 'Tape Logo',
              height: 48,
              width: 48,
            ),
          ),
        ));
  }
}
