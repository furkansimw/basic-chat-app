import 'package:chat/pages/core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';

class Ma extends StatefulWidget {
  const Ma({Key? key}) : super(key: key);

  @override
  State<Ma> createState() => _MaState();
}

class _MaState extends State<Ma> {
  bool? _isAuth;
  @override
  void initState() {
    super.initState();
    start();
  }

  Future<void> start() async {
    var sp = await SharedPreferences.getInstance();
    bool isAuth = sp.getBool('isAuth') ?? false;
    setState(() {
      _isAuth = isAuth;
    });
  }

  Widget builder() {
    if (_isAuth == null) {
      return const SizedBox();
    } else if (_isAuth!) {
      return const Core();
    } else {
      return const Login();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      routes: {
        'login': (context) => const Login(),
        'core': (context) => const Core(),
      },
      home: builder(),
    );
  }
}
