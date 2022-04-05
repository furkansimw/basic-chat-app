import 'package:cloud_firestore/cloud_firestore.dart';
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
              itemBuilder: (c, i) => _ContactItem(contacts[i].data()['uid'])),
        )
        //_ContactItem(contacts[i])),
        );
  }
}

class _ContactItem extends StatelessWidget {
  var useruid;
  _ContactItem(this.useruid);
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Row(
            children: [
              data['pp'] == null
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipOval(child: Image.asset('assets/none.png')),
                    )
                  : Image.network(data['pp']),
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
          );
        },
      ),
    );
  }
}
