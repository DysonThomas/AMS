import 'package:flutter/material.dart';
import 'package:telsim_attendance/Screen/editEmployee.dart';
import 'package:telsim_attendance/Screen/homeScreen.dart';
import '../Functions/fetchstoredetails.dart';
import '../Screen/manageEmp.dart';
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

  @override
  void initState() {
    super.initState();
    _checkStoreStatus();
  }

  Future<void> _checkStoreStatus() async {
    final int? storeStatus = await LocalStorageService.getStoreStatus();
    if (mounted) {
      setState(() {
        storeActive = storeStatus;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (storeActive == 0) {
      // Store is inactive, block access or show a message
      return Drawer(
        backgroundColor: Colors.white,
        child: ListView(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: const Color(0xFF2C3E50)),
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Contact Admin'),
              ),
            ]
        )
      );
    }

    // Store is active, show the drawer as normal
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: const Color(0xFF2C3E50)),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (widget.currentRoute != 'home')
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home Screen'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => Homescreen(),
                ));
              },
            ),
          if (widget.currentRoute != 'register')
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Register Employee'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => RegisterFace(),
                ));
              },
            ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Employee Details'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => ManageEmployee(),
              ));
            },
          ),
        ],
      ),
    );
  }
}