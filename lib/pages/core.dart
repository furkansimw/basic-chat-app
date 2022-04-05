import 'package:chat/data/const.dart';
import 'package:chat/pages/chat.dart';
import 'package:chat/pages/contacts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Core extends StatefulWidget {
  const Core({Key? key}) : super(key: key);

  @override
  State<Core> createState() => _CoreState();
}

class _CoreState extends State<Core> {
  List<QueryDocumentSnapshot<Map<String, dynamic>>> messagePerson = [];
  @override
  void initState() {
    super.initState();
    getData();
    getMessagePersonData();
  }

  void getMessagePersonData() {
    FirebaseFirestore.instance
        .collection('messages')
        .orderBy('lastmsg', descending: true)
        .limit(50)
        .snapshots()
        .listen((event) {
      messagePerson = event.docs;
      setState(() {});
    });
  }

  String myUid = FirebaseAuth.instance.currentUser!.uid;
  var myData = {};
  Future<void> getData() async {
    var get =
        await FirebaseFirestore.instance.collection('users').doc(myUid).get();
    myData = get.data()!;
    setState(() {});
  }

  final globalKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Drawer(),
      appBar: AppBar(actions: const [
        Icon(
          Icons.search,
          size: 26,
        ),
        SizedBox(width: 10),
      ]),
      body: RefreshIndicator(
        onRefresh: () async {
          await getData();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ListView.builder(
            itemCount: messagePerson.length,
            itemBuilder: (context, index) => _ContactItem(
              findUser(messagePerson[index].data()['users']).toString(),
              messagePerson[index].data(),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          var user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            String uid = user.uid;
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => Contacts(uid: uid)));
          } else {
            toast('User not found\nTry again later');
          }
        },
        backgroundColor: Colors.white,
        elevation: 0,
        child: const Icon(Icons.chat),
      ),
    );
  }

  String findUser(users) {
    if (users[0] == myUid) {
      return users[1];
    } else {
      return users[0];
    }
  }
}

class _ContactItem extends StatelessWidget {
  String personUid;
  var docData;

  _ContactItem(this.personUid, this.docData);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      width: double.infinity,
      child: FutureBuilder(
        future:
            FirebaseFirestore.instance.collection('users').doc(personUid).get(),
        builder: (context, AsyncSnapshot snapshot) {
          var data = snapshot.data;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Chat(data: snapshot.data.data()))),
            child: GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Chat(data: snapshot.data.data()))),
              child: Container(
                color: Colors.transparent,
                child: Row(
                  children: [
                    data['pp'] == null
                        ? Hero(
                            tag: 'pp',
                            child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ClipOval(
                                    child: Image.asset('assets/none.png'))),
                          )
                        : Image.network(data['pp']),
                    const SizedBox(width: 5),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: docData['lastmsg'] != null ? 10 : 0),
                        Hero(
                          tag: data['userName'],
                          child: Text(
                            data['userName'].toString(),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        Visibility(
                          visible: docData['lastmsg'] != null,
                          child: Row(
                            children: [
                              const Icon(Icons.done, size: 20),
                              Text(
                                docData['lastmsg'].toString(),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
