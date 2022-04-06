import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  var myData;
  SettingsPage(this.myData);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 15),
          Center(
            child: Hero(
              tag: 'pp',
              child: SizedBox(
                width: MediaQuery.of(context).size.width / 3,
                child: ClipOval(
                  child: widget.myData['pp'] == null
                      ? Image.asset('assets/none.png')
                      : Image.network(widget.myData['pp']),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            widget.myData['userName'].toString(),
            style: const TextStyle(
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}
