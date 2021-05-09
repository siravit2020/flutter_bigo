import 'package:flutter/material.dart';
import 'package:flutter_bigo/authentications/authentication_with_google.dart';
import 'package:flutter_bigo/provider.dart';
import 'package:flutter_bigo/screens/index.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/bigo_logo.png',
                width: 0.3.sw,
              ),
              SizedBox(
                height: 4,
              ),
              Text(
                'Fake',
                style: TextStyle(color: Colors.grey.shade400),
              ),
              SizedBox(
                height: 30,
              ),
              _ButtonLogin()
            ],
          ),
        ),
      ),
    );
  }
}

class _ButtonLogin extends StatelessWidget {
  const _ButtonLogin({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30.0),
      ),
      color: Colors.white,
      onPressed: () async {
        var result = await loginWithGoogle();
        if (result != null) {
          context.read<LiveStreamProvider>().uid = result.user.uid;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => IndexPage()),
          );
        }
      },
      child: Text('Login with Google'),
    );
  }
}
