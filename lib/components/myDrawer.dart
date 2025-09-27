import 'package:flutter/material.dart';
import 'package:telsim_attendance/Screen/homeScreen.dart';
import '../Screen/manageEmp.dart';
import '../Screen/registerFace.dart';

class Mydrawer extends StatelessWidget {
  final String currentRoute;
  const Mydrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.grey[700],),
            child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24,fontWeight: FontWeight.bold)),
          ),
          if (currentRoute != 'home')
          ListTile(
              leading: Icon(Icons.home),
              title: Text('Home Screen'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => Homescreen(),
                ),);
              }
          ),
          if (currentRoute != 'manage')
          ListTile(
              leading: Icon(Icons.manage_accounts),
              title: Text('Manage Employee'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => Manageemp(),
                ),);
              }
          ),
          if (currentRoute != 'register')
          ListTile(
              leading: Icon(Icons.add),
              title: Text('Register Employee'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => RegisterFace(),
                ),);
              }
          ),

        ],
      ),
    );
  }
}
