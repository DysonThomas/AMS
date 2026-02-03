import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Functions/fetchstoredetails.dart';
import '../Screen/registerFace.dart';
import '../constants.dart';

class UpdateNeededEmployees extends StatefulWidget {
  const UpdateNeededEmployees({super.key});

  @override
  State<UpdateNeededEmployees> createState() => _UpdateNeededEmployeesState();
}

class _UpdateNeededEmployeesState extends State<UpdateNeededEmployees> {
  List<dynamic> employees = [];
  bool isLoading = true;
  void initState() {

    checkEditableEmployees();
  }
  Future<void> checkEditableEmployees() async {
    try {
      final store = await LocalStorageService.getStoreDetails();
      var storeId = store?['storeId'];
      print("storeId: $storeId");

      final url = Uri.parse("$apiBaseUrl/getEmployeesByEditStatus?storeId=$storeId");

      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print("Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            employees = jsonDecode(response.body);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("🔥 Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF2C3E50)),
        ),
      );
    }

    if (employees.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            "No employees to edit",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Table(
            border: TableBorder.all(
              color: const Color(0xFF2C3E50),
              width: 1.5,
              style: BorderStyle.solid,
            ),
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1),
            },
            children: [
              // Header row
              TableRow(
                decoration: const BoxDecoration(
                  color: Color(0xFF2C3E50),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "Name",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "Action",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              // Data rows
              ...employees.map((employee) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        employee['userName'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Center(
                        child: SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2C3E50),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterFace(
                                updateMode: true,
                                employeeId: employee['userID'].toString(),
                                employeeName: employee['userName'],
                              )));
                              print("Edit pressed for: ${employee['userName']}");
                            },
                            child: const Text("Edit"),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
