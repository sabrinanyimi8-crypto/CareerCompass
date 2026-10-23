import 'package:flutter/material.dart';
import '../cloud.dart';
import '../app_state.dart';
import '../career_data.dart';
import '../recommender.dart';

// The career assessment: five steps, one for each factor the engine scores on
// (interests, skills, academic results, work style and goals). The answers are
// saved to Firestore at the end so the student does not have to redo them.
class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final pages = PageController();
  int step = 0;
  String error = '';

  // true while the answers are saving, so the button shows a spinner and
  // nothing can be tapped twice
  bool saving = false;

  // work on copies so that backing out of the assessment doesn't half change
  // the student's profile
  List<String> chosenInterests = [];
  List<String> chosenSkills = [];
  String chosenWorkStyle = '';
  List<String> chosenGoals = [];

  @override
  void initState() {
    super.initState();
    chosenInterests = List.from(currentStudent.interests);
    chosenSkills = List.from(currentStudent.skills);
    chosenWorkStyle = currentStudent.workStyle;
    chosenGoals = List.from(currentStudent.goals);
  }

  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  // Checks the current step, then moves forward or finishes on the last step.
  void next() {
    if (saving) return;

    // each step has its own minimum, otherwise the scores end up meaningless
    if (step == 0 && chosenInterests.length < 3) {
      setState(() {
        error = 'Pick at least 3 interests';
      });
      return;
    }
    if (step == 1 && chosenSkills.length < 3) {
      setState(() {
        error = 'Pick at least 3 skills';
      });
      return;
    }
    if (step == 3 && chosenWorkStyle == '') {
      setState(() {
        error = 'Choose a work style';
      });
      return;
    }
    if (step == 4 && chosenGoals.isEmpty) {
      setState(() {
        error = 'Pick at least one goal';
      });
      return;
    }

    setState(() {
      error = '';
    });

    if (step == 4) {
      finish();
    } else {
      step++;
      pages.animateToPage(
        step,
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
      );
    }
  }

  // Goes back one step, or leaves the assessment from the first step.
  void back() {
    if (saving) return;

    if (step == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      step--;
      error = '';
    });
    pages.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.ease,
    );
  }

  // Saves the answers to Firestore. Only if that works are the careers scored
  // and the screen closed. If the save fails the old answers are put back and
  // the student can try again.
  Future<void> finish() async {
    // keep the old answers so a failed save can be undone
    final oldInterests = currentStudent.interests;
    final oldSkills = currentStudent.skills;
    final oldWorkStyle = currentStudent.workStyle;
    final oldGoals = currentStudent.goals;

    currentStudent.interests = List.from(chosenInterests);
    currentStudent.skills = List.from(chosenSkills);
    currentStudent.workStyle = chosenWorkStyle;
    currentStudent.goals = List.from(chosenGoals);

    setState(() {
      error = '';
      saving = true;
    });

    // saveStudent gives back false if the save failed
    final ok = await saveStudent();
    if (!mounted) return;

    if (!ok) {
      currentStudent.interests = oldInterests;
      currentStudent.skills = oldSkills;
      currentStudent.workStyle = oldWorkStyle;
      currentStudent.goals = oldGoals;
      setState(() {
        saving = false;
        error = 'Could not save your answers. Check your connection and try again';
      });
      return;
    }

    // score everything straight away so the results tab has something in it
    runHistory.add(getRecommendations(currentStudent));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      // stops the phone's back gesture from leaving while the save is running
      canPop: !saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Assessment - step ${step + 1} of 5'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: saving ? null : back,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              LinearProgressIndicator(value: (step + 1) / 5),
              Expanded(
                child: PageView(
                  controller: pages,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _interestsStep(),
                    _skillsStep(),
                    _academicStep(),
                    _workStyleStep(),
                    _goalsStep(),
                  ],
                ),
              ),
              if (error != '')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(error, style: TextStyle(color: scheme.error)),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: saving ? null : back,
                        child: Text(step == 0 ? 'Cancel' : 'Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        // greyed out while saving so it cannot be tapped twice
                        onPressed: saving ? null : next,
                        child: saving
                            ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: scheme.onPrimary,
                          ),
                        )
                            : Text(step == 4 ? 'See my results' : 'Next'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // The title and explanation at the top of each step.
  Widget _heading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),
      ],
    );
  }

  // One chip per option. Tapping adds or removes it from the list passed in.
  Widget _chips(List<String> options, List<String> chosen) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        bool selected = chosen.contains(option);
        return FilterChip(
          label: Text(option),
          selected: selected,
          onSelected: (value) {
            setState(() {
              if (value) {
                chosen.add(option);
              } else {
                chosen.remove(option);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _interestsStep() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _heading('What are you interested in?', 'This counts for 30% of your score, the most of the five factors.'),
        _chips(interestOptions, chosenInterests),
        const SizedBox(height: 12),
        Text('${chosenInterests.length} selected', style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  Widget _skillsStep() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _heading('Which of these are you good at?', 'Be honest rather than ambitious. This is 25% of your score.'),
        _chips(skillOptions, chosenSkills),
        const SizedBox(height: 12),
        Text('${chosenSkills.length} selected', style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  // Nothing to capture here, the marks come from the profile. This step shows
  // the student what the engine is going to use so the 20% is not a mystery.
  Widget _academicStep() {
    // group the marks by subject area so each area can show its own average
    Map<String, List<double>> byArea = {};
    for (var r in currentStudent.academicRecords) {
      if (!byArea.containsKey(r.subjectArea)) {
        byArea[r.subjectArea] = [];
      }
      byArea[r.subjectArea]!.add(r.mark);
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _heading('Your academic results', 'Taken from the modules on your profile. Worth 20% of your score.'),
        if (byArea.isEmpty)
          const Text('No modules captured. Go to your profile and add some.')
        else
          for (var area in byArea.keys)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(area),
                subtitle: Text('${byArea[area]!.length} module(s)'),
                trailing: Text(
                  '${(byArea[area]!.reduce((a, b) => a + b) / byArea[area]!.length).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        const SizedBox(height: 8),
        Text(
          'Overall average: ${overallAverage(currentStudent).toStringAsFixed(1)}%',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Careers with a minimum average higher than yours will be listed separately instead of '
              'being recommended.',
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }

  Widget _workStyleStep() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _heading('How would you prefer to work?', 'Worth 15% of your score.'),
        // only one of these can be picked, so ChoiceChip instead of the
        // FilterChips used on the other steps
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: workStyleOptions.map((option) {
            return ChoiceChip(
              label: Text(option),
              selected: chosenWorkStyle == option,
              onSelected: (value) {
                setState(() {
                  chosenWorkStyle = option;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const Text(
          'Hybrid counts as a half match against office based or remote careers.',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
      ],
    );
  }

  Widget _goalsStep() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _heading('What matters to you long term?', 'Worth 10% of your score.'),
        _chips(goalOptions, chosenGoals),
        const SizedBox(height: 12),
        Text('${chosenGoals.length} selected', style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}