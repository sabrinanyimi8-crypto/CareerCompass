import 'package:flutter/material.dart';
import '../app_state.dart';
import '../cloud.dart';
import '../models.dart';
import 'ask_screen.dart';

// How long after saving a career before the first check-in shows.
// Duration.zero makes it show straight away, which makes it easy to test.
// For the real app, change it to Duration(days: 3).
const Duration firstCheckInDelay = Duration.zero;

// How long before we ask again if they have not applied yet.
const Duration repeatCheckInDelay = Duration(days: 7);

// Finds the first saved career that is due for a check-in.
SavedCareer? careerDueForCheckIn() {
  for (var s in savedCareers) {
    if (s.latestStatus == 'Applied') continue;
    final wait = s.checkIns.isEmpty ? firstCheckInDelay : repeatCheckInDelay;
    if (DateTime.now().difference(s.lastTouched) >= wait) {
      return s;
    }
  }
  return null;
}

class CheckInSection extends StatefulWidget {
  final VoidCallback onChanged;

  const CheckInSection({super.key, required this.onChanged});

  @override
  State<CheckInSection> createState() => _CheckInSectionState();
}

class _CheckInSectionState extends State<CheckInSection> {
  void _answer(SavedCareer s, String status) {
    setState(() {
      s.checkIns.add(CheckIn(status));
    });
    // save the answer to Firestore
    saveCareerToCloud(s);
    widget.onChanged();

    // if they need help, take them straight to the question screen
    if (status == 'Need help') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AskScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final due = careerDueForCheckIn();
    final answered = savedCareers.where((s) => s.checkIns.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (due != null)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick check-in',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text('Have you applied for ${due.careerTitle} yet?'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () => _answer(due, 'Applied'),
                        child: const Text('Applied'),
                      ),
                      OutlinedButton(
                        onPressed: () => _answer(due, 'Not yet'),
                        child: const Text('Not yet'),
                      ),
                      OutlinedButton(
                        onPressed: () => _answer(due, 'Need help'),
                        child: const Text('Need help'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (answered.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your progress',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  for (var s in answered)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.careerTitle),
                      trailing: Text(
                        s.latestStatus,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}