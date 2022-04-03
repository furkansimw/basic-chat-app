import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Core extends StatefulWidget {
  const Core({Key? key}) : super(key: key);

  @override
  State<Core> createState() => _CoreState();
}

class _CoreState extends State<Core> {
  @override
  void initState() {
    super.initState();
    getData();
  }

  var myData = {};
  Future<void> getData() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    var get =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    myData = get.data()!;
  }

  final globalKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Drawer(),
      appBar: AppBar(actions: [
        Icon(
          Icons.search,
          size: 26,
        ),
        const SizedBox(width: 10),
      ]),
      body: RefreshIndicator(
        onRefresh: () async {
          await getData();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [],
          ),
        ),
      ),
    );
  }
}

