import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:telsim_attendance/Screen/homeScreen.dart';
import 'package:telsim_attendance/components/textBox.dart';
import '../constants.dart';
final storage = FlutterSecureStorage();
class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80.0,
        iconTheme: IconThemeData(
          color: Colors.white70,
        ),
        backgroundColor: const Color(0xFF2C3E50),
        title: const Text(
          'Attendo',
          style: TextStyle(fontWeight: FontWeight.bold,
              color: Colors.white70

          ),
        ),
        centerTitle: true,
        elevation: 6,
      ),
      body: Center(
    child: SingleChildScrollView(
    padding: const EdgeInsets.all(24.0),
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,

    children: [
    // Logo / Title
    Text(
    'Login',
    style: TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: Color(0xFF2C3E50),
    ),
    ),
    const SizedBox(height: 30),

      MyTextBox(controller: _emailController, label: 'Enter Email Address'),
    const SizedBox(height: 16),
      MyTextBox(controller: _passwordController, label: 'Enter Password',obscureText: true,),
    // Password

    const SizedBox(height: 24),

    // Login Button
    SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton(
    style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFF2C3E50),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    ),
    ),
     onPressed:  login,
    child: Text(
    'Login',
    style: TextStyle(
    fontSize: 16,
    color: Colors.white,
    ),
    ),
    ),
    ),

    const SizedBox(height: 16),
    ],
    ),
    ),
    ),

    );
  }
  login() async {
  if(_emailController.text.isEmpty|| _passwordController.text.isEmpty){
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please Fill Both Email and Password"))
    );
    return;
  }
    try {
      var url = Uri.parse("$apiBaseUrl/logindashboard");
      var response = await http.post(url, headers: {
        "Content-Type": "application/json",
      },
          body: jsonEncode({
            "email": _emailController.text,
            "password": _passwordController.text,
          })

      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        await saveLoginResponse(decodedResponse);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login Sucessfull")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Homescreen()),
        );

      }
      else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Incorrect Email or Password")),
        );
      }
      else{
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")),
        );
      }
    }
        catch(e) {
          if(!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Connection error: ${e.toString()}")),
          );
        }




  }
  Future<void> saveLoginResponse(Map<String, dynamic> response) async {
    await storage.write(key: 'token', value: response['token']);
    await storage.write(
      key: 'user',
      value: jsonEncode(response['user']),
    );

  }
}
