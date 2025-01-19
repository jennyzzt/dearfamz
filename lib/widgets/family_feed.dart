import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'family_answer_card.dart';

class FamilyFeed extends StatefulWidget {
  const FamilyFeed({super.key});

  @override
  State<FamilyFeed> createState() => _FamilyFeedState();
}

class _FamilyFeedState extends State<FamilyFeed> {
  /// A list of today's answers from family members
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _familyAnswers = [];

  /// Whether we are currently loading data
  bool _isLoadingAnswers = false;

  /// Map to cache userId -> email lookups
  final Map<String, String> _emailCache = {};

  @override
  void initState() {
    super.initState();
    _loadFamilyAnswers();
  }

  /// Loads today's answers from all family members
  Future<void> _loadFamilyAnswers() async {
    setState(() {
      _isLoadingAnswers = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoadingAnswers = false;
        });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists || userDoc.data()?['familyMembers'] == null) {
        setState(() {
          _isLoadingAnswers = false;
          _familyAnswers = [];
        });
        return;
      }

      final List<String> familyMemberUids = List<String>.from(userDoc.data()?['familyMembers'] ?? []);

      if (familyMemberUids.isEmpty) {
        setState(() {
          _isLoadingAnswers = false;
          _familyAnswers = [];
        });
        return;
      }

      final todayMidnight = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);

      final querySnap = await FirebaseFirestore.instance
          .collection('inputfeeds')
          .where('userId', whereIn: familyMemberUids)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayMidnight))
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _familyAnswers = querySnap.docs;
      });
    } catch (e) {
      debugPrint('Error loading family answers: $e');
    } finally {
      setState(() {
        _isLoadingAnswers = false;
      });
    }
  }

  Future<String?> _fetchEmail(String userId) async {
    if (_emailCache.containsKey(userId)) {
      return _emailCache[userId];
    }
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final email = userDoc.data()?['email'] as String?;
      if (email != null) {
        _emailCache[userId] = email;
      }
      return email;
    } catch (e) {
      debugPrint('Error fetching email for userId $userId: $e');
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAnswers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_familyAnswers.isEmpty) {
      return const Center(child: Text('No answers from family members yet'));
    }

    return ListView.builder(
      itemCount: _familyAnswers.length,
      itemBuilder: (context, index) {
        final doc = _familyAnswers[index];
        final data = doc.data();

        final question = data['question'] as String? ?? 'No question';
        final answer = data['answer'] as String? ?? 'No answer';
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final userId = data['userId'] as String? ?? '';

        return FutureBuilder<String?>(
          future: _fetchEmail(userId),
          builder: (context, snapshot) {
            final email = snapshot.data ?? 'Loading...';
            return FamilyAnswerCard(
              question: question,
              answer: answer,
              createdAt: createdAt,
              email: email,
            );
          },
        );
      },
    );
  }
}