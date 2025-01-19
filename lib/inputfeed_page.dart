import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Controller to capture the user’s typed answer
  final TextEditingController _answerController = TextEditingController();

  // State variables
  bool hasAnsweredToday = false;
  bool isLoading = true;
  String? todaysAnswer;

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
        setState(() {
          hasAnsweredToday = true;
          // We assume there's only one question, so take the first doc
          todaysAnswer = query.docs.first['answer'];
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

  /// Saves the user's answer to Firestore
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
      await FirebaseFirestore.instance.collection('inputfeeds').add({
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
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving response: $e')),
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

    // If user has answered today, display the question and their answer
    if (hasAnsweredToday) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Connect Today'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  question,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'You have connected today!',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your answer: $todaysAnswer',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Otherwise, show the question and allow submission
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Today'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              question,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _answerController,
              decoration: const InputDecoration(
                labelText: 'Type your answer here',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _saveAnswer(context),
              child: const Text('Submit Answer'),
            ),
          ],
        ),
      ),
    );
  }
}