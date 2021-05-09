import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bigo/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class CallPage extends StatefulWidget {
  /// non-modifiable channel name of the page

  const CallPage({
    Key key,
  }) : super(key: key);

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  @override
  void dispose() {
    print('logout');
    final provider = context.read<LiveStreamProvider>();
    provider.users.clear();
    provider.logout();
    provider.leaveChannel();
    provider.engine.leaveChannel();
    provider.engine.destroy();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final provider = context.read<LiveStreamProvider>();
    provider
      ..initialize()
      ..createClient();
  }

  List<Widget> _getRenderViews() {
    final provider = context.read<LiveStreamProvider>();
    final List<StatefulWidget> list = [];
    if (provider.role == ClientRole.Broadcaster) {
      list.add(RtcLocalView.SurfaceView());
    }
    provider.users
        .forEach((int uid) => list.add(RtcRemoteView.SurfaceView(uid: uid)));
    return list;
  }

  /// Video view wrapper
  Widget _videoView(view) {
    return Expanded(child: Container(child: view));
  }

  /// Video view row wrapper
  Widget _expandedVideoRow(List<Widget> views) {
    final wrappedViews = views.map<Widget>(_videoView).toList();
    return Expanded(
      child: Row(
        children: wrappedViews,
      ),
    );
  }

  /// Video layout wrapper
  Widget _viewRows() {
    final views = _getRenderViews();
    switch (views.length) {
      case 1:
        return Container(
            child: Column(
          children: <Widget>[_videoView(views[0])],
        ));
      case 2:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow([views[0]]),
            _expandedVideoRow([views[1]])
          ],
        ));
      case 3:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow(views.sublist(0, 2)),
            _expandedVideoRow(views.sublist(2, 3)),
          ],
        ));
      case 4:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow(views.sublist(0, 2)),
            _expandedVideoRow(views.sublist(2, 4)),
          ],
        ));
      default:
    }
    return Container();
  }

  /// Toolbar layout
  Widget _toolbar() {
    final provider = context.read<LiveStreamProvider>();
    if (provider.role == ClientRole.Audience) return Container();
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ClipOval(
          child: Material(
            color: Colors.black54,
            child: InkWell(
              child: SizedBox(
                height: 30,
                width: 30,
                child: Icon(
                  provider.muted ? Icons.mic_off : Icons.mic,
                  color: Colors.white,
                  size: 16.0,
                ),
              ),
              onTap: provider.onToggleMute,
            ),
          ),
        ),
        SizedBox(width: 10),
        ClipOval(
          child: Material(
            color: Colors.black54,
            child: InkWell(
              child: SizedBox(
                height: 30,
                width: 30,
                child: Icon(
                  Icons.switch_camera,
                  color: Colors.white,
                  size: 16.0,
                ),
              ),
              onTap: provider.onSwitchCamera,
            ),
          ),
        ),
        SizedBox(width: 10),
        ClipOval(
          child: Material(
            color: Colors.red,
            child: InkWell(
              child: SizedBox(
                height: 30,
                width: 30,
                child: Icon(
                  Icons.call_end,
                  color: Colors.white,
                  size: 16.0,
                ),
              ),
              onTap: () => _onCallEnd(context),
            ),
          ),
        ),
      ],
    );
  }

  void _onCallEnd(BuildContext context) async {
    final provider = context.read<LiveStreamProvider>();
    await provider.users.clear();
    provider.logout();
    provider.leaveChannel();
    await provider.engine.leaveChannel();
    await provider.engine.destroy();
    //Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    print('start build');
    return SafeArea(
      child: Scaffold(
        // resizeToAvoidBottomInset: false,
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: <Widget>[
                    _viewRows(),
                    _ChatLayout(),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      left: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black87,
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 8.0,
                        ),
                        child: SendChannelMessage(context: context),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _toolbar(),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SendChannelMessage extends StatelessWidget {
  const SendChannelMessage({
    Key key,
    @required this.context,
  }) : super(key: key);

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    print('start build 2');
    final chatProvider = context.watch<LiveStreamProvider>();
    if (!chatProvider.isLogin || !chatProvider.isInChannel) {
      return Container();
    }
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: chatProvider.channelMessageController,
            style: TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: 'message',
              hintStyle: TextStyle(color: Colors.white38),
              border: InputBorder.none,
            ),
          ),
        ),
        GestureDetector(
          onTap: chatProvider.toggleSendChannelMessage,
          child: SvgPicture.asset(
            'assets/icons/send.svg',
            width: 24,
            color: Colors.white,
          ),
        )
      ],
    );
  }
}

class _ChatLayout extends StatelessWidget {
  const _ChatLayout({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<LiveStreamProvider>();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.7,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: ListView.builder(
            reverse: true,
            itemCount: chatProvider.chat.length,
            itemBuilder: (BuildContext context, int index) {
              if (chatProvider.chat.isEmpty) {
                return null;
              }
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 3,
                  horizontal: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          chatProvider.chat[index],
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
