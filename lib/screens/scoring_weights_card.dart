import 'package:flutter/material.dart';
import '../recommender.dart';

// Shows how much each part counts towards a career's match score.
// The numbers come straight from the recommendation engine, so this
// always matches what the app actually does.
class ScoringWeightsCard extends StatelessWidget {
  const ScoringWeightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final weights = {
      'Interests': interestWeight,
      'Skills': skillWeight,
      'Academic performance': academicWeight,
      'Work style': workStyleWeight,
      'Goals': goalWeight,
    };

    double total = 0;
    for (var w in weights.values) {
      total = total + w;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scoring weights',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            for (var k in weights.keys)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(k),
                trailing: Text(
                  '${weights[k]!.toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                '${total.toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}