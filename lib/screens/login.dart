import 'package:aligo/screens/create_account.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aligo/screens/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController staffIdCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  bool _isLoading = false;

  Future<void> _login() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final staffId = staffIdCtrl.text.trim();
    final password = passCtrl.text.trim();

    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(staffId)
          .get();

      if (!doc.exists) {
        throw 'لم يتم العثور على اسم المستخدم';
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['password'] != password) {
        throw 'كلمة المرور غير صحيحة';
      }

      // ✅ Persist staff id + name for later unlock checks
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentStaffId', staffId);
      await prefs.setString(
          'currentStaffName', (data['name'] ?? '').toString());

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyHomePage()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    staffIdCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Directionality(
      // 🔁 Force RTL for this page
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    'assets/images/mof_logo.jpeg',
                    height: 150,
                    width: 150,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'نظام إدارة شؤون قسم الحاسوب – دائرة الموازنة، وزارة المالية',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Roboto', fontSize: 20),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: size.width * 0.8,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: staffIdCtrl,
                            enabled: !_isLoading,
                            textAlign: TextAlign.right,
                            // ⬅️ right-align Arabic input
                            decoration: const InputDecoration(
                              icon: Icon(Icons.badge),
                              hintText: 'اسم المستخدم',
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'الرجاء إدخال اسم المستخدم'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: passCtrl,
                            enabled: !_isLoading,
                            obscureText: true,
                            textAlign: TextAlign.right,
                            // ⬅️ right-align Arabic input
                            decoration: const InputDecoration(
                              icon: Icon(Icons.lock),
                              hintText: 'كلمة المرور',
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'الرجاء إدخال كلمة المرور'
                                : null,
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Text('تسجيل الدخول'),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const CreateAccountPage(),
                                      ),
                                    ),
                            child: const Text('ليس لديك حساب؟ أنشئ حسابًا'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
