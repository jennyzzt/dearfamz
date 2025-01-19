import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FamilyAnswerCard extends StatelessWidget {
  final String question;
  final String answer;
  final DateTime createdAt;
  final String name;

  // NEW: Allows you to choose how to display the date/time
  final bool showDateInsteadOfTime;

  const FamilyAnswerCard({
    super.key,
    required this.question,
    required this.answer,
    required this.createdAt,
    required this.name,
    this.showDateInsteadOfTime = false, // default: false => show time
  });

  @override
  Widget build(BuildContext context) {
    // Decide which format to show depending on the boolean
    final displayString = showDateInsteadOfTime
        ? DateFormat.yMMMd().format(createdAt) // e.g. "Jan 19, 2025"
        : '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(answer),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(displayString), // Show date OR time
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
