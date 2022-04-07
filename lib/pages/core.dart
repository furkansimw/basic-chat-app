import 'package:chat/data/const.dart';
import 'package:chat/data/get.dart';
import 'package:chat/pages/chat.dart';
import 'package:chat/pages/contacts.dart';
import 'package:chat/pages/settingspage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Core extends StatefulWidget {
  const Core({Key? key}) : super(key: key);

  @override
  State<Core> createState() => _CoreState();
}

class _CoreState extends State<Core> {
  Getx getx = Get.put(Getx());
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
        .where('users', arrayContains: myUid)
        .orderBy('lastdate', descending: true)
        .limit(30)
        .snapshots()
        .listen((event) {
      messagePerson.clear();

      for (var element in event.docs) {
        if (element.data()['hide'].contains(myUid)) {
          messagePerson.remove(element);
        } else {
          messagePerson.add(element);
        }
      }

      setState(() {});
    });
  }

  String myUid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> getData() async {
    var get =
        await FirebaseFirestore.instance.collection('users').doc(myUid).get();
    getx.myData.value = get.data()!;
    setState(() {});
  }

  final globalKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        drawer: Drawer(
            child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Hero(
                tag: 'pp',
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: ClipOval(
                    child: getx.myData['pp'] == null
                        ? Image.asset('assets/none.png', fit: BoxFit.cover)
                        : Image.network(getx.myData['pp'], fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                getx.myData['userName'].toString(),
                style: const TextStyle(
                  fontSize: 20,
                ),
              ),
              Visibility(
                visible: getx.myData['bio'] != null,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    getx.myData['bio'].toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsPage()));
                  },
                  icon: const Icon(Icons.settings)),
              const Divider(thickness: 2),
              const Spacer(),
              IconButton(
                  onPressed: () async {
                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                              title: const Text('Are you sure app exit'),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () async {
                                      var sp =
                                          await SharedPreferences.getInstance();
                                      await FirebaseAuth.instance.signOut();
                                      await sp.setBool('isAuth', false);
                                      Navigator.pushNamedAndRemoveUntil(
                                          context, 'login', (route) => false);
                                    },
                                    child: const Text('Exit')),
                              ],
                            ));
                  },
                  icon: const Icon(Icons.exit_to_app_outlined)),
              const SizedBox(height: 50),
            ],
          ),
        )),
        appBar: AppBar(
          actions: [
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, 'search'),
              child: const Hero(
                tag: 'search',
                child: Icon(
                  Icons.search,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          title: const Text('Messages'),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await getData();
          },
          child: ListView.builder(
            itemCount: messagePerson.length,
            itemBuilder: (context, index) => Container(
              color: Colors.black12,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _ContactItem(
                  findUser(messagePerson[index].data()['users']).toString(),
                  messagePerson[index],
                ),
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
          // if (snapshot.connectionState == ConnectionState.waiting) {
          //   return const Center(child: CircularProgressIndicator());
          // }
          if (snapshot.hasData) {
            return GestureDetector(
              onLongPress: () => showModalBottomSheet(
                context: context,
                builder: (context) =>
                    Column(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(height: 10),
                  Text(
                    'Deleting chat ${data['userName']}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () async {
                      String myUid = FirebaseAuth.instance.currentUser!.uid;
                      List def = docData.data()['hide'];
                      def.add(myUid);
                      Navigator.pop(context);
                      await FirebaseFirestore.instance
                          .collection('messages')
                          .doc(docData.id)
                          .update({
                        'hide': def,
                      });
                    },
                    child: const Text('Delete'),
                  ),
                  const SizedBox(height: 10),
                ]),
              ),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Chat(data: snapshot.data.data()))),
              child: GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            Chat(data: snapshot.data.data()))),
                child: Container(
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipOval(
                          child: data['pp'] == null
                              ? Image.asset('assets/none.png',
                                  fit: BoxFit.cover)
                              : Image.network(data['pp'], fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                              height:
                                  docData.data()['lastmsg'] != null ? 10 : 0),
                          Text(
                            data['userName'].toString(),
                            style: const TextStyle(fontSize: 18),
                          ),
                          Visibility(
                            visible: docData.data()['lastmsg'] != null,
                            child: Row(
                              children: [
                                Visibility(
                                    visible: docData.data()['lastsender'] !=
                                        personUid,
                                    child: const Icon(Icons.done, size: 20)),
                                Text(
                                  docData.data()['lastmsg'].toString(),
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
          }
          return Row(
            children: const [CircularProgressIndicator()],
          );
        },
      ),
    );
  }
}
