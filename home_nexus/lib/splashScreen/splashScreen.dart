import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../login/login.dart';

class splashScreen extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _splashScreenState();

}
class _splashScreenState extends State<splashScreen>
{
  void initState(){
    super.initState();
    Timer(Duration(seconds: 3),(){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Login()),);
    });
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size; // Get the size of the screen;
    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        color: Colors.blue,
        child: Center(
            child: Text("welcome",style:TextStyle(
              fontSize: 25,
              color: Colors.white,
            ),)
        ),
      ),
    );
  }
}