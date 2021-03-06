import 'package:flutter/material.dart';
import 'package:flutter_bigo/provider.dart';
import 'package:flutter_bigo/screens/index.dart';
import 'package:flutter_bigo/screens/login.dart';
import 'package:flutter_screenutil/screenutil_init.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('error');
          return SizedBox();
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return MyApp();
        }

        return SizedBox();
      },
    );
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(412, 870),
      allowFontScaling: false,
      builder: () => MultiProvider(
        providers: [
          ChangeNotifierProvider<LiveStreamProvider>(
            create: (_) => LiveStreamProvider(),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: LoginScreen(),
        ),
      ),
    );
  }
}
