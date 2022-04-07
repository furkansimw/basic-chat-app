import 'dart:io';

import 'package:chat/data/const.dart';
import 'package:chat/data/get.dart';
import 'package:clipboard/clipboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'contacts.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  initState() {
    super.initState();
    start();
  }

  int contactsLength = 0;
  Future<void> start() async {
    var get = await FirebaseFirestore.instance
        .collection('users')
        .doc(getx.myData['uid'])
        .collection('contacts')
        .get();
    contactsLength = get.docs.length;
    setState(() {});
  }

  Getx getx = Get.find();
  bool userNameEdit = false, bioEdit = false;
  TextEditingController userName = TextEditingController(),
      bioController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          userNameEdit = false;
          bioEdit = false;
        });
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 15),
              Center(
                child: Hero(
                  tag: 'pp',
                  child: GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          TextButton(
                              onPressed: () async =>
                                  await updateImage(ImageSource.gallery),
                              child: const Text('Gallery')),
                          TextButton(
                              onPressed: () async =>
                                  await updateImage(ImageSource.camera),
                              child: const Text('Camera')),
                          Visibility(
                            visible: getx.myData['pp'] != null,
                            child: TextButton(
                                onPressed: () async {
                                  getx.myData['pp'] = null;
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(getx.myData['uid'])
                                      .update({'pp': null});
                                  Navigator.pop(context);
                                },
                                child: const Text('Remove Photo')),
                          ),
                        ]),
                      ),
                    ),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width / 3,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ClipOval(
                          child: getx.myData['pp'] == null
                              ? Image.asset('assets/none.png',
                                  fit: BoxFit.cover)
                              : Image.network(getx.myData['pp'],
                                  fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  userNameEdit
                      ? SizedBox(
                          width: MediaQuery.of(context).size.width / 2,
                          child: TextField(controller: userName))
                      : Text(
                          getx.myData['userName'].toString(),
                          style: const TextStyle(fontSize: 20),
                        ),
                  const SizedBox(width: 10),
                  userNameEdit
                      ? GestureDetector(
                          onTap: () async {
                            if (userName.text.length < 3) {
                              toast('Username min 4 digit must');
                              userNameEdit = false;
                              setState(() {});
                              return;
                            }
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(getx.myData['uid'])
                                .update({'userName': userName.text.toString()});
                            userNameEdit = false;
                            getx.myData['userName'] = userName.text.toString();
                            setState(() {});
                          },
                          child: const Icon(Icons.done))
                      : GestureDetector(
                          onTap: () => setState(() {
                                userName.text = getx.myData['userName'];
                                userNameEdit = true;
                              }),
                          child: const Icon(Icons.edit)),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  bioEdit
                      ? SizedBox(
                          width: MediaQuery.of(context).size.width / 2,
                          child: TextField(controller: bioController))
                      : Text(
                          getx.myData['bio'] ?? 'enter bio',
                          style: const TextStyle(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                  const SizedBox(width: 10),
                  bioEdit
                      ? GestureDetector(
                          onTap: () async {
                            String? data = bioController.text;
                            bioController.text == ''
                                ? data = null
                                : data = bioController.text;
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(getx.myData['uid'])
                                .update({'bio': data});
                            bioEdit = false;
                            getx.myData['bio'] = data;
                            setState(() {});
                          },
                          child: const Icon(Icons.done))
                      : GestureDetector(
                          onTap: () => setState(() {
                                bioController.text = getx.myData['bio'] ?? '';
                                bioEdit = true;
                              }),
                          child: const Icon(Icons.edit)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('you have contact : '),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      var user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        String uid = user.uid;
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Contacts(uid: uid)));
                      } else {
                        toast('User not found\nTry again later');
                      }
                    },
                    child: Text(
                      contactsLength.toString(),
                      style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Visibility(
                visible: MediaQuery.of(context).viewInsets.bottom == 0,
                child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance
                          .sendPasswordResetEmail(email: getx.myData['email']);
                      toast(
                          'sended password reset link ${getx.myData['email']}');
                    },
                    child: const Text('Forgot password')),
              ),
              const Spacer(),
              Visibility(
                visible: MediaQuery.of(context).viewInsets.bottom == 0,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('uid: ', style: TextStyle(fontSize: 12)),
                      Text(
                        getx.myData['uid'].toString(),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                          onTap: () {
                            FlutterClipboard.copy(getx.myData['uid'].toString())
                                .then((value) => toast('copied uid'));
                          },
                          child: const Icon(Icons.copy, size: 20)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> updateImage(ImageSource source) async {
    var picker = ImagePicker();
    var picked = await picker.pickImage(source: ImageSource.gallery);
    Navigator.pop(context);
    if (picked != null) {
      File file = File(picked.path);
      await FirebaseStorage.instance
          .ref('pp')
          .child(getx.myData['uid'] + '.png')
          .putFile(file);

      String imageUrl = await FirebaseStorage.instance
          .ref('pp')
          .child(getx.myData['uid'] + '.png')
          .getDownloadURL();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(getx.myData['uid'])
          .update({'pp': imageUrl});
      getx.myData['pp'] = imageUrl;
    }
  }
}
