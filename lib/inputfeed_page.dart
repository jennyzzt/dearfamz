import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dearfamz/widgets/appbar_ttitle.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InputFeedPage extends StatefulWidget {
  const InputFeedPage({super.key});

  @override
  State<InputFeedPage> createState() => _InputFeedPageState();
}

class _InputFeedPageState extends State<InputFeedPage> {
  // Question we ask
  final String question = "What is your favourite color?";

  // Controller to capture (or edit) the user’s typed answer
  final TextEditingController _answerController = TextEditingController();

  // State variables
  bool hasAnsweredToday = false;
  bool isLoading = true;

  /// The user’s answer for today (if any)
  String? todaysAnswer;

  /// The Firestore doc ID for today’s answer (needed for editing)
  String? todaysAnswerDocId;

  /// Whether user is currently editing an existing answer
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    _checkIfAnsweredToday();
  }

  /// Check if the user already answered the question "today"
  /// We define "today" as after midnight local time.
  Future<void> _checkIfAnsweredToday() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return; // Not logged in
    }

    final now = DateTime.now();
    // Midnight for "today" (local time)
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
        });
      }
    } catch (e) {
      debugPrint('Error checking if answered today: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
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

    try {
      final docRef = await FirebaseFirestore.instance.collection('inputfeeds').add({
        'question': question,
        'answer': answerText,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _answerController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Response saved!')),
      );

      setState(() {
        hasAnsweredToday = true;
        todaysAnswer = answerText;
        todaysAnswerDocId = docRef.id;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving response: $e')),
      );
    }
  }

  /// Called when the user wants to start editing today's answer.
  void _startEditing() {
    setState(() {
      isEditing = true;
      // Populate the controller with the existing answer for editing
      _answerController.text = todaysAnswer ?? '';
    });
  }

  /// Updates the existing answer in Firestore (when user has already answered).
  Future<void> _updateAnswer(BuildContext context) async {
    if (todaysAnswerDocId == null) {
      return; // Should not happen if we reached this point
    }

    final newAnswer = _answerController.text.trim();
    if (newAnswer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an answer.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('inputfeeds')
          .doc(todaysAnswerDocId)
          .update({'answer': newAnswer});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer updated!')),
      );

      setState(() {
        todaysAnswer = newAnswer;
        isEditing = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating response: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If still loading Firestore data, show a simple progress indicator
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If the user has NOT answered today, show question & "Submit Answer"
    if (!hasAnsweredToday) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: AppBarTitle(),
        ),
        body: Column(
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
                          maxLines: 5,  // Allow up to 5 lines
                          decoration: InputDecoration(
                            labelText: 'Type your answer here',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
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
        ),
      );
    }

    // If user has already answered today:
    //  - Show either a read-only view with "Edit" button
    //  - Or an editable text field with "Save Changes" button
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: AppBarTitle(),
      ),
      body: Column(
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
                              width: double.infinity,
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
                            // 2) Multi-line, box-style text field for "Edit"
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
      ),
    );
  }
}
