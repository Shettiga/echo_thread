import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String selectedRole = "Donor";
  bool obscurePassword = true;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> registerUser() async {
  // ✅ 1. Validate input
  if (nameController.text.isEmpty ||
      emailController.text.isEmpty ||
      passwordController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please fill all fields")),
    );
    return;
  }

  try {
    // ✅ 2. Create user
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    // ✅ 3. Store user in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(credential.user!.uid)
        .set({
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'role': selectedRole,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    // ✅ 4. CLOSE KEYBOARD (important)
    FocusScope.of(context).unfocus();

    // ✅ 5. SHOW MESSAGE
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Registration Successful 🎉"),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );

    // ✅ 6. DELAY + NAVIGATION (safe)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    Navigator.pop(context); // go back to login

  } on FirebaseAuthException catch (e) {
    if (!mounted) return;

    String message = "Registration Failed";

    if (e.code == 'email-already-in-use') {
      message = "Email already exists";
    } else if (e.code == 'weak-password') {
      message = "Password should be at least 6 characters";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF81C784)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_add,
                          size: 60, color: Colors.green),
                      const SizedBox(height: 10),

                      const Text(
                        "Create Account",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 20),

                      // 👤 Name
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: "Full Name",
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // 📧 Email
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // 🔒 Password
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // 🎯 Role Dropdown
                      DropdownButtonFormField(
                        value: selectedRole,
                        items: const [
                          DropdownMenuItem(
                              value: "Donor", child: Text("Donor")),
                          DropdownMenuItem(
                              value: "NGO", child: Text("NGO")),
                          DropdownMenuItem(
                              value: "Volunteer",
                              child: Text("Volunteer")),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedRole = value.toString();
                          });
                        },
                        decoration: InputDecoration(
                          labelText: "Select Role",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // 🚀 Register Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: registerUser,
                          style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.green.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Register",
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}