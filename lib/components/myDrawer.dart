import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:telsim_attendance/Screen/editEmployee.dart';
import 'package:telsim_attendance/Screen/homeScreen.dart';
import 'package:telsim_attendance/Screen/loginPage.dart';
import '../Functions/fetchstoredetails.dart';
import '../Screen/registerFace.dart';
class Mydrawer extends StatefulWidget {
  final String currentRoute;
  const Mydrawer({super.key, required this.currentRoute});

  @override
  State<Mydrawer> createState() => _MydrawerState();
}

class _MydrawerState extends State<Mydrawer> {
  int? storeActive;
  bool isLoading = true;
  int? role;
  @override
  void initState() {
    super.initState();
    checkRole();
  }
  Future<void> checkRole() async {
    String? userS = await storage.read(key: 'user');
    if (userS == null) return;

    final user = jsonDecode(userS);

    setState(() {
      role = user['role'] as int?; // Direct assignment since it's already an int
      isLoading = false;
    });

    debugPrint('Role loaded: $role');
  }


  @override
  Widget build(BuildContext context) {
    // Store is active, show the drawer as normal
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: const Color(0xFF2C3E50)),
            child:  Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (  role != null && role!=6 && widget.currentRoute != 'home')
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home Screen'),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => Homescreen()),
                      (route) => false,
                );
              },
            ),
          if ( role != null && role!=6 && widget.currentRoute != 'register')
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Register Employee'),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterFace()),
                      (route) => false,
                );
              },
            ),
          if ( role != null &&  role!=6 && widget.currentRoute != 'manage')
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Employee Details'),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => ManageEmployee()),
                    (route) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await LocalStorageService.clear();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => Loginpage()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }


}