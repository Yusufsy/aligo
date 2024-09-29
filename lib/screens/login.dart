import 'package:aligo/screens/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController unameCntrl = TextEditingController();
  final TextEditingController passCntrl = TextEditingController();
  final String filePath = 'assets/images/emp_names.xlsx';

  Future<void> uploadEmployees() async {
    try {
      // Load the Excel file from assets
      ByteData data = await rootBundle.load(filePath);
      var bytes = data.buffer.asUint8List();
      var excel = Excel.decodeBytes(bytes);

      final firestoreInstance = FirebaseFirestore.instance;

      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table];
        for (var row in sheet!.rows.skip(1)) {
          // Skip header row
          var empNumber = row[0]!.value.toString();
          var empName = row[1]!.value.toString();
          // if (empNumber != null && empName != null) {
          await firestoreInstance.collection('employees').doc(empNumber).set({
            'number': empNumber,
            'name': empName,
          });
          print("Employee Added: $empName");
          // }
        }
      }
    } catch (e) {
      print("Error uploading employees: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      // backgroundColor: const Color(0xFF001522),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Image.asset(
              "assets/images/mof_logo.jpeg",
              height: 200,
              width: 200,
            ),
            const Text(
              'MoF Inventory Disbursement Management System',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: "Roboto", fontSize: 20),
            ),
            SizedBox(
              width: size.width * 0.8,
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: unameCntrl,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.person),
                        hintText: "Enter username",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    TextFormField(
                      controller: passCntrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.password),
                        hintText: "Enter password",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (unameCntrl.text == "admin" &&
                              passCntrl.text == "admin") {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Welcome back')),
                            );
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const MyHomePage()));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Username / password incorrect')),
                            );
                          }
                        }
                      },
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      // floatingActionButton:
      //     FloatingActionButton(onPressed: () async => await uploadEmployees()),
    );
  }
}
