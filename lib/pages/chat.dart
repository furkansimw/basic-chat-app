import 'dart:async';

import 'package:chat/data/const.dart';
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
  bool can = false;
  String myUid = FirebaseAuth.instance.currentUser!.uid;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> messages = [];
  @override
  void initState() {
    super.initState();
    isFriend();
  }

  void isFriend() async {
    var _get = await FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('contacts')
        .doc(widget.data['uid'])
        .get();
    can = _get.exists;
    if (can) {
      get();
    }
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

  TextEditingController messageController = TextEditingController();
  void delete(item) {
    FirebaseFirestore.instance
        .collection('messages')
        .doc(docId)
        .collection('messages')
        .doc(item.id)
        .delete();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 45,
        title: SizedBox(
          height: 50,
          child: Row(children: [
            Padding(
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: AspectRatio(
                    aspectRatio: 1,
                    child: widget.data['pp'] == null
                        ? Image.asset('assets/none.png')
                        : Image.network(widget.data['pp'])),
              ),
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
            child: can
                ? ListView.builder(
                    reverse: true,
                    controller: controller,
                    itemCount: messages.length,
                    itemBuilder: (context, index) => GestureDetector(
                        onLongPress: () {
                          if (messages[index].data()['sender'] == myUid) {
                            deleteDialog(index, () {
                              setState(() {});
                            });
                          }
                        },
                        child: _messageItem(data: messages[index])),
                  )
                : const Center(
                    child: Text('you are not friends',
                        style: TextStyle(fontSize: 22),
                        textAlign: TextAlign.center)),
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
                    if (messageController.text.isEmpty) {
                      return;
                    }
                    if (!can) {
                      toast('you are not friends');
                      null;
                    }
                    String message = messageController.text;

                    messageController.clear();
                    print('starting');
                    var data = {
                      'date': FieldValue.serverTimestamp(),
                      'sender': myUid,
                      'message': message,
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
                      'lastdate': data['date'],
                      'hide': [],
                    });
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

  String converter(DateTime item) {
    var month = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    var now = DateTime.now();
    if (item.year == now.year) {
      if (item.month == now.month) {
        if (item.day == now.day) {}
      }
    }

    return '${item.year} ${item.day} ${month[item.month - 1]} ${item.hour}:${item.minute}';
  }

  deleteDialog(index, update) {
    return showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Message :',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(messages[index].data()['message']),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Date : ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(converter(DateTime.fromMillisecondsSinceEpoch(
                    messages[index].data()['date'].seconds * 1000))),
              ],
            ),
            const SizedBox(height: 10),
            TextButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('messages')
                      .doc(docId)
                      .collection('messages')
                      .doc(messages[index].id)
                      .delete();
                  update();
                  var get = await FirebaseFirestore.instance
                      .collection('messages')
                      .doc(docId)
                      .collection('messages')
                      .orderBy('date')
                      .limit(1)
                      .get();
                  var data;
                  try {
                    data = get.docs[0].data();
                  } catch (e) {
                    data = {
                      'lastmsg': null,
                      'lastdate': null,
                      'lastsender': null
                    };
                  }
                  await FirebaseFirestore.instance
                      .collection('messages')
                      .doc(docId)
                      .update({
                    'lastmsg': data['message'],
                    'lastdate': data['date'],
                    'lastsender': data['sender']
                  });
                  Navigator.pop(context);
                },
                child: const Text('Delete')),
            const SizedBox(height: 10),
          ],
        ),
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
