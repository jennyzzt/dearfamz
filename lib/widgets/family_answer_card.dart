import 'package:flutter/material.dart';

class FamilyAnswerCard extends StatelessWidget {
  final String question;
  final String answer;
  final DateTime createdAt;
  final String email;

  const FamilyAnswerCard({
    super.key,
    required this.question,
    required this.answer,
    required this.createdAt,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(answer),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}