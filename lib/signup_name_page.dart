import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dearfamz/home_page.dart'; 
import 'package:dearfamz/widgets/appbar_ttitle.dart'; // Your custom AppBarTitle widget

class SignUpNamePage extends StatefulWidget {
  final String email;
  final String password;

  const SignUpNamePage({
    super.key,
    required this.email,
    required this.password,
  });

  static route(String email, String password) {
    return MaterialPageRoute(
      builder: (_) => SignUpNamePage(email: email, password: password),
    );
  }

  @override
  State<SignUpNamePage> createState() => _SignUpNamePageState();
}

class _SignUpNamePageState extends State<SignUpNamePage> {
  final nameController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your first name';
    }
    return null;
  }

  Future<void> createUser() async {
    if (!formKey.currentState!.validate()) return;

    try {
      setState(() => isLoading = true);

      // 1. Create user in Firebase Auth with email & password
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      // 2. If successful, create the user doc in Firestore
      final user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'name': nameController.text.trim(),
          'familyMembers': [],
        });
      }

      // 3. Navigate to home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyHomePage()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Unknown error occurred')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use your custom AppBar
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: AppBarTitle(),
      ),
      body: Column(
        children: [
          // Main content is scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(15.0),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    // Top text
                    const Text(
                      'What\'s your first name?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: nameController,
                      validator: validateName,
                      textAlign: TextAlign.center, // Center the cursor & text
                      style: const TextStyle(
                        fontSize: 40,          // Bigger font
                        fontWeight: FontWeight.bold, // Bolded
                      ),
                      decoration: InputDecoration(
                        // Remove "Name" label
                        // Provide an empty label or hint if you prefer
                        hintText: '',
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Additional text below the input
                    const Text(
                      'What your family members call you',
                      textAlign: TextAlign.center,
                        style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            child: SizedBox(
              width: double.infinity,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18.0),
                      ),
                      onPressed: createUser,
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}