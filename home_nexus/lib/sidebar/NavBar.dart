import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ListTile(
            title: Text("Seeker"),
            onTap: (){

            },
          ),
          ListTile(
            title: Text("Seller"),
            onTap: (){

            },
          ),
          ListTile(
            title: Text("Contractor"),
            onTap: (){

            },
          ),
        ],
      ),
    );
  }
}
