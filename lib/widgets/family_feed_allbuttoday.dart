import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'family_answer_card.dart';

class FamilyFeedAllButToday extends StatefulWidget {
  const FamilyFeedAllButToday({super.key});

  @override
  State<FamilyFeedAllButToday> createState() => _FamilyFeedAllButTodayState();
}

class _FamilyFeedAllButTodayState extends State<FamilyFeedAllButToday> {
  /// A list of past answers from family members
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _familyAnswersPast = [];
  bool _isLoadingAnswers = false;

  /// Cache user data: userId -> { 'name': ..., 'photoUrl': ... }
  final Map<String, Map<String, String?>> _userCache = {}; // UPDATED

  @override
  void initState() {
    super.initState();
    _loadFamilyAnswersAllButToday();
  }

  Future<void> _loadFamilyAnswersAllButToday() async {
    setState(() => _isLoadingAnswers = true);

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
          _familyAnswersPast = [];
        });
        return;
      }

      final List<String> familyMemberUids =
          List<String>.from(userDoc.data()?['familyMembers'] ?? []);

      if (familyMemberUids.isEmpty) {
        setState(() {
          _isLoadingAnswers = false;
          _familyAnswersPast = [];
        });
        return;
      }

      final todayMidnight = DateTime.now().copyWith(
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
      );

      // Query all older feed
      final querySnap = await FirebaseFirestore.instance
          .collection('inputfeeds')
          .where('userId', whereIn: familyMemberUids)
          .where('createdAt', isLessThan: Timestamp.fromDate(todayMidnight))
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _familyAnswersPast = querySnap.docs;
      });
    } catch (e) {
      debugPrint('Error loading all-but-today’s family answers: $e');
    } finally {
      setState(() => _isLoadingAnswers = false);
    }
  }

  /// Same pattern as above: fetch name + photoUrl, store in cache
  Future<Map<String, String?>> _fetchUserInfo(String userId) async {
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
      debugPrint('Error fetching name for userId $userId: $e');
      return {'name': 'Unknown', 'photoUrl': ''};
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAnswers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_familyAnswersPast.isEmpty) {
      // If empty, that means no older feed
      return const Center(
        child: Text('No answers from family members yet.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true, // so it can be placed in a Column
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _familyAnswersPast.length,
      itemBuilder: (context, index) {
        final doc = _familyAnswersPast[index];
        final data = doc.data();

        final question = data['question'] as String? ?? 'No question';
        final answer = data['answer'] as String? ?? 'No answer';
        final createdAt =
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final userId = data['userId'] as String? ?? '';
        final imageUrl = data['imageUrl'] as String? ?? '';

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
              showDateInsteadOfTime: true,
              answerImageUrl: imageUrl,
            );
          },
        );
      },
    );
  }
}
