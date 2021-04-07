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
  int _userNo = 0;
  RtcEngine _engine;
  AgoraRtmClient _client;
  AgoraRtmChannel _channel;

  @override
  void dispose() {
    _users.clear();
    _logout();
    _leaveChannel();
    _engine.leaveChannel();
    _engine.destroy();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initialize();
    _createClient();
  }

  void _logout() async {
    final chatProvider = context.read<ChatProvider>();
    try {
      await _client.logout();
      chatProvider.log('Logout success.');
    } catch (errorCode) {
      chatProvider.log('Logout error: ');
    }
  }

  void _leaveChannel() async {
    final chatProvider = context.read<ChatProvider>();
    try {
      await _channel.leave();
      chatProvider.log('Leave channel success.');
      _client.releaseChannel(_channel.channelId);
    } catch (errorCode) {
      chatProvider.log('Leave channel error: ' + errorCode.toString());
    }
  }

  void _createClient() async {
    final chatProvider = context.read<ChatProvider>();
    _client = await AgoraRtmClient.createInstance(APP_ID);
    _client.onMessageReceived = (AgoraRtmMessage message, String peerId) {
      chatProvider.log("Peer msg: " + peerId + ", msg: " + message.text);
    };
    _client.onConnectionStateChanged = (int state, int reason) {
      chatProvider.log('Connection state changed: ' +
          state.toString() +
          ', reason: ' +
          reason.toString());
      if (state == 5) {
        _client.logout();
        chatProvider.log('Logout.');
      }
    };
    await _client.login(null, widget.nameLogin);
    chatProvider.log('Login success: ' + widget.nameLogin);
    chatProvider.login = true;

    try {
      _channel = await _createChannel(widget.channelName);
      await _channel.join();
      chatProvider.log('Join channel success.');

      chatProvider.inChannel = true;
    } catch (e) {
      print('Join channel error' + e);
    }
  }

  Future<AgoraRtmChannel> _createChannel(String name) async {
    final chatProvider = context.read<ChatProvider>();
    AgoraRtmChannel channel = await _client.createChannel(name);
    channel.onMemberJoined = (AgoraRtmMember member) {
      chatProvider.log(
          "Member joined: " + member.userId + ', channel: ' + member.channelId);
    };
    channel.onMemberLeft = (AgoraRtmMember member) {
      chatProvider.log(
          "Member left: " + member.userId + ', channel: ' + member.channelId);
    };
    channel.onMessageReceived =
        (AgoraRtmMessage message, AgoraRtmMember member) {
      chatProvider
          .log("Channel msg: " + member.userId + ", msg: " + message.text);
    };
    return channel;
  }

  Future<void> initialize() async {
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
                    _ViewRows(
                      role: widget.role,
                      users: _users,
                    ),
                    _ChatLayout(),
                    _toolbar(),
                  ],
                ),
              ),
              InputMessage(channel: _channel,),
            ],
          ),
        ),
      ),
    );
  }
}

class InputMessage extends StatelessWidget {
  const InputMessage({
    Key key, this.channel,
  }) : super(key: key);
  final AgoraRtmChannel channel;
  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          (!chatProvider.isLogin || !chatProvider.isInChannel)
              ? Container()
              : Row(children: <Widget>[
                  Expanded(
                      child: TextField(
                          controller: chatProvider.channelMessageController,
                          decoration: InputDecoration(
                              hintText: 'Input channel message'))),
                  OutlineButton(
                    child: Text('Send to Channel'),
                    onPressed: () => _toggleSendChannelMessage(context,channel),
                  )
                ])
        ],
      ),
    );
  }

  void _toggleSendChannelMessage(BuildContext context,AgoraRtmChannel channel) async {
    final chatProvider = context.read<ChatProvider>();
    String text = chatProvider.channelMessageController.text;
    if (text.isEmpty) {
      chatProvider.log('Please input text to send.');
      return;
    }
    try {
      await channel.sendMessage(AgoraRtmMessage.fromText(text));
      chatProvider.log(text);
    } catch (errorCode) {
      chatProvider.log('Send channel message error: ' + errorCode.toString());
    }
  }
}

class _ViewRows extends StatelessWidget {
  const _ViewRows({
    Key key,
    this.users,
    this.role,
  }) : super(key: key);
  final List<int> users;
  final ClientRole role;
  @override
  Widget build(BuildContext context) {
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

  /// Video view row wrapper
  Widget _expandedVideoRow(List<Widget> views) {
    final wrappedViews = views.map<Widget>(_videoView).toList();
    return Expanded(
      child: Row(
        children: wrappedViews,
      ),
    );
  }

  /// Helper function to get list of native views
  List<Widget> _getRenderViews() {
    final List<StatefulWidget> list = [];
    if (role == ClientRole.Broadcaster) {
      list.add(RtcLocalView.SurfaceView());
    }
    users.forEach((int uid) => list.add(RtcRemoteView.SurfaceView(uid: uid)));
    return list;
  }

  /// Video view wrapper
  Widget _videoView(view) {
    return Expanded(child: Container(child: view));
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
