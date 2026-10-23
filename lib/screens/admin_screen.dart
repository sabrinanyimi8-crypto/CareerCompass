import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../career_data.dart';
import '../cloud.dart';
import '../models.dart';
import 'admin_notices_screen.dart';
import 'scoring_weights_card.dart';
import 'login.dart';

const String _cloudFailMessage =
    'Could not reach Firestore. Check you are logged in as the admin and the rules are published.';

// The admin's main screen: a list of every career with edit and delete,
// plus a button to add a new one.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool showUpload = false;

  @override
  void initState() {
    super.initState();
    // if the database has no careers yet, offer to upload the starting ones
    cloudHasCareers().then((has) {
      if (mounted) {
        setState(() {
          showUpload = !has;
        });
      }
    });
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _upload() async {
    final ok = await uploadAllCareers();
    if (!mounted) return;
    if (ok) {
      setState(() {
        showUpload = false;
      });
      _message('Careers uploaded to Firestore');
    } else {
      _message(_cloudFailMessage);
    }
  }

  // Signs out, then clears every screen off the stack and shows a fresh
  // login page, so Back cannot return to the admin screen.
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  Future<void> _openForm(Career? existing) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CareerFormScreen(existing: existing),
      ),
    );
    setState(() {});
  }

  Future<void> _confirmDelete(Career c) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete career?'),
        content: Text('${c.title} will be removed from the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (yes == true) {
      setState(() {
        careers.removeWhere((x) => x.careerId == c.careerId);
        // if a student had saved it, remove it from their saved list too
        removeSaved(c.careerId);
      });
      final ok = await deleteCareerDoc(c.careerId);
      if (!ok && mounted) {
        _message(_cloudFailMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage careers'),
        actions: [
          IconButton(
            tooltip: 'Manage notices',
            icon: const Icon(Icons.campaign_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminNoticesScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(null),
        icon: const Icon(Icons.add),
        label: const Text('Add career'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              if (showUpload)
                Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No careers in Firestore yet',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Upload the starting careers so students see the same list from the database.',
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: _upload,
                          child: const Text('Upload starting careers'),
                        ),
                      ],
                    ),
                  ),
                ),
              const ScoringWeightsCard(),
              const SizedBox(height: 16),
              Text(
                '${careers.length} careers in the app',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              for (var c in careers)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(
                      c.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(c.field),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _openForm(c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(c),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// The add / edit form. If existing is null we are adding a new career,
// otherwise we are changing that one.
class CareerFormScreen extends StatefulWidget {
  final Career? existing;

  const CareerFormScreen({super.key, this.existing});

  @override
  State<CareerFormScreen> createState() => _CareerFormScreenState();
}

class _CareerFormScreenState extends State<CareerFormScreen> {
  final formKey = GlobalKey<FormState>();

  late TextEditingController title;
  late TextEditingController field;
  late TextEditingController description;
  late TextEditingController minAvg;
  late TextEditingController salary;
  late TextEditingController quals;

  late String workStyle;
  late Set<String> interests;
  late Set<String> skills;
  late Set<String> subjects;
  late Set<String> goals;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;

    title = TextEditingController(text: c?.title ?? '');
    field = TextEditingController(text: c?.field ?? '');
    description = TextEditingController(text: c?.description ?? '');
    minAvg = TextEditingController(
      text: c == null ? '50' : c.minimumAverage.toStringAsFixed(0),
    );
    salary = TextEditingController(text: c?.salaryRange ?? '');
    // one qualification per line
    quals = TextEditingController(text: c?.qualificationsNeeded.join('\n') ?? '');

    workStyle = c?.workStyle ?? workStyleOptions.first;
    interests = Set<String>.from(c?.relatedInterests ?? []);
    skills = Set<String>.from(c?.requiredSkills ?? []);
    subjects = Set<String>.from(c?.relevantSubjectAreas ?? []);
    goals = Set<String>.from(c?.goalTags ?? []);
  }

  @override
  void dispose() {
    title.dispose();
    field.dispose();
    description.dispose();
    minAvg.dispose();
    salary.dispose();
    quals.dispose();
    super.dispose();
  }

  // makes the next free id, like c16, c17 and so on
  String _newId() {
    var highest = 0;
    for (var c in careers) {
      final n = int.tryParse(c.careerId.substring(1)) ?? 0;
      if (n > highest) {
        highest = n;
      }
    }
    return 'c${(highest + 1).toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;

    final qualList = quals.text
        .split('\n')
        .map((q) => q.trim())
        .where((q) => q.isNotEmpty)
        .toList();
    final avg = double.parse(minAvg.text.trim());
    final c = widget.existing;
    final Career saved;

    if (c == null) {
      saved = Career(
        careerId: _newId(),
        title: title.text.trim(),
        description: description.text.trim(),
        field: field.text.trim(),
        relatedInterests: interests.toList(),
        requiredSkills: skills.toList(),
        relevantSubjectAreas: subjects.toList(),
        minimumAverage: avg,
        workStyle: workStyle,
        salaryRange: salary.text.trim(),
        qualificationsNeeded: qualList,
        goalTags: goals.toList(),
      );
      careers.add(saved);
    } else {
      c.title = title.text.trim();
      c.description = description.text.trim();
      c.field = field.text.trim();
      c.relatedInterests = interests.toList();
      c.requiredSkills = skills.toList();
      c.relevantSubjectAreas = subjects.toList();
      c.minimumAverage = avg;
      c.workStyle = workStyle;
      c.salaryRange = salary.text.trim();
      c.qualificationsNeeded = qualList;
      c.goalTags = goals.toList();
      saved = c;
    }

    final ok = await saveCareerDoc(saved);
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_cloudFailMessage)),
      );
    }
    Navigator.pop(context);
  }

  String? _required(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please fill this in';
    return null;
  }

  // a row of tappable options, using the same lists the student assessment uses
  // so the matching still lines up
  Widget _chips(String label, List<String> options, Set<String> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var o in options)
              FilterChip(
                label: Text(o),
                selected: selected.contains(o),
                onSelected: (on) {
                  setState(() {
                    if (on) {
                      selected.add(o);
                    } else {
                      selected.remove(o);
                    }
                  });
                },
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final adding = widget.existing == null;

    return Scaffold(
      appBar: AppBar(title: Text(adding ? 'Add career' : 'Edit career')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'Career title',
                    border: OutlineInputBorder(),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: field,
                  decoration: const InputDecoration(
                    labelText: 'Field (for example Software Development)',
                    border: OutlineInputBorder(),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: description,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: minAvg,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minimum average (0 to 100)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').trim());
                    if (n == null || n < 0 || n > 100) {
                      return 'Enter a number between 0 and 100';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: salary,
                  decoration: const InputDecoration(
                    labelText: 'Salary range (for example R20 000 - R40 000 per month)',
                    border: OutlineInputBorder(),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: quals,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Qualifications needed (one per line)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Work style', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var w in workStyleOptions)
                      ChoiceChip(
                        label: Text(w),
                        selected: workStyle == w,
                        onSelected: (_) => setState(() => workStyle = w),
                      ),
                  ],
                ),
                _chips('Related interests', interestOptions, interests),
                _chips('Required skills', skillOptions, skills),
                _chips('Relevant subject areas', subjectAreaOptions, subjects),
                _chips('Goals this career fits', goalOptions, goals),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _save,
                  child: Text(adding ? 'Add career' : 'Save changes'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}