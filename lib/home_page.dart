import 'package:dearfamz/widgets/appbar_ttitle.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dearfamz/login_page.dart';
import 'package:dearfamz/editfamily_page.dart';
import 'package:dearfamz/inputfeed_page.dart';
import 'package:dearfamz/widgets/family_feed.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  /// Signs out the user and navigates back to the login page.
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, LoginPage.route());
  }

  /// Called when the user taps the back/icon in the AppBar (Edit Family).
  void _onEditFamilyMembers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditFamilyPage()),
    );
  }

  /// Called when the user taps "Connect Today".
  void _onConnectToday() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InputFeedPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.group), // or Icons.people_outline, etc.
          tooltip: 'Edit Family Members',
          onPressed: _onEditFamilyMembers,
        ),
        title: AppBarTitle(),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Only keep "Connect Today" in the body
          Center(
            child: ElevatedButton(
              onPressed: _onConnectToday,
              child: const Text('Connect Today'),
            ),
          ),
          const SizedBox(height: 16),

          // The feed of family's answers for today
          const Expanded(
            child: FamilyFeed(),
          ),
        ],
      ),
    );
  }
}