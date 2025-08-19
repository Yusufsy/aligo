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
  bool _hidePass = true;
  bool _hideConfirm = true;

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
      final staffId = staffIdCtrl.text.trim();

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(staffId)
          .get();

      if (doc.exists) {
        throw 'اسم المستخدم موجود بالفعل';
      }

      await FirebaseFirestore.instance.collection('users').doc(staffId).set({
        'username': staffId,
        'name': nameCtrl.text.trim(),
        'password': passCtrl.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء الحساب بنجاح')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    staffIdCtrl.dispose();
    nameCtrl.dispose();
    passCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // ✅ Force RTL on this page
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إنشاء حساب'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // اسم المستخدم
                TextFormField(
                  controller: staffIdCtrl,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.badge), // shows on right in RTL
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),

                // الاسم الكامل
                TextFormField(
                  controller: nameCtrl,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),

                // كلمة المرور
                TextFormField(
                  controller: passCtrl,
                  textAlign: TextAlign.right,
                  obscureText: _hidePass,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _hidePass = !_hidePass),
                      icon: Icon(
                          _hidePass ? Icons.visibility : Icons.visibility_off),
                      tooltip: _hidePass ? 'إظهار' : 'إخفاء',
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),

                // تأكيد كلمة المرور
                TextFormField(
                  controller: confirmPassCtrl,
                  textAlign: TextAlign.right,
                  obscureText: _hideConfirm,
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _hideConfirm = !_hideConfirm),
                      icon: Icon(_hideConfirm
                          ? Icons.visibility
                          : Icons.visibility_off),
                      tooltip: _hideConfirm ? 'إظهار' : 'إخفاء',
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _register,
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text('إنشاء حساب'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
