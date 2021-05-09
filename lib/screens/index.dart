import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bigo/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import './call.dart';

class IndexPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => IndexState();
}

class IndexState extends State<IndexPage> {
  final _channelController = TextEditingController();
  bool _validateError = false;
  ClientRole _role = ClientRole.Broadcaster;

  @override
  void dispose() {
    // dispose input controller
    _channelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('start');
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 7,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 70,
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _role = ClientRole.Broadcaster;
                                  });
                                },
                                child: SvgPicture.asset(
                                  'assets/icons/live-streaming.svg',
                                  color: _role == ClientRole.Broadcaster
                                      ? Colors.black
                                      : Colors.black.withOpacity(0.3),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _role = ClientRole.Audience;
                                  });
                                },
                                child: SvgPicture.asset(
                                  'assets/icons/customer.svg',
                                  color: _role == ClientRole.Audience
                                      ? Colors.black
                                      : Colors.black.withOpacity(0.3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      _FieldName(
                        channelController: _channelController,
                        validateError: _validateError,
                      ),
                      _JoinButton(
                        function: () {
                          onJoin();
                        },
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onJoin() async {
    // update input validation
    setState(() {
      _channelController.text.isEmpty
          ? _validateError = true
          : _validateError = false;
    });
    if (_channelController.text.isNotEmpty) {
      // await for camera and mic permissions before pushing video page
      await _handleCameraAndMic(Permission.camera);
      await _handleCameraAndMic(Permission.microphone);
      // push video page with given channel name
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            final provider = context.read<LiveStreamProvider>();
            provider.channelName = _channelController.text;
            provider.role = _role;
            return CallPage();
          },
        ),
      );
    }
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    print(status);
  }
}

class _FieldName extends StatelessWidget {
  const _FieldName({
    Key key,
    @required TextEditingController channelController,
    @required bool validateError,
  })  : _channelController = channelController,
        _validateError = validateError,
        super(key: key);

  final TextEditingController _channelController;
  final bool _validateError;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _channelController,
      cursorColor: Colors.black87,
      decoration: InputDecoration(
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black87),
        ),
        errorText: _validateError ? 'Channel name is mandatory' : null,
        border: UnderlineInputBorder(
          borderSide: BorderSide(width: 0.5),
        ),
        hintText: 'Channel name',
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({
    Key key,
    this.function,
  }) : super(key: key);
  final Function function;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: FlatButton(
              onPressed: function,
              child: Text(
                'Join',
                style: TextStyle(fontSize: 20.sp),
              ),
              color: Colors.white,
              textColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
          )
        ],
      ),
    );
  }
}
