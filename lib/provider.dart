import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bigo/utils/settings.dart';
export 'package:provider/provider.dart';

class LiveStreamProvider extends ChangeNotifier {
  List<String> _chat = [];
  bool _isInChannel = false;
  bool _isLogin = false;
  TextEditingController _channelMessageController = TextEditingController();
  AgoraRtmClient _client;
  AgoraRtmChannel _channel;
  RtcEngine _engine;
  ClientRole _role;
  String _channelName;
  String _uid;
  final _users = <int>[];

  bool muted = false;

  set client(v) {
    _client = v;
    notifyListeners();
  }

  set role(val) => _role = val;

  set channelName(val) => _channelName = val;

  get engine => _engine;

  get users => _users;

  get role => _role;

  get client => _client;

  get channel => _channel;

  set login(bool status) {
    _isLogin = status;
    notifyListeners();
  }

  set inChannel(bool status) {
    _isInChannel = status;
    notifyListeners();
  }

  set uid(val) => _uid = val;

  get chat => _chat;

  get isInChannel => _isInChannel;

  get isLogin => _isLogin;

  get channelMessageController => _channelMessageController;

  void logout() async {
    try {
      await _client.logout();

      insertText('Logout success.');
    } catch (errorCode) {
      insertText('Logout error: ');
    }
  }

  void insertText(String message) {
    print(message);
    _chat.insert(0, message);
    notifyListeners();
  }

  void leaveChannel() async {
    try {
      await _channel.leave();
      insertText('Leave channel success.');
      _client.releaseChannel(_channel.channelId);
    } catch (errorCode) {
      insertText('Leave channel error: ' + errorCode.toString());
    }
  }

  void initialize() async {
    if (APP_ID.isEmpty) {
      insertText('APP_ID missing, please provide your APP_ID in settings.dart');
      insertText('Agora Engine is not starting');

      return;
    }

    await initAgoraRtcEngine();
    _addAgoraEventHandlers();

    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    configuration.dimensions = VideoDimensions(1920, 1080);
    await _engine.setVideoEncoderConfiguration(configuration);
    await _engine.joinChannel(null, _channelName, null, 0);
  }

  Future<void> initAgoraRtcEngine() async {
    _engine = await RtcEngine.createWithConfig(RtcEngineConfig(APP_ID));

    await _engine.enableVideo();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(_role);
  }

  void toggleSendChannelMessage() async {
    String text = _channelMessageController.text;
    if (text.isEmpty) {
      insertText('Please input text to send.');
      return;
    }
    try {
      await _channel.sendMessage(AgoraRtmMessage.fromText(text));
      insertText(text);
    } catch (errorCode) {
      insertText('Send channel message error: ' + errorCode.toString());
    }
    channelMessageController.text = '';
  }

  void _addAgoraEventHandlers() {
    _engine.setEventHandler(
      RtcEngineEventHandler(
        error: (code) {
          final info = 'onError: $code';
          insertText(info);
        },
        joinChannelSuccess: (channel, uid, elapsed) {
          final info = 'onJoinChannel: $channel, uid: $uid';
          insertText(info);
        },
        leaveChannel: (stats) {
          insertText('onLeaveChannel');
          _users.clear();
        },
        userJoined: (uid, elapsed) {
          final info = 'userJoined: $uid';
          insertText(info);
          _users.add(uid);
        },
        userOffline: (uid, elapsed) {
          final info = 'userOffline: $uid';
          insertText(info);
          _users.remove(uid);
        },
        firstRemoteVideoFrame: (uid, width, height, elapsed) {
          final info = 'firstRemoteVideo: $uid ${width}x $height';
          insertText(info);
        },
      ),
    );
  }

  void onToggleMute() {
    muted = !muted;

    _engine.muteLocalAudioStream(muted);
  }

  void onSwitchCamera() {
    _engine.switchCamera();
  }

  void createClient() async {
    _client = await AgoraRtmClient.createInstance(APP_ID);
    _client.onMessageReceived = (AgoraRtmMessage message, String peerId) {
      insertText("Peer msg: " + peerId + ", msg: " + message.text);
    };
    _client.onConnectionStateChanged = (int state, int reason) {
      insertText('Connection state changed: ' + state.toString() + ', reason: ' + reason.toString());
      if (state == 5) {
        _client.logout();
        insertText('Logout.');
        notifyListeners();
      }
    };
    await _client.login(null, _uid);
    insertText('Login success: ' + _uid);

    _isLogin = true;
    notifyListeners();

    try {
      _channel = await _createChannel(_channelName);

      await _channel.join();
      insertText('Join channel success.');

      _isInChannel = true;
      notifyListeners();
    } catch (e) {
      print('Join channel error' + e);
    }
  }

  Future<AgoraRtmChannel> _createChannel(String name) async {
    AgoraRtmChannel channel = await _client.createChannel(name);
    channel.onMemberJoined = (AgoraRtmMember member) {
      insertText("Member joined: " + member.userId + ', channel: ' + member.channelId);
    };
    channel.onMemberLeft = (AgoraRtmMember member) {
      insertText("Member left: " + member.userId + ', channel: ' + member.channelId);
    };
    channel.onMessageReceived = (AgoraRtmMessage message, AgoraRtmMember member) {
      insertText("Channel msg: " + member.userId + ", msg: " + message.text);
    };
    return channel;
  }
}
