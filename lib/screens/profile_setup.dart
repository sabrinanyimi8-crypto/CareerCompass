import 'package:flutter/material.dart';
import '../cloud.dart';
import '../app_state.dart';
import '../models.dart';
import '../career_data.dart';
import 'home.dart';

// Used twice - once after registering, and again from the profile tab when the
// student wants to change something. The editing flag just changes the wording
// and makes the button go back instead of forward.
class ProfileSetupScreen extends StatefulWidget {
  final bool editing;

  const ProfileSetupScreen({super.key, this.editing = false});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final institutionBox = TextEditingController();
  final qualificationBox = TextEditingController();
  int year = 1;
  String error = '';

  // true while the profile is saving, so the button shows a spinner
  bool saving = false;

  @override
  void initState() {
    super.initState();
    institutionBox.text = currentStudent.institution;
    qualificationBox.text = currentStudent.qualification;
    if (currentStudent.yearOfStudy > 0) {
      year = currentStudent.yearOfStudy;
    }
  }

  @override
  void dispose() {
    institutionBox.dispose();
    qualificationBox.dispose();
    super.dispose();
  }

  // Shows a short message at the bottom of the screen.
  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // Shows a mark without a pointless ".0", so 72.0 shows as 72.
  String _markText(double mark) {
    return mark == mark.roundToDouble() ? mark.toStringAsFixed(0) : mark.toString();
  }

  // Asks before removing a module, then shows a message once it is gone.
  Future<void> _confirmDelete(AcademicRecord r) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete module?'),
        content: Text('${r.moduleCode} - ${r.moduleName} will be removed.'),
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
      if (!mounted) return;
      setState(() {
        currentStudent.academicRecords.remove(r);
      });
      _message('Module deleted. Tap Save changes to keep this.');
    }
  }

  // One dialog for both adding a module and editing one.
  // Pass an existing record to edit it, or nothing to add a new one.
  void editRecord([AcademicRecord? existing]) {
    final adding = existing == null;
    // taken here because the dialog has its own context inside the builder
    final messenger = ScaffoldMessenger.of(context);
    final codeBox = TextEditingController(text: existing?.moduleCode ?? '');
    final nameBox = TextEditingController(text: existing?.moduleName ?? '');
    final markBox = TextEditingController(
      text: existing == null ? '' : _markText(existing.mark),
    );
    final yearBox = TextEditingController(
      text: existing == null ? '${DateTime.now().year}' : '${existing.year}',
    );
    String area = (existing != null && subjectAreaOptions.contains(existing.subjectArea))
        ? existing.subjectArea
        : subjectAreaOptions[0];
    String dialogError = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(adding ? 'Add a module' : 'Edit module'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: codeBox,
                      decoration: const InputDecoration(labelText: 'Module code'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameBox,
                      decoration: const InputDecoration(labelText: 'Module name'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: markBox,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Final mark (%)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: yearBox,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Year'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: area,
                      decoration: const InputDecoration(labelText: 'Subject area'),
                      items: subjectAreaOptions.map((a) {
                        return DropdownMenuItem(value: a, child: Text(a));
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          area = value!;
                        });
                      },
                    ),
                    if (dialogError != '')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(dialogError, style: const TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    // the mark comes out of the text field as a string so it has
                    // to be parsed before we can compare it to anything
                    double? mark = double.tryParse(markBox.text.trim());
                    int? recordYear = int.tryParse(yearBox.text.trim());

                    if (codeBox.text.trim() == '' || nameBox.text.trim() == '') {
                      setDialogState(() {
                        dialogError = 'Fill in the module code and name';
                      });
                      return;
                    }
                    if (mark == null || mark < 0 || mark > 100) {
                      setDialogState(() {
                        dialogError = 'Mark must be a number between 0 and 100';
                      });
                      return;
                    }
                    if (recordYear == null ||
                        recordYear < 2000 ||
                        recordYear > DateTime.now().year + 1) {
                      setDialogState(() {
                        dialogError = 'Enter a valid year, for example ${DateTime.now().year}';
                      });
                      return;
                    }

                    if (existing == null) {
                      currentStudent.academicRecords.add(AcademicRecord(
                        codeBox.text.trim().toUpperCase(),
                        nameBox.text.trim(),
                        mark,
                        recordYear,
                        area,
                      ));
                    } else {
                      // change the record in place
                      existing.moduleCode = codeBox.text.trim().toUpperCase();
                      existing.moduleName = nameBox.text.trim();
                      existing.mark = mark;
                      existing.year = recordYear;
                      existing.subjectArea = area;
                    }
                    Navigator.pop(context);
                    setState(() {});
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          adding
                              ? 'Module added. Tap Save changes to keep it.'
                              : 'Module updated. Tap Save changes to keep it.',
                        ),
                      ),
                    );
                  },
                  child: Text(adding ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Checks the form, saves the profile to Firestore, then moves on.
  Future<void> save() async {
    if (saving) return;

    if (institutionBox.text.trim() == '' || qualificationBox.text.trim() == '') {
      setState(() {
        error = 'Please enter your institution and qualification';
      });
      return;
    }
    if (currentStudent.academicRecords.length < 3) {
      setState(() {
        error = 'Add at least 3 modules so we can work out your averages';
      });
      return;
    }

    currentStudent.institution = institutionBox.text.trim();
    currentStudent.qualification = qualificationBox.text.trim();
    currentStudent.yearOfStudy = year;

    setState(() {
      error = '';
      saving = true;
    });

    // saveStudent gives back false if the save failed
    final ok = await saveStudent();
    if (!mounted) return;

    setState(() {
      saving = false;
    });

    if (!ok) {
      setState(() {
        error = 'Could not save your profile. Check your connection and try again';
      });
      return;
    }

    // the message stays visible on the next screen
    _message('Profile saved');

    if (widget.editing) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editing ? 'Edit profile' : 'Set up your profile'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!widget.editing)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Tell us where you study and what you have done so far. Your marks are used to work '
                      'out which careers you already meet the requirements for.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            TextField(
              controller: institutionBox,
              decoration: const InputDecoration(labelText: 'Institution'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qualificationBox,
              decoration: const InputDecoration(labelText: 'Qualification'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: year,
              decoration: const InputDecoration(labelText: 'Year of study'),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1st year')),
                DropdownMenuItem(value: 2, child: Text('2nd year')),
                DropdownMenuItem(value: 3, child: Text('3rd year')),
                DropdownMenuItem(value: 4, child: Text('4th year / Honours')),
              ],
              onChanged: (value) {
                setState(() {
                  year = value!;
                });
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My modules',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => editRecord(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (currentStudent.academicRecords.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No modules captured yet.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            for (var r in currentStudent.academicRecords)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('${r.moduleCode} - ${r.moduleName}'),
                  subtitle: Text('${r.subjectArea} | ${r.year}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_markText(r.mark)}%',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => editRecord(r),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(r),
                      ),
                    ],
                  ),
                ),
              ),
            if (error != '')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(error, style: TextStyle(color: scheme.error)),
              ),
            const SizedBox(height: 20),
            FilledButton(
              // greyed out while saving so it cannot be tapped twice
              onPressed: saving ? null : save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: saving
                  ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: scheme.onPrimary,
                ),
              )
                  : Text(widget.editing ? 'Save changes' : 'Continue'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}