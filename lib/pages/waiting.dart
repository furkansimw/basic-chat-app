import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WaitingPage extends StatefulWidget {
  String uid;

  WaitingPage(this.uid);

  @override
  State<WaitingPage> createState() => _WaitingPageState();
}

class _WaitingPageState extends State<WaitingPage> {
  var controller = PageController();
  int limit = 50;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> waiting = [];
  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      setState(() {
        if (controller.offset == controller.position.maxScrollExtent) {
          limit += 20;
          updateData();
        }
      });
    });
    getData();
  }

  Future<void> getData() async {
    var get = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('waiting')
        .limit(limit)
        .get();
    waiting.clear();
    for (var element in get.docs) {
      waiting.add(element);
    }
    setState(() {});
  }

  Future<void> updateData() async {
    var get = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('waiting')
        .startAfterDocument(waiting.last)
        .limit(limit)
        .get();
    for (var element in get.docs) {
      waiting.add(element);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Waiting')),
      body: RefreshIndicator(
        onRefresh: () async {
          await getData();
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: controller,
          itemCount: waiting.length,
          itemBuilder: (c, i) => _WaitingItem(waiting[i], widget.uid, (uid) {
            setState(() {
              waiting.remove(uid);
            });
          }),
        ),
      ),
    );
  }
}

class _WaitingItem extends StatelessWidget {
  var userId;
  String myUid;
  var update;
  _WaitingItem(this.userId, this.myUid, this.update);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black12,
      width: double.infinity,
      height: 70,
      child: FutureBuilder(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(userId.id)
              .get()
              .then((value) => value.data()),
          builder: (context, AsyncSnapshot snapshot) {
            var data = snapshot.data;
            if (snapshot.hasData) {
              return Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipOval(
                      child: data['pp'] == null
                          ? Image.asset('assets/none.png')
                          : Image.network(data['pp']),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: data['bio'] != null ? 12 : 0),
                      Text(
                        data['userName'].toString(),
                        style: const TextStyle(fontSize: 18),
                      ),
                      Visibility(
                        visible: data['bio'] != null,
                        child: Text(
                          data['bio'].toString(),
                          style: const TextStyle(
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                      onTap: () async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(myUid)
                            .collection('waiting')
                            .doc(userId.id)
                            .delete();
                        update(userId);
                      },
                      child: const Icon(Icons.delete)),
                  const SizedBox(width: 10),
                  GestureDetector(
                      onTap: () async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(myUid)
                            .collection('waiting')
                            .doc(userId.id)
                            .delete();
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(myUid)
                            .collection('contacts')
                            .doc(userId.id)
                            .set({});
                        update(userId);
                      },
                      child: const Icon(Icons.done, size: 30)),
                  const SizedBox(width: 15),
                ],
              );
            }
            return const SizedBox();
          }),
    );
  }
}
