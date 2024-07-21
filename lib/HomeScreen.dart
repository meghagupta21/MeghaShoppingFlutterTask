import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_shopping_app_task/ProductScreen.dart';
class HomeScreen extends StatefulWidget {
  final String user_id;
  const HomeScreen({super.key, required this.user_id});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override

  void getInitialMessage() async {
    RemoteMessage? message = await FirebaseMessaging.instance.getInitialMessage();

    if(message != null) {

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message.notification!.body!),
          duration: Duration(seconds: 5),
          backgroundColor: Colors.red,
        ));
      }

  }

  @override
  void initState() {
    super.initState();

    getInitialMessage();



    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("App was opened by a notification"),
        duration: Duration(seconds: 10),
        backgroundColor: Colors.green,
      ));
    });
  }
  Widget build(BuildContext context) {
    return Scaffold(
      body: ProductListScreen(user_id: widget.user_id,),
    );
  }
}
