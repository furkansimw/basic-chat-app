import 'package:chat/data/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  Future<void> search() async {
    if (searchController.text.isEmpty) {
      return;
    }
    result.clear();
    setState(() {});
    var userNameForArray = [];
    var uidForArray = [];
    var emailForArray = [];
    var get1 = await FirebaseFirestore.instance
        .collection('users')
        .where('userName',
            isEqualTo: searchController.text,
            isNotEqualTo: getx.myData['userName'])
        .limit(20)
        .get();
    var get2 = await FirebaseFirestore.instance
        .collection('users')
        .where('uid',
            isEqualTo: searchController.text, isNotEqualTo: getx.myData['uid'])
        .limit(20)
        .get();
    var get3 = await FirebaseFirestore.instance
        .collection('users')
        .where('email',
            isEqualTo: searchController.text,
            isNotEqualTo: getx.myData['email'])
        .limit(20)
        .get();
    for (var element in get1.docs) {
      userNameForArray.add(element.data());
    }
    for (var element in get2.docs) {
      uidForArray.add(element.data());
    }
    for (var element in get3.docs) {
      emailForArray.add(element.data());
    }
    for (var element in userNameForArray) {
      if (uidForArray.contains(element)) {
        uidForArray.remove(element);
      }
      if (emailForArray.contains(element)) {
        emailForArray.remove(element);
      }
    }

    result.addAll(userNameForArray + uidForArray + emailForArray);
    setState(() {});
  }

  var searchController = TextEditingController();
  var result = [];
  Getx getx = Get.find();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          onSubmitted: (submit) async => await search(),
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Search uid email or userName',
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () async => await search(),
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
      ),
      body: ListView.builder(
        itemCount: result.length,
        itemBuilder: (context, index) {
          var data = result[index];
          return _SeachItem(data, getx.myData);
        },
      ),
    );
  }
}

class _SeachItem extends StatefulWidget {
  var data, mydata;

  _SeachItem(this.data, this.mydata);

  @override
  State<_SeachItem> createState() => _SeachItemState();
}

enum Status { friend, waiting, none }

class _SeachItemState extends State<_SeachItem> {
  Status status = Status.none;

  @override
  void initState() {
    super.initState();
    start();
  }

  Future<void> start() async {
    var get = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.mydata['uid'])
        .collection('contacts')
        .doc(widget.data['uid'])
        .get();
    var exists = get.exists;
    if (exists) {
      status = Status.friend;
    } else {
      var get2 = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.mydata['uid'])
          .collection('waiting')
          .doc(widget.data['uid'])
          .get();
      var ex = get2.exists;
      if (ex) {
        status = Status.waiting;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => Container(
            color: Colors.black12,
            child: Column(
              children: [
                const SizedBox(height: 10),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 4,
                  child: ClipOval(
                    child: widget.data['pp'] == null
                        ? Image.asset('assets/none.png')
                        : Image.network(widget.data['pp']),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Username : '),
                    Text(widget.data['userName'].toString(),
                        style: const TextStyle(fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Bio : '),
                    Text(
                      widget.data['bio'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.values[1],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () async {
                    if (status == Status.none) {
                      status = Status.waiting;
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.data['uid'])
                          .collection('waiting')
                          .doc(widget.mydata['uid'])
                          .set({});
                      Navigator.pop(context);
                    } else if (status == Status.friend) {
                      print(status);
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                              'Are you sure remove friend ${widget.data['userName']}'),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(widget.mydata['uid'])
                                      .collection('contacts')
                                      .doc(widget.data['uid'])
                                      .delete();
                                  status = Status.none;
                                  setState(() {});
                                  Navigator.pop(context);
                                },
                                child: const Text('Remove')),
                          ],
                        ),
                      );
                    } else if (status == Status.waiting) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.mydata['uid'])
                          .collection('waiting')
                          .doc(widget.data['uid'])
                          .delete();
                      status = Status.none;
                      Navigator.pop(context);
                    }

                    setState(() {});
                  },
                  child: Text(status == Status.none
                      ? 'Request Send'
                      : status == Status.waiting
                          ? 'Waiting'
                          : 'You are friend'),
                )
              ],
            ),
          ),
        );
      },
      child: Container(
        height: 70,
        color: Colors.black12,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: ClipOval(
                child: widget.data['pp'] == null
                    ? Image.asset('assets/none.png')
                    : Image.network(widget.data['pp']),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Text(
                  widget.data['userName'],
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  widget.data['bio'] ?? '',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
            const Spacer(),
            status == Status.friend
                ? const Icon(Icons.person)
                : status == Status.waiting
                    ? const Icon(Icons.loop)
                    : const SizedBox()
          ]),
        ),
      ),
    );
  }
}
