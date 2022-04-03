import 'package:chat/data/const.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final style = const TextStyle(fontSize: 18);
  bool login = true;
  TextEditingController controller1 = TextEditingController(),
      controller2 = TextEditingController(),
      controller3 = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(login ? 'Login' : 'signUp')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(children: [
          const Spacer(flex: 3),
          Visibility(visible: !login, child: _tf('Username', controller1)),
          const SizedBox(height: 10),
          _tf('Email', controller2),
          const SizedBox(height: 10),
          _tf('Password', controller3),
          const SizedBox(height: 30),
          ElevatedButton(
              onPressed: () {
                if (login) {
                  FireLogin.login(controller2.text.toString(),
                      controller3.text.toString(), context, (code) {
                    if (code == 'user-not-found') {
                      controller2.clear();
                    }
                    if (code == 'wrong-password') {
                      controller3.clear();
                    }
                    setState(() {});
                  });
                } else {
                  if (controller1.text.length > 3) {
                    FireLogin.singUp(
                        controller1.text.toString(),
                        controller2.text.toString(),
                        controller3.text.toString(),
                        context, (code) {
                      if (code == 'email-already-in-use') {
                        login = true;
                      }
                      if (code == 'weak-password') {
                        controller3.clear();
                      }
                      setState(() {});
                    });
                  } else {
                    toast('Username min 4 digit must');
                  }
                }
              },
              child: Text(login ? 'Login' : 'singUp')),
          const SizedBox(height: 10),
          TextButton(
              onPressed: () => setState(() => login = !login),
              child: Text(login ? 'singUp' : 'Login')),
          const Spacer(flex: 2),
        ]),
      ),
    );
  }

  Widget _tf(String label, TextEditingController controller) => TextField(
      style: style,
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(labelText: label),
      obscureText: label == 'Password');
}

//all firebase login funcs
class FireLogin {
  static Future<void> login(
      String email, String password, BuildContext context, analyzer) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      await setPref(context);
    } on FirebaseAuthException catch (e) {
      analyzer(e.code);
      if (e.code == 'user-not-found') {
        toast('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        toast('Wrong password provided for that user.');
      }
    }
  }

  static Future<void> singUp(String userName, String email, String password,
      BuildContext context, analyzer) async {
    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await fireSetup(userName, email, context);
    } on FirebaseAuthException catch (e) {
      analyzer(e.code);
      if (e.code == 'weak-password') {
        toast('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        toast('The account already exists for that email.');
      }
    } catch (e) {
      toast(e.toString());
    }
  }

  static Future<void> fireSetup(
      String userName, String email, BuildContext context) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    var data = {
      'uid': uid,
      'email': email,
      'bio': null,
      'pp': null,
      'userName': userName,
    };
    await FirebaseFirestore.instance.collection('users').doc(uid).set(data);
    await setPref(context);
  }

  static Future<void> setPref(BuildContext context) async {
    var sp = await SharedPreferences.getInstance();
    await sp.setBool('isAuth', true);
    Navigator.pushNamedAndRemoveUntil(context, 'core', (route) => false);
  }
}
