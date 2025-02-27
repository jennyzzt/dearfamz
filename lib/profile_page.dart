import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:dearfamz/login_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dearfamz/widgets/profile_pic.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  /// Text controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  /// Master switch: Are we currently in "edit" mode for the profile?
  bool _isEditing = false;

  /// We'll store the original text to revert if the user cancels.
  String _originalName = '';
  String _originalEmail = '';

  /// Selected image file (if any).
  File? _selectedImageFile;

  /// Firestore user doc reference.
  DocumentReference<Map<String, dynamic>>? _userDocRef;

  /// For storing the existing PhotoUrl (if any).
  String? _existingPhotoUrl;

  /// Flag to show a loading spinner while saving
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Retrieve the current user’s Firestore doc.
  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserDoc() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('No currently logged in user');
    }
    final docRef =
        FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
    _userDocRef = docRef;
    return docRef.get();
  }

  /// Helper: load image from gallery or camera using image_picker
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pick from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? pickedFile =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      _selectedImageFile = File(pickedFile.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a picture'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? pickedFile =
                      await picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    setState(() {
                      _selectedImageFile = File(pickedFile.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Uploads file to Firebase Storage and returns the download URL
  Future<String> _uploadImage(File imageFile) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      // Create a unique file path in storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pics')
          .child('$userId.jpg');

      // Upload the file
      await ref.putFile(imageFile);

      // Return the download URL
      final downloadURL = await ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      rethrow; // let caller handle
    }
  }

  /// Update Firestore with the new name/email & PhotoUrl
  Future<void> _saveChanges() async {
    if (_userDocRef == null) return;

    setState(() {
      _isSaving = true; // Start showing the loading spinner
    });

    try {
      String? newPhotoUrl = _existingPhotoUrl;

      // If user picked a new image, upload it
      if (_selectedImageFile != null) {
        newPhotoUrl = await _uploadImage(_selectedImageFile!);
      }

      // Update Firestore
      await _userDocRef!.update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'photoUrl': newPhotoUrl ?? '',
      });

      // Update local state
      setState(() {
        _existingPhotoUrl = newPhotoUrl;
        _isEditing = false;
        _selectedImageFile = null; // Reset after saving
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      // Stop showing the loading spinner (in both success & error cases)
      setState(() {
        _isSaving = false;
      });
    }
  }

  /// Cancel editing: revert changes
  void _cancelEditing() {
    setState(() {
      _nameController.text = _originalName;
      _emailController.text = _originalEmail;
      _selectedImageFile = null; // Discard new image if any
      _isEditing = false;
    });
  }

  /// Show a dialog to confirm sign-out
  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(LoginPage.route());
    }
  }

  /// Common style for text fields
  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.black),
      hintText: hint,
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(8.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.black, width: 2.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _getUserDoc(),
        builder: (context, snapshot) {
          // Handle loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Handle errors
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          // If no data, show a placeholder
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User document does not exist'));
          }

          // Extract user data
          final userData = snapshot.data!.data();
          if (userData == null) {
            return const Center(child: Text('No user data found'));
          }

          // Pre-populate the text fields if not already set
          if (_nameController.text.isEmpty) {
            _nameController.text = userData['name'] ?? '';
          }
          if (_emailController.text.isEmpty) {
            _emailController.text = userData['email'] ?? '';
          }

          // Store the existing PhotoUrl (for display if no new pic is selected)
          _existingPhotoUrl ??= userData['photoUrl'];

          // For the circle avatar’s initial:
          final name = _nameController.text;
          final email = _emailController.text;
          final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';

          // We can stack the main UI with a loading overlay
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Pic at the top
                    ProfilePic(
                      radius: 60,
                      selectedImageFile: _selectedImageFile,
                      photoUrl: _existingPhotoUrl,
                      initialLetter: firstLetter,
                      showCameraIcon: _isEditing,
                      onCameraTap: _isEditing ? _pickImage : null,
                    ),
                    const SizedBox(height: 20),

                    // Show different UIs depending on whether we're editing:
                    if (!_isEditing)
                      // --- VIEW MODE (no icons, centered) ---
                      Column(
                        children: [
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 30, // Adjust as desired
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            email,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16, // Adjust as desired
                            ),
                          ),
                        ],
                      )
                    else
                      // --- EDIT MODE (TextFormFields with icons) ---
                      Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: _buildInputDecoration(
                              'Name',
                              Icons.person_outline,
                            ),
                          ),
                          const SizedBox(height: 15),
                          // Non-editable Email Field
                          TextFormField(
                            controller: _emailController,
                            decoration: _buildInputDecoration(
                              'Email (Unchangeable)',
                              Icons.email_outlined,
                            ).copyWith(
                              prefixIcon: Icon(Icons.email_outlined, color: Colors.grey),
                              enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                              borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.grey, width: 2.0),
                              borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            readOnly: true, // Make the field non-editable
                            style: const TextStyle(color: Colors.grey), // Greyed-out text
                          ),
                        ],
                      ),

                    const SizedBox(height: 40),

                    // ---- EDIT / SAVE & CANCEL BUTTONS ----
                    if (!_isEditing)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18.0),
                          ),
                          onPressed: () {
                            // Capture originals before editing
                            _originalName = _nameController.text;
                            _originalEmail = _emailController.text;
                            setState(() {
                              _isEditing = true;
                            });
                          },
                          child: const Text(
                            'Edit',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18.0),
                              ),
                              onPressed: _saveChanges,
                              child: const Text(
                                'Save',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18.0),
                              ),
                              onPressed: _cancelEditing,
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),

                    // ---- SIGN OUT BUTTON ----
                    if (!_isEditing)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 18.0),
                          ),
                          onPressed: _confirmSignOut,
                          child: const Text(
                            'Sign Out',
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // --- LOADING OVERLAY ---
              if (_isSaving)
                // This container covers the entire screen and blocks user input
                Container(
                  color: Colors.black54, // semi-transparent
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
