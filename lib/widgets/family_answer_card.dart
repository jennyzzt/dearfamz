import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FamilyAnswerCard extends StatelessWidget {
  final String question;
  final String answer;
  final DateTime createdAt;
  final String name;
  final bool showDateInsteadOfTime;
  final String? photoUrl;
  final String? answerImageUrl;

  const FamilyAnswerCard({
    super.key,
    required this.question,
    required this.answer,
    required this.createdAt,
    required this.name,
    this.showDateInsteadOfTime = false,
    this.photoUrl,
    this.answerImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final displayString = showDateInsteadOfTime
        ? DateFormat.yMMMd().format(createdAt)
        : '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // Ensures the card clips its child (the image) to the rounded border
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // adjust corner radius as you like
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --------- TEXT/AVATAR SECTION WITH PADDING ---------
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: avatar + name/time
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                          ? NetworkImage(photoUrl!)
                          : null,
                      backgroundColor: (photoUrl == null || photoUrl!.isEmpty)
                          ? Colors.blue
                          : null,
                      child: (photoUrl == null || photoUrl!.isEmpty)
                          ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          displayString,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Question
                Text(
                  question,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 8),

                // Answer
                Text(
                  answer,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          // --------- OPTIONAL IMAGE FLUSH WITH CARD EDGES ---------
          if (answerImageUrl != null && answerImageUrl!.isNotEmpty)
            Image.network(
              answerImageUrl!,
              fit: BoxFit.cover,
            ),
        ],
      ),
    );
  }
}
