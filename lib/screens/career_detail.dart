import 'package:flutter/material.dart';
import '../cloud.dart';
import '../app_state.dart';
import '../career_data.dart';
import '../models.dart';
import '../recommender.dart';

// Everything about one recommended career: the score and why it was given,
// the breakdown by factor, the career's details, and the save/remove button.
class CareerDetailScreen extends StatefulWidget {
  final Result result;

  const CareerDetailScreen({super.key, required this.result});

  @override
  State<CareerDetailScreen> createState() => _CareerDetailScreenState();
}

class _CareerDetailScreenState extends State<CareerDetailScreen> {
  // true while a save or remove is running, so the buttons are disabled and
  // a double tap cannot save the same career twice
  bool busy = false;

  // Runs a cloud call and says whether it worked. It counts as failed if the
  // call throws an error or gives back false.
  Future<bool> _cloudWorked(Future<dynamic> Function() action) async {
    try {
      final result = await action();
      return result != false;
    } catch (_) {
      return false;
    }
  }

  void _showFailure(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Saves the career (after asking for an optional note) or removes it if it
  // is already saved. The saved list only changes once Firestore has
  // confirmed, so the screen never shows something that was not stored.
  Future<void> toggleSave() async {
    if (busy) return;
    var r = widget.result;

    // already saved, so this tap means remove
    if (isSaved(r.careerId)) {
      setState(() {
        busy = true;
      });
      final ok = await _cloudWorked(() => removeCareerFromCloud(r.careerId));
      if (!mounted) return;
      if (ok) {
        removeSaved(r.careerId);
      }
      setState(() {
        busy = false;
      });
      if (!ok) {
        _showFailure('Could not remove this career. Check your connection and try again');
      }
      return;
    }

    // not saved yet, so ask for a note first. The dialog gives back the note,
    // or nothing if the student pressed Cancel.
    final noteBox = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save this career'),
          content: TextField(
            controller: noteBox,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'e.g. ask the lecturer about the honours requirement',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, noteBox.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (note == null || !mounted) return;

    setState(() {
      busy = true;
    });
    final newSave = SavedCareer(r.careerId, r.careerTitle, note);
    final ok = await _cloudWorked(() => saveCareerToCloud(newSave));
    if (!mounted) return;
    if (ok) {
      savedCareers.add(newSave);
    }
    setState(() {
      busy = false;
    });
    if (!ok) {
      _showFailure('Could not save this career. Check your connection and try again');
    }
  }

  @override
  Widget build(BuildContext context) {
    var r = widget.result;
    Career c = findCareer(r.careerId);
    bool saved = isSaved(r.careerId);

    // the weight each factor could have scored, used to draw the bars
    Map<String, double> maxes = {
      'Interests': interestWeight,
      'Skills': skillWeight,
      'Academic performance': academicWeight,
      'Work style': workStyleWeight,
      'Goals': goalWeight,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(c.title),
        actions: [
          IconButton(
            icon: Icon(saved ? Icons.bookmark : Icons.bookmark_outline),
            onPressed: busy ? null : toggleSave,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Text(
                  r.totalScore.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                ),
                const Text(' / 100', style: TextStyle(fontSize: 16, color: Colors.black54)),
                const Spacer(),
                Chip(label: Text('Rank #${r.rank}')),
              ],
            ),
            const SizedBox(height: 8),
            Text(c.field, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 20),

            // the explainability part from the proposal - every score has to
            // come with a reason the student can read
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Why this was recommended',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(r.explanation),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Score breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'How each of the five factors contributed.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 12),
            for (var factor in r.breakdown.keys)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(factor)),
                        Text(
                          '${r.breakdown[factor]!.toStringAsFixed(1)} of ${maxes[factor]!.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      // clamped so the bar can never go past empty or full
                      value: (r.breakdown[factor]! / maxes[factor]!).clamp(0.0, 1.0),
                      minHeight: 8,
                    ),
                  ],
                ),
              ),

            const Divider(height: 32),
            const Text('About this career', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(c.description),
            const SizedBox(height: 20),

            _info('Typical salary', c.salaryRange),
            _info('Work style', c.workStyle),
            _info('Minimum average', '${c.minimumAverage.toStringAsFixed(0)}% in ${c.relevantSubjectAreas.join(', ')}'),
            const SizedBox(height: 16),

            const Text(
              'Qualifications that lead here',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (var q in c.qualificationsNeeded)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.school_outlined, size: 20),
                title: Text(q),
              ),
            const SizedBox(height: 16),

            const Text('Skills employers look for', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // a tick for each required skill the student already has
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: c.requiredSkills.map((s) {
                bool has = currentStudent.skills.contains(s);
                return Chip(
                  label: Text(s),
                  avatar: Icon(
                    has ? Icons.check : Icons.remove,
                    size: 16,
                    color: has ? Colors.green : Colors.black38,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              // greyed out while saving so it cannot be tapped twice
              onPressed: busy ? null : toggleSave,
              icon: busy
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
                  : Icon(saved ? Icons.bookmark_remove : Icons.bookmark_add),
              label: Text(saved ? 'Remove from saved' : 'Save this career'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // A label on the left and its value on the right, for the career facts.
  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}