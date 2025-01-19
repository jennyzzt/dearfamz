import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dearfamz/editfamily_page.dart';
import 'package:dearfamz/inputfeed_page.dart';
import 'package:dearfamz/profile_page.dart';
import 'package:dearfamz/widgets/family_feed_today.dart';
import 'package:dearfamz/widgets/family_feed_allbuttoday.dart';
import 'package:dearfamz/widgets/profile_pic.dart';
import 'package:dearfamz/widgets/appbar_ttitle.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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

  /// Called when the user taps on the Profile icon.
  void _onProfilePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );
  }

  /// Fetch the current user's Firestore doc to get the name
  Future<String> _getUserName() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return '';
    }

    final docRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      return '';
    }

    final data = docSnap.data();
    if (data == null) {
      return '';
    }

    final name = data['name'] as String? ?? '';
    return name;
  }

  /// Helper to create "----- Label -----" style section headers
  Widget _buildSectionHeader(String label) {
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const Expanded(child: Divider(thickness: 1)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.group),
          tooltip: 'Edit Family Members',
          onPressed: _onEditFamilyMembers,
        ),
        title: AppBarTitle(),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // We use a FutureBuilder to get the user's name before building the avatar
          FutureBuilder<String>(
            future: _getUserName(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // While loading, show a placeholder or a spinner
                return const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                // If there's an error, show a fallback
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: GestureDetector(
                    onTap: _onProfilePage,
                    child: const CircleAvatar(
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.error),
                    ),
                  ),
                );
              }

              // Extract the name and get the first letter
              final name = snapshot.data ?? '';
              final firstLetter =
                  name.isNotEmpty ? name[0].toUpperCase() : '?';

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: _onProfilePage,
                  child: ProfilePic(
                    radius: 20, // Smaller radius for the app bar
                    selectedImageFile: null,
                    photoURL: null,
                    initialLetter: firstLetter,
                    showCameraIcon: false,
                    onCameraTap: null,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      /// The main content, which we can scroll.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ---------- TODAY FEED -----------
            _buildSectionHeader("Today's Family Feed"),
            const SizedBox(height: 8),
            const FamilyFeedToday(),
            const SizedBox(height: 24),

            // ---------- ALL TIME FEEDS -----------
            _buildSectionHeader("All Time Feeds"),
            const SizedBox(height: 8),
            const FamilyFeedAllButToday(),
            const SizedBox(height: 60), // extra spacing above the pinned button
          ],
        ),
      ),
      /// Pinned bottom "Connect Today" button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18.0),
              ),
              onPressed: _onConnectToday,
              child: const Text(
                'Connect Today',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
