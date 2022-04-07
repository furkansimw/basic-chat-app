import 'package:chat/data/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  var searchController = TextEditingController();
  var result = [];
  Getx getx = Get.find();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Search uid email or userName',
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () async {
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
                      isEqualTo: searchController.text,
                      isNotEqualTo: getx.myData['uid'])
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
            },
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

class _SeachItemState extends State<_SeachItem> {
  bool exist = false;

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
    exist = get.exists;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
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
            Visibility(visible: exist, child: const Icon(Icons.person)),
          ]),
        ),
      ),
    );
  }
}
