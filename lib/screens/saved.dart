import 'package:flutter/material.dart';
import '../app_state.dart';
import '../career_data.dart';
import '../cloud.dart';
import 'field_icon.dart';

class SavedTab extends StatefulWidget {
  final VoidCallback onChanged;

  const SavedTab({super.key, required this.onChanged});

  @override
  State<SavedTab> createState() => _SavedTabState();
}

class _SavedTabState extends State<SavedTab> {
  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // Lets the student change the note on a saved career, and saves it to Firestore.
  void editNote(int index) {
    final noteBox = TextEditingController(text: savedCareers[index].notes);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit note'),
          content: TextField(controller: noteBox, maxLines: 3),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final saved = savedCareers[index];
                saved.notes = noteBox.text.trim();
                Navigator.pop(dialogContext);
                setState(() {});

                final ok = await saveCareerToCloud(saved);
                if (!mounted) return;
                _message(ok
                    ? 'Note saved'
                    : 'Could not save your note. Check your connection and try again.');
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Removes a saved career from the app and from Firestore.
  Future<void> removeCareer(int index) async {
    final removed = savedCareers[index];
    setState(() {
      savedCareers.removeAt(index);
    });
    widget.onChanged();

    final ok = await removeCareerFromCloud(removed.careerId);
    if (!mounted) return;
    _message(ok
        ? 'Career removed from your saved list'
        : 'Could not remove it online. Check your connection and try again.');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (savedCareers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Nothing saved yet. Open a career from your results and tap the bookmark to keep it here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (int i = 0; i < savedCareers.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // the icon for this career's field, same as the results page
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          fieldIcon(findCareer(savedCareers[i].careerId).field),
                          size: 22,
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              savedCareers[i].careerTitle,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              findCareer(savedCareers[i].careerId).field,
                              style: const TextStyle(color: Colors.black54, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => editNote(i),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => removeCareer(i),
                      ),
                    ],
                  ),
                  if (savedCareers[i].notes != '')
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      color: const Color(0xFFFFFDE7),
                      child: Text(savedCareers[i].notes),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    'Saved ${savedCareers[i].savedAt.day}/${savedCareers[i].savedAt.month}/${savedCareers[i].savedAt.year}',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}