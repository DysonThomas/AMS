import 'package:flutter/material.dart';
import 'package:telsim_attendance/components/EditEmployeesList.dart';

import '../components/myDrawer.dart';

class ManageEmployee extends StatefulWidget {
  const ManageEmployee({super.key});

  @override
  State<ManageEmployee> createState() => _ManageEmployeeState();
}

class _ManageEmployeeState extends State<ManageEmployee> {
  @override

  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Mydrawer(currentRoute: 'manage',),
      appBar: AppBar(
        toolbarHeight: 80.0,
        iconTheme: IconThemeData(
          color: Colors.white70, // 👈 your custom color
        ),
        backgroundColor: const Color(0xFF2C3E50),
        title: const Text(
          'Edit List',
          style: TextStyle(fontWeight: FontWeight.w600,
              color: Colors.white

          ),
        ),
        centerTitle: true,
        elevation: 6,
      ),
      body: Column(
        children: [
          UpdateNeededEmployees(),
        ],
      ),
    );
  }
}
