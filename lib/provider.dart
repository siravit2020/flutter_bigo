import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class ChatProvider extends ChangeNotifier {
  List<String> _chat = [];
  bool _isInChannel = false;
  bool _isLogin = false;
  TextEditingController _channelMessageController = TextEditingController();
  void insert(String message) {
    _chat.insert(0, message);
    notifyListeners();
  }

  void add(String message) {
    _chat.add(message);
    notifyListeners();
  }

  void log(String message) {
    print(message);
    _chat.insert(0, message);
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
