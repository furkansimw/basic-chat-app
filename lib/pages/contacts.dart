import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat.dart';

class Contacts extends StatefulWidget {
  String uid;
  Contacts({required this.uid});

  @override
  State<Contacts> createState() => _ContactsState();
}

class _ContactsState extends State<Contacts> {
  var controller = PageController();
  int limit = 50;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> contacts = [];
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
        .collection('contacts')
        .limit(limit)
        .get();
    contacts.clear();
    for (var element in get.docs) {
      contacts.add(element);
    }
    setState(() {});
  }

  Future<void> updateData() async {
    var get = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('contacts')
        .startAfterDocument(contacts.last)
        .limit(limit)
        .get();
    for (var element in get.docs) {
      contacts.add(element);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Contacts'),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ListView.builder(
              padding: const EdgeInsets.only(top: 10),
              controller: controller,
              itemCount: contacts.length,
              itemBuilder: (c, i) =>
                  _ContactItem(contacts[i].id, () => getData())),
        ));
  }
}

class _ContactItem extends StatelessWidget {
  String useruid;
  var update;
  _ContactItem(this.useruid, this.update);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      width: double.infinity,
      child: FutureBuilder(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(useruid)
            .get()
            .then((value) => value.data()),
        builder: (context, AsyncSnapshot snapshot) {
          var data = snapshot.data;
          // if (snapshot.connectionState == ConnectionState.waiting) {
          //   return const Center(child: CircularProgressIndicator());
          // }

          if (snapshot.hasData) {
            return GestureDetector(
              onTap: () => showModalBottomSheet(
                  context: context,
                  builder: (context) => Container(
                        color: Colors.black12,
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            SizedBox(
                              width: MediaQuery.of(context).size.width / 4,
                              child: ClipOval(
                                child: data['pp'] == null
                                    ? Image.asset('assets/none.png')
                                    : Image.network(data['pp']),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Username : '),
                                Text(data['userName'].toString(),
                                    style: const TextStyle(fontSize: 18)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Bio : '),
                                Text(
                                  data['bio'] ?? '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontStyle: FontStyle.values[1],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            IconButton(
                                tooltip: 'Remove Contact ${data['userName']}',
                                onPressed: () {
                                  Navigator.pop(context);
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(
                                          'Are you sure remove ${data['userName']}'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancel')),
                                        TextButton(
                                            onPressed: () async {
                                              String myUid = FirebaseAuth
                                                  .instance.currentUser!.uid;
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(myUid)
                                                  .collection('contacts')
                                                  .doc(data['uid'])
                                                  .delete();
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(data['uid'])
                                                  .collection('contacts')
                                                  .doc(myUid)
                                                  .delete();
                                              update();
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Remove')),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.remove_circle_outline)),
                          ],
                        ),
                      )),
              child: Container(
                color: Colors.transparent,
                child: Row(
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
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Chat(data: data)));
                        },
                        child: const Icon(Icons.message)),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
