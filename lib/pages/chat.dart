import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Chat extends StatefulWidget {
  var data;
  
  Chat({Key? key, required this.data}) : super(key: key);

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  bool firstTime = false;
  var controller = PageController();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> messages = [];
  @override
  void initState() {
    super.initState();
    get();
  }

  void scrollListener() {
    controller.addListener(() async {
      if (controller.offset == controller.position.maxScrollExtent) {
        var get = await FirebaseFirestore.instance
            .collection('messages')
            .doc(docId)
            .collection('messages')
            .limit(limit)
            .orderBy('date', descending: true)
            .startAfterDocument(messages.last)
            .get();

        var arrays = get.docs;
        messages.addAll(arrays);
        setState(() {});
      }
    });
  }

  late String docId;
  late StreamSubscription<QuerySnapshot<Map<String, dynamic>>> listener;
  int limit = 100;

  Future<void> get() async {
    bool exists = false;
    String myUid = FirebaseAuth.instance.currentUser!.uid;

    var get = await FirebaseFirestore.instance
        .collection('messages')
        .where('users', arrayContains: myUid)
        .get();

    try {
      exists = get.docs[0].exists;
    } catch (e) {
      exists = false;
    }
    print(exists);
    if (exists) {
      scrollListener();
      docId = get.docs[0].id;
      listener = FirebaseFirestore.instance
          .collection('messages')
          .doc(docId)
          .collection('messages')
          .limit(limit)
          .orderBy('date', descending: true)
          .snapshots()
          .listen((event) {
        messages = event.docs;
        setState(() {});
      });
    } else {
      firstTime = true;
    }
  }

  String myUid = FirebaseAuth.instance.currentUser!.uid;
  TextEditingController messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 45,
        title: SizedBox(
          height: 50,
          child: Row(children: [
            Hero(
              tag: 'pp ',
              child: widget.data['pp'] == null
                  ? Padding(
                      padding: const EdgeInsets.all(3),
                      child: ClipOval(
                        child: AspectRatio(
                            aspectRatio: 1,
                            child: Image.asset('assets/none.png')),
                      ),
                    )
                  : Image.network(widget.data['pp']),
            ),
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
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              controller: controller,
              itemCount: messages.length,
              itemBuilder: (context, index) =>
                  _messageItem(data: messages[index]),
            ),
          ),
          SizedBox(
            height: 60,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    var data = {
                      'date': FieldValue.serverTimestamp(),
                      'sender': myUid,
                      'message': messageController.text,
                    };
                    print('---');
                    if (firstTime) {
                      //first time
                      print('first time');
                      var add = await FirebaseFirestore.instance
                          .collection('messages')
                          .add({
                        'users': [myUid, widget.data['uid']],
                        'cache': null,
                      });
                      docId = add.id;
                      firstTime = false;
                      get();
                    }
                    await FirebaseFirestore.instance
                        .collection('messages')
                        .doc(docId)
                        .collection('messages')
                        .add(data);
                    await FirebaseFirestore.instance
                        .collection('messages')
                        .doc(docId)
                        .update({
                      'lastmsg': data['message'],
                      'lastsender': data['sender'],
                      'lastdate': data['date']
                    });
                    messageController.clear();
                  },
                  icon: const Icon(Icons.send, size: 30),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _messageItem extends StatelessWidget {
  var data;
  _messageItem({required this.data});
  String myUid = FirebaseAuth.instance.currentUser!.uid;
  @override
  Widget build(BuildContext context) {
    double x = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisAlignment: data.data()['sender'] == myUid
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: x * .6),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                data.data()['message'].toString(),
                textAlign: data.data()['sender'] == myUid
                    ? TextAlign.right
                    : TextAlign.left,
                maxLines: 5,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
