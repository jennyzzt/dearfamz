import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'family_answer_card.dart';

class FamilyFeedToday extends StatefulWidget {
  const FamilyFeedToday({super.key});

  @override
  State<FamilyFeedToday> createState() => _FamilyFeedTodayState();
}

class _FamilyFeedTodayState extends State<FamilyFeedToday> {
  /// A list of today's answers from family members
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _familyAnswersToday = [];

  /// Whether we are currently loading data
  bool _isLoadingAnswers = false;

  /// Cache of userId -> { 'name': ..., 'photoUrl': ... }
  final Map<String, Map<String, String?>> _userCache = {};

  @override
  void initState() {
    super.initState();
    _loadFamilyAnswersToday();
  }

  Future<void> _loadFamilyAnswersToday() async {
    setState(() {
      _isLoadingAnswers = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoadingAnswers = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists || userDoc.data()?['familyMembers'] == null) {
        setState(() {
          _isLoadingAnswers = false;
          _familyAnswersToday = [];
        });
        return;
      }

      final List<String> familyMemberUids =
          List<String>.from(userDoc.data()?['familyMembers'] ?? []);

      if (familyMemberUids.isEmpty) {
        setState(() {
          _isLoadingAnswers = false;
          _familyAnswersToday = [];
        });
        return;
      }

      // Start of today (midnight)
      final todayMidnight = DateTime.now().copyWith(
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
      );

      // Query only today's feed
      final querySnap = await FirebaseFirestore.instance
          .collection('inputfeeds')
          .where('userId', whereIn: familyMemberUids)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayMidnight))
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _familyAnswersToday = querySnap.docs;
      });
    } catch (e) {
      debugPrint('Error loading today’s family answers: $e');
    } finally {
      setState(() {
        _isLoadingAnswers = false;
      });
    }
  }

  /// Fetch user info (name + photoUrl), caching so we only do one doc fetch per user.
  Future<Map<String, String?>> _fetchUserInfo(String userId) async {
    // Check cache first
    if (_userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final data = userDoc.data();
      final name = data?['name'] as String? ?? 'Unknown';
      final photoUrl = data?['photoUrl'] as String? ?? '';

      final result = {'name': name, 'photoUrl': photoUrl};
      _userCache[userId] = result;
      return result;
    } catch (e) {
      debugPrint('Error fetching data for userId $userId: $e');
      return {'name': 'Unknown', 'photoUrl': ''};
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAnswers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_familyAnswersToday.isEmpty) {
      // Show a message that there's no feed for today
      return const Center(
        child: Text('No answers from family members yet.'),
      );
    }

    // Build the list
    return ListView.builder(
      shrinkWrap: true, // so it can be placed in a Column
      physics: const NeverScrollableScrollPhysics(), // disable its own scroll
      itemCount: _familyAnswersToday.length,
      itemBuilder: (context, index) {
        final doc = _familyAnswersToday[index];
        final data = doc.data();

        final question = data['question'] as String? ?? 'No question';
        final answer = data['answer'] as String? ?? 'No answer';
        final createdAt =
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final userId = data['userId'] as String? ?? '';
        final imageUrl = data['imageUrl'] as String? ?? '';

        // We now fetch name+photo in a single shot
        return FutureBuilder<Map<String, String?>>(
          future: _fetchUserInfo(userId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const ListTile(
                title: Text('Loading user info...'),
                subtitle: Text('...'),
              );
            }
            final userInfo = snapshot.data!;
            final userName = userInfo['name'] ?? 'Unknown';
            final photoUrl = userInfo['photoUrl'] ?? '';

            return FamilyAnswerCard(
              question: question,
              answer: answer,
              createdAt: createdAt,
              name: userName,
              photoUrl: photoUrl,
              answerImageUrl: imageUrl,
            );
          },
        );
      },
    );
  }
}
