import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bigo/provider.dart';
import 'package:provider/provider.dart';
import '../utils/settings.dart';

class CallPage extends StatefulWidget {
  /// non-modifiable channel name of the page
  final String channelName;
  final String nameLogin;
  final ClientRole role;
  const CallPage({Key key, this.channelName, this.role, this.nameLogin})
      : super(key: key);

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final _users = <int>[];

  bool muted = false;

  RtcEngine _engine;

  @override
  void dispose() {
    print('logout');
    _users.clear();
    context.read<ChatProvider>().logout();
    context.read<ChatProvider>().leaveChannel();
    _engine.leaveChannel();
    _engine.destroy();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initialize();
    context
        .read<ChatProvider>()
        .createClient(widget.nameLogin, widget.channelName);
  }

  Widget _buildSendChannelMessage() {
    final chatProvider = context.watch<ChatProvider>();
    if (!chatProvider.isLogin ||
        !chatProvider.isInChannel) {
      return Container();
    }
    return Row(children: <Widget>[
      Expanded(
          child: TextField(
              controller: chatProvider.channelMessageController,
              decoration: InputDecoration(hintText: 'Input channel message'))),
      OutlineButton(
        child: Text('Send to Channel'),
        onPressed: chatProvider.toggleSendChannelMessage,
      )
    ]);
  }

  void initialize() async {
    if (APP_ID.isEmpty) {
      final chatProvider = context.read<ChatProvider>();
     
        chatProvider
            .add('APP_ID missing, please provide your APP_ID in settings.dart');
        chatProvider.add('Agora Engine is not starting');
      
      return;
    }

    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();

    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    configuration.dimensions = VideoDimensions(1920, 1080);
    await _engine.setVideoEncoderConfiguration(configuration);
    await _engine.joinChannel(null, widget.channelName, null, 0);
  }

  /// Create agora sdk instance and initialize
  Future<void> _initAgoraRtcEngine() async {
    _engine = await RtcEngine.createWithConfig(RtcEngineConfig(APP_ID));
    await _engine.enableVideo();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(widget.role);
  }

  /// Add agora event handlers
  void _addAgoraEventHandlers() {
    final chatProvider = context.read<ChatProvider>();
    _engine.setEventHandler(
      RtcEngineEventHandler(
        error: (code) {
          final info = 'onError: $code';
          chatProvider.add(info);
        },
        joinChannelSuccess: (channel, uid, elapsed) {
          final info = 'onJoinChannel: $channel, uid: $uid';
          chatProvider.add(info);
        },
        leaveChannel: (stats) {
          chatProvider.add('onLeaveChannel');
          _users.clear();
        },
        userJoined: (uid, elapsed) {
          final info = 'userJoined: $uid';
          chatProvider.add(info);
          _users.add(uid);
        },
        userOffline: (uid, elapsed) {
          final info = 'userOffline: $uid';
          chatProvider.add(info);
          _users.remove(uid);
        },
        firstRemoteVideoFrame: (uid, width, height, elapsed) {
          final info = 'firstRemoteVideo: $uid ${width}x $height';
          chatProvider.add(info);
        },
      ),
    );
  }

  /// Helper function to get list of native views
  List<Widget> _getRenderViews() {
    final List<StatefulWidget> list = [];
    if (widget.role == ClientRole.Broadcaster) {
      list.add(RtcLocalView.SurfaceView());
    }
    _users.forEach((int uid) => list.add(RtcRemoteView.SurfaceView(uid: uid)));
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
    if (widget.role == ClientRole.Audience) return Container();
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            onPressed: _onToggleMute,
            child: Icon(
              muted ? Icons.mic_off : Icons.mic,
              color: muted ? Colors.white : Colors.blueAccent,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: muted ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(12.0),
          ),
          RawMaterialButton(
            onPressed: () => _onCallEnd(context),
            child: Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
          ),
          RawMaterialButton(
            onPressed: _onSwitchCamera,
            child: Icon(
              Icons.switch_camera,
              color: Colors.blueAccent,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.white,
            padding: const EdgeInsets.all(12.0),
          )
        ],
      ),
    );
  }

  void _onCallEnd(BuildContext context) {
    Navigator.pop(context);
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    print('start build');
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: <Widget>[
                    _viewRows(),
                    _ChatLayout(),
                    _toolbar(),
                  ],
                ),
              ),
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    _buildSendChannelMessage(),
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

class _ChatLayout extends StatelessWidget {
  const _ChatLayout({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.5,
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
