import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bigo/src/utils/settings.dart';
import 'package:provider/provider.dart';

class ChatProvider extends ChangeNotifier {
  List<String> _chat = [];
  bool _isInChannel = false;
  bool _isLogin = false;
  TextEditingController _channelMessageController = TextEditingController();
  AgoraRtmClient _client;
  AgoraRtmChannel _channel;

  set client(v) {
    _client = v;
    notifyListeners();
  }

  get client => _client;

  get channel => _channel;
  void insert(String message) {
    _chat.insert(0, message);
    notifyListeners();
  }

  void add(String message) {
    _chat.add(message);
    notifyListeners();
  }

  void logout() async {
    try {
      await _client.logout();

      log('Logout success.');
    } catch (errorCode) {
      log('Logout error: ');
    }
  }

  void log(String message) {
    print(message);
    _chat.insert(0, message);
    notifyListeners();
  }

  void leaveChannel() async {
    try {
      await _channel.leave();
      log('Leave channel success.');
      _client.releaseChannel(_channel.channelId);
    } catch (errorCode) {
      log('Leave channel error: ' + errorCode.toString());
    }
  }

  void toggleSendChannelMessage() async {
    String text = _channelMessageController.text;
    if (text.isEmpty) {
      log('Please input text to send.');
      return;
    }
    try {
      await _channel.sendMessage(AgoraRtmMessage.fromText(text));
      log(text);
    } catch (errorCode) {
      log('Send channel message error: ' + errorCode.toString());
    }
    channelMessageController.text = '';
  }

  void createClient(String nameLogin, String channelName) async {
    _client = await AgoraRtmClient.createInstance(APP_ID);
    _client.onMessageReceived = (AgoraRtmMessage message, String peerId) {
      log("Peer msg: " + peerId + ", msg: " + message.text);
    };
    _client.onConnectionStateChanged = (int state, int reason) {
      log('Connection state changed: ' +
          state.toString() +
          ', reason: ' +
          reason.toString());
      if (state == 5) {
        _client.logout();
        log('Logout.');
        notifyListeners();
      }
    };
    await _client.login(null, nameLogin);
    log('Login success: ' + nameLogin);

    _isLogin = true;
    notifyListeners();

    try {
      _channel = await _createChannel(channelName);
      await _channel.join();
      log('Join channel success.');

      _isInChannel = true;
      notifyListeners();
    } catch (e) {
      print('Join channel error' + e);
    }
  }

  Future<AgoraRtmChannel> _createChannel(String name) async {
    AgoraRtmChannel channel = await _client.createChannel(name);
    channel.onMemberJoined = (AgoraRtmMember member) {
      log("Member joined: " + member.userId + ', channel: ' + member.channelId);
    };
    channel.onMemberLeft = (AgoraRtmMember member) {
      log("Member left: " + member.userId + ', channel: ' + member.channelId);
    };
    channel.onMessageReceived =
        (AgoraRtmMessage message, AgoraRtmMember member) {
      log("Channel msg: " + member.userId + ", msg: " + message.text);
    };
    return channel;
  }

  set login(bool status) {
    _isLogin = status;
    notifyListeners();
  }

  set inChannel(bool status) {
    _isInChannel = status;
    notifyListeners();
  }

  get chat => _chat;

  get isInChannel => _isInChannel;

  get isLogin => _isLogin;

  get channelMessageController => _channelMessageController;
}
