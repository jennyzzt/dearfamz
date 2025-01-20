import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dearfamz/widgets/appbar_ttitle.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ConnectTodayPage extends StatefulWidget {
  const ConnectTodayPage({super.key});

  @override
  State<ConnectTodayPage> createState() => _ConnectTodayPageState();
}

class _ConnectTodayPageState extends State<ConnectTodayPage> {
  // We'll store today's question in a variable. Default/fallback is:
  String question = "What did you eat today?";

  // Controller to capture (or edit) the user’s typed answer
  final TextEditingController _answerController = TextEditingController();

  // State variables
  bool hasAnsweredToday = false;
  bool isLoading = true; // For the initial fetch

  /// Whether we’re currently submitting/saving (to show a loading overlay)
  bool _isSubmitting = false;

  /// The user’s answer for today (if any)
  String? todaysAnswer;

  /// The Firestore doc ID for today’s answer (needed for editing)
  String? todaysAnswerDocId;

  /// Whether user is currently editing an existing answer
  bool isEditing = false;

  // To track the selected image file
  File? _selectedImage;

  // If user already has an image from previous submission, store it here
  String? todaysImageUrl;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  /// Single method to:
  /// 1) Fetch today's question from "questions" collection.
  /// 2) Check if the user has already answered today.
  Future<void> _initPage() async {
    setState(() => isLoading = true);

    // 1) Fetch the question for today
    await _fetchTodaysQuestion();

    // 2) Check if the user has answered today
    await _checkIfAnsweredToday();

    setState(() => isLoading = false);
  }

  /// Fetch the question from Firestore for "today".
  /// If no question doc is found, we keep our fallback question.
  Future<void> _fetchTodaysQuestion() async {
    final now = DateTime.now();
    // "Today" at midnight
    final todayMidnight = DateTime(now.year, now.month, now.day);
    // "Tomorrow" at midnight, for an upper bound
    final tomorrowMidnight = todayMidnight.add(const Duration(days: 1));

    try {
      final query = await FirebaseFirestore.instance
          .collection('questions')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayMidnight))
          .where('createdAt', isLessThan: Timestamp.fromDate(tomorrowMidnight))
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final fetchedQuestion = doc['question'] as String?;
        if (fetchedQuestion != null && fetchedQuestion.isNotEmpty) {
          setState(() {
            question = fetchedQuestion;
          });
        }
      } else {
        // No question doc found; fallback remains
      }
    } catch (e) {
      debugPrint('Error fetching daily question: $e');
    }
  }

  /// Check if the user already answered the question "today".
  Future<void> _checkIfAnsweredToday() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return; // Not logged in
    }

    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    try {
      final query = await FirebaseFirestore.instance
          .collection('inputfeeds')
          .where('userId', isEqualTo: user.uid)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayMidnight))
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        setState(() {
          hasAnsweredToday = true;
          todaysAnswer = doc['answer'];
          todaysAnswerDocId = doc.id;
          todaysImageUrl = doc.data().containsKey('imageUrl') ? doc['imageUrl'] as String? : null;
        });
      }
    } catch (e) {
      debugPrint('Error checking if answered today: $e');
    }
  }

  /// Pick an image using image_picker.
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  /// Saves a **new** user's answer to Firestore (when user has not answered yet).
  Future<void> _saveAnswer(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in.')),
      );
      return;
    }

    final answerText = _answerController.text.trim();
    if (answerText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an answer.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true; // start showing spinner
    });

    try {
      final docRef = await FirebaseFirestore.instance.collection('inputfeeds').add({
        'question': question,
        'answer': answerText,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // If the user picked an image, upload it
      String? imageUrl;
      if (_selectedImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('inputfeeds_images')
            .child('${docRef.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');

        await storageRef.putFile(_selectedImage!);
        imageUrl = await storageRef.getDownloadURL();

        await docRef.update({'imageUrl': imageUrl});
      }

      _answerController.clear();
      setState(() {
        hasAnsweredToday = true;
        todaysAnswer = answerText;
        todaysAnswerDocId = docRef.id;
        todaysImageUrl = imageUrl;
        _selectedImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Response saved!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving response: $e')),
      );
    } finally {
      // Stop spinner whether success or fail
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  /// Called when the user wants to start editing today's answer.
  void _startEditing() {
    setState(() {
      isEditing = true;
      _answerController.text = todaysAnswer ?? '';
    });
  }

  /// Updates the existing answer in Firestore (when user has already answered).
  Future<void> _updateAnswer(BuildContext context) async {
    if (todaysAnswerDocId == null) return;

    final newAnswer = _answerController.text.trim();
    if (newAnswer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an answer.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true; // start showing spinner
    });

    try {
      // If user selected a new image, upload it
      String? imageUrl = todaysImageUrl; // keep existing if none chosen
      if (_selectedImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('inputfeeds_images')
            .child('$todaysAnswerDocId${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(_selectedImage!);
        imageUrl = await storageRef.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('inputfeeds')
          .doc(todaysAnswerDocId)
          .update({
        'answer': newAnswer,
        if (imageUrl != null) 'imageUrl': imageUrl,
      });

      setState(() {
        todaysAnswer = newAnswer;
        todaysImageUrl = imageUrl;
        _selectedImage = null;
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer updated!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating response: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false; // stop spinner
      });
    }
  }

  /// Builds the main body of the page (excluding the loading overlay).
  Widget _buildBody() {
    // If still loading Firestore data (question or answer-check), show a progress indicator
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // If the user has NOT answered today, show question & "Submit Answer"
    if (!hasAnsweredToday) {
      return Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      question,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      // 1) Multi-line, box-style text field
                      child: TextField(
                        controller: _answerController,
                        maxLines: 5, // Allow up to 5 lines
                        decoration: InputDecoration(
                          labelText: 'Type your answer here',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // If an image is chosen, display a preview
                    if (_selectedImage != null)
                      Image.file(
                        _selectedImage!,
                        height: 200,
                      ),
                    const SizedBox(height: 8),
                    // Button to pick image
                    ElevatedButton(
                      onPressed: _pickImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Upload an image (optional)'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Pinned bottom "Submit Answer" button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18.0),
                ),
                onPressed: () => _saveAnswer(context),
                child: const Text(
                  'Submit Answer',
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
      );
    }

    // If user has already answered today:
    //  - Show either a read-only view with "Edit" button
    //  - Or an editable text field with "Save Changes" button
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: !isEditing
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'You have connected today!',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          question,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        // Nicer UI with a Card for the user's answer
                        Card(
                          color: Colors.orange[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Container(
                            width: 300,
                            padding: const EdgeInsets.all(50.0),
                            child: Text(
                              todaysAnswer ?? '',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // If an image was previously uploaded, show it
                        if (todaysImageUrl != null && todaysImageUrl!.isNotEmpty)
                          Image.network(
                            todaysImageUrl!,
                            height: 200,
                          ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          question,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          // Multi-line text field for "Edit"
                          child: TextField(
                            controller: _answerController,
                            maxLines: 5, // Allow up to 5 lines
                            decoration: InputDecoration(
                              labelText: 'Edit your answer here',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Show old image if it exists and no new image chosen
                        if (todaysImageUrl != null &&
                            todaysImageUrl!.isNotEmpty &&
                            _selectedImage == null)
                          Column(
                            children: [
                              const SizedBox(height: 8),
                              Image.network(
                                todaysImageUrl!,
                                height: 200,
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        // OR if the user has picked a new image, show that preview:
                        if (_selectedImage != null)
                          Image.file(_selectedImage!, height: 200),
                        const SizedBox(height: 8),
                        // Button to pick a new image (optional)
                        ElevatedButton(
                          onPressed: _pickImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('Upload a new image (optional)'),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        // Pinned bottom button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18.0),
                backgroundColor: !isEditing ? Colors.grey : Theme.of(context).primaryColor,
              ),
              onPressed: !isEditing ? _startEditing : () => _updateAnswer(context),
              child: Text(
                !isEditing ? 'Edit' : 'Save Changes',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // We’ll return a Scaffold with a Stack that includes the main body +
    // a possible loading overlay if _isSubmitting is true.
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: AppBarTitle(),
      ),
      // Stack to show the body behind a semi-transparent loading overlay if needed
      body: Stack(
        children: [
          // 1) The main body
          _buildBody(),

          // 2) The loading overlay if we are submitting
          if (_isSubmitting)
            Container(
              color: Colors.black54,  // semi-transparent overlay
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
