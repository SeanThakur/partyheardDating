import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import './MyDashboard.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  SharedPreferences logindata;
  bool newuser;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  FacebookLogin facebookLogin = new FacebookLogin();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    check_if_already_login();
  }
  void check_if_already_login() async {
    logindata = await SharedPreferences.getInstance();
    newuser = (logindata.getBool('login') ?? true);
    print(newuser);
    if (newuser == false) {
      Navigator.pushReplacement(
          context, new MaterialPageRoute(builder: (context) => MyDashboard()));
    }
  }

  Future<Null> _signInFacebook() async {
    final FacebookLoginResult result = await facebookLogin.logIn(['email']);
    switch (result.status) {
      case FacebookLoginStatus.loggedIn:
        final FacebookAccessToken accessToken = result.accessToken;
        _auth.signInWithCredential(
          FacebookAuthProvider.getCredential(accessToken: accessToken.token),
        ).then((user) async {
          final graphResponse = await http.get(
              'https://graph.facebook.com/v2.12/me?fields=name,picture.height(640).width(640),first_name,last_name,email&access_token=${accessToken.token}');
          var profile = json.decode(graphResponse.body);
          print(profile.toString());
          //Checking if the user id is present if does then navigate to MyDashboard page
          if (profile["id"] != '') {
            print('Successfull');
            logindata.setBool('login', false);
            logindata.setString('id', profile["id"]);
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => MyDashboard()));
          }
          //storing Snapshot
          final DocumentSnapshot doc = await Firestore.instance.collection("datingUser").document(user.user.uid).get();
          //Storing the user data in the Firestore database
          if (!doc.exists) {
            await Firestore.instance.collection("datingUser").document(user.user.uid).setData({
              "firstName": profile["first_name"],
              "lastName": profile["last_name"],
              "userName": profile["name"],
              "email": profile['email'],
              "photUrl": profile["picture"]["data"]["url"],
              "signin_method": 'Facebook',
              "uid": user.user.uid,
            });
          }
        });

        break;
      case FacebookLoginStatus.cancelledByUser:
        print('Login cancelled by the user.');
        break;
      case FacebookLoginStatus.error:
        print('Something went wrong with the login process.\n'
            'Here\'s the error Facebook gave us: ${result.errorMessage}');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.redAccent,Colors.yellow[400]]
          )
        ),
        child: Center(
          child: InkWell(
            onTap: () {
              _signInFacebook();
            },
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: EdgeInsets.symmetric(
                vertical: 20.0,
                horizontal: 20.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    FontAwesomeIcons.facebookF,
                    color: Colors.red,
                    size: 20.0,
                  ),
                  Text(
                    ' |  Sign in with Facebook',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 20.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      )
    );
  }
}
