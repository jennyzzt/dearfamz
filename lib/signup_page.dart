import 'package:dearfamz/widgets/appbar_ttitle.dart';
import 'package:flutter/material.dart';
import 'package:dearfamz/login_page.dart';
import 'package:dearfamz/signup_name_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  static route() => MaterialPageRoute(
        builder: (context) => const SignUpPage(),
      );

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Validate email
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    return null;
  }

  // Validate password
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  // Move to the next screen (SignUpNamePage) only if email & password are valid
  void goToNamePage() {
    if (!formKey.currentState!.validate()) return;
    Navigator.push(
      context,
      SignUpNamePage.route(
        emailController.text.toLowerCase().trim(),
        passwordController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: AppBarTitle(),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(15.0),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Create an account with\nyour email address',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: emailController,
                      validator: validateEmail,
                      decoration: InputDecoration(
                        // Icon on the left
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: Colors.black,
                        ),
                        hintText: 'Enter email',
                        // Black outline border when not focused
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        // Black outline border when focused
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
                    TextFormField(
                      controller: passwordController,
                      validator: validatePassword,
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.black,
                        ),
                        hintText: 'Enter password',
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
                    const SizedBox(height: 30),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, LoginPage.route());
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                          text: 'Already have an account? ',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                          children: [
                            TextSpan(
                            text: 'Sign In',
                            style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
                      onPressed: goToNamePage,
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