import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({Key? key}) : super(key: key);

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController staffIdCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final TextEditingController confirmPassCtrl = TextEditingController();
  bool isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (passCtrl.text.trim() != confirmPassCtrl.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمات المرور غير متطابقة')),
      );
      return;
    }
    setState(() => isLoading = true);
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(staffIdCtrl.text.trim())
          .get();
      if (doc.exists) {
        throw 'اسم المستخدم موجود بالفعل';
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(staffIdCtrl.text.trim())
          .set({
        'username': staffIdCtrl.text.trim(),
        'name': nameCtrl.text.trim(),
        'password': passCtrl.text.trim(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء الحساب بنجاح')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: staffIdCtrl,
                decoration: const InputDecoration(labelText: 'اسم المستخدم'),
                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'كلمة المرور'),
                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: confirmPassCtrl,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'تأكيد كلمة المرور'),
                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : _register,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('إنشاء حساب'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
