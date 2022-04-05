import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Chat extends StatefulWidget {
  var data;

  Chat({required this.data});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  var messages = [];
  @override
  void initState() {
    super.initState();
    get();
  }

  late String docId;
  late StreamSubscription<QuerySnapshot<Map<String, dynamic>>> listener;
  int limit = 1;
  Future<void> get() async {
    String myUid = FirebaseAuth.instance.currentUser!.uid;
    var get = await FirebaseFirestore.instance
        .collection('chats')
        .where('users', arrayContains: myUid)
        .get();
    bool exists = get.docs[0].exists;
    if (exists) {
      docId = get.docs[0].id;
      listener = FirebaseFirestore.instance
          .collection('chats')
          .doc(docId)
          .collection('messages')
          .limit(limit)
          .orderBy('date', descending: true)
          .snapshots()
          .listen((event) {
        for (var element in event.docs) {
          messages.add(element);
          setState(() {});
        }
      });
    } else {
      //!setup
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: () async {
        await listener.cancel();

        log(limit.toString() + ' limit');
        log(docId);
        listener = FirebaseFirestore.instance
            .collection('chats')
            .doc(docId)
            .collection('messages')
            .limit(limit)
            .orderBy('date', descending: true)
            .startAfterDocument(messages.last)
            .snapshots()
            .listen((event) {
          for (var element in event.docs) {
            messages.add(element);
          }

          setState(() {});
        });
      }),
      appBar: AppBar(
        leadingWidth: 45,
        title: SizedBox(
          height: 50,
          child: Row(children: [
            widget.data['pp'] == null
                ? Padding(
                    padding: const EdgeInsets.all(3),
                    child: ClipOval(
                      child: AspectRatio(
                          aspectRatio: 1,
                          child: Image.asset('assets/none.png')),
                    ),
                  )
                : Image.network(widget.data['pp']),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.data['userName'].toString(),
                softWrap: false,
                overflow: TextOverflow.fade,
              ),
            ),
          ]),
        ),
      ),
      body: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) =>
            Text(messages[index].data()['message'].toString()),
      ),
    );
  }
}
