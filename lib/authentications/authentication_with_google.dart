import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<UserCredential> loginWithGoogle() async {
  FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );
  GoogleSignInAccount user = await _googleSignIn.signIn();
  GoogleSignInAuthentication userAuth = await user.authentication;

  return await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: userAuth.idToken, accessToken: userAuth.accessToken));
  
}
