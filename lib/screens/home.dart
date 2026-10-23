import 'package:flutter/material.dart';
import '../app_state.dart';
import '../cloud.dart';
import '../recommender.dart';
import 'assessment.dart';
import 'results.dart';
import 'saved.dart';
import 'profile.dart';
import 'notifications.dart';

// The main screen a student sees after logging in. It holds the bottom
// navigation bar and switches between the four tabs: Home, Results, Saved
// and Profile.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;

  final titles = ['CareerCompass', 'My recommendations', 'Saved careers', 'My profile'];

  // Passed to every tab so a change on one tab (like saving a career)
  // updates the whole screen.
  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (tab == 0) {
      body = DashboardTab(onChanged: refresh);
    } else if (tab == 1) {
      body = ResultsTab(onChanged: refresh);
    } else if (tab == 2) {
      body = SavedTab(onChanged: refresh);
    } else {
      body = ProfileTab(onChanged: refresh);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[tab]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(child: body),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) {
          setState(() {
            tab = i;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.star_outline), label: 'Results'),
          NavigationDestination(icon: Icon(Icons.bookmark_outline), label: 'Saved'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

// The Home tab: a greeting, the student's key numbers, the next step they
// should take (assessment or generating results) and their top match.
class DashboardTab extends StatefulWidget {
  final VoidCallback onChanged;

  const DashboardTab({super.key, required this.onChanged});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    // get the latest notices from Firestore so the count below is correct
    loadNoticesFromCloud().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // Scores every career for this student, stores the run, and tells them
  // how many careers matched.
  void runEngine() {
    var run = getRecommendations(currentStudent);
    runHistory.add(run);
    setState(() {});
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Found ${run.results.length} matching careers')),
    );
  }

  // Compares the top score from this run against the one before it, so the
  // student can see that updating their profile actually changed something.
  String progressText() {
    if (runHistory.length < 2) {
      return '';
    }
    var thisRun = runHistory.last;
    var lastRun = runHistory[runHistory.length - 2];
    // if either run had everything excluded there is no top score to compare
    if (thisRun.results.isEmpty || lastRun.results.isEmpty) {
      return '';
    }
    double now = thisRun.results.first.totalScore;
    double before = lastRun.results.first.totalScore;
    double diff = now - before;
    if (diff > 0.5) {
      return 'Your top match went up by ${diff.toStringAsFixed(0)} points since your last run.';
    }
    if (diff < -0.5) {
      return 'Your top match went down by ${diff.abs().toStringAsFixed(0)} points since your last run.';
    }
    return 'Your top match stayed about the same as your last run.';
  }

  @override
  Widget build(BuildContext context) {
    var run = latestRun;
    String firstName = currentStudent.fullName.split(' ')[0];
    double avg = overallAverage(currentStudent);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        // keeps the page readable on wide screens
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Dark header with the greeting and the two key numbers.
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi $firstName',
                              style: text.headlineMedium?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${currentStudent.qualification} | Year ${currentStudent.yearOfStudy}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.explore, size: 32, color: scheme.secondary),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _heroStat(
                          context,
                          '${avg.toStringAsFixed(0)}%',
                          'Overall average',
                        ),
                      ),
                      Container(width: 1, height: 44, color: Colors.white24),
                      Expanded(
                        child: _heroStat(
                          context,
                          '${currentStudent.academicRecords.length}',
                          'Modules captured',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // the assessment has to be done before there is anything to score
            if (!currentStudent.assessmentDone)
              _actionCard(
                context,
                'Finish your career assessment',
                'Five short steps. We use your answers to score every career in the system.',
                'Start assessment',
                    () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AssessmentScreen()),
                  );
                  setState(() {});
                  widget.onChanged();
                },
              ),

            if (currentStudent.assessmentDone && run == null)
              _actionCard(
                context,
                'Assessment complete',
                'Generate your recommendations to see your matches.',
                'Generate recommendations',
                runEngine,
              ),

            if (run != null) ...[
              Text('Your top match', style: text.titleLarge),
              const SizedBox(height: 8),
              if (run.results.isEmpty)
                const Card(
                  color: Color(0xFFFBEAE8),
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('No careers matched'),
                    subtitle: Text(
                        'Every career was ruled out by the minimum average rules. See Results.'),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _scoreRing(
                          context,
                          run.results.first.totalScore,
                          scheme.secondary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                run.results.first.careerTitle,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Tap Results below to see the full list',
                                style: TextStyle(color: Colors.black54, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (progressText() != '')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    progressText(),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: runEngine,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Run again'),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Runs so far: ${runHistory.length}',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],

            const SizedBox(height: 24),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.campaign_outlined),
              title: const Text('Opportunities and deadlines'),
              subtitle: Text(
                notices.isEmpty ? 'Nothing posted right now' : '${notices.length} notices',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // A number and its label, shown on the dark header.
  Widget _heroStat(BuildContext context, String value, String label) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value, style: text.headlineMedium?.copyWith(color: Colors.white)),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  // A white card with a heading, a sentence and one brass button.
  Widget _actionCard(
      BuildContext context,
      String title,
      String body,
      String buttonLabel,
      VoidCallback onPressed,
      ) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: text.titleLarge),
            const SizedBox(height: 6),
            Text(body, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: scheme.secondary,
                foregroundColor: scheme.onSecondary,
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // The score as a ring that fills once when it appears.
  Widget _scoreRing(BuildContext context, double score, Color color) {
    final scheme = Theme.of(context).colorScheme;
    final reduce = MediaQuery.of(context).disableAnimations;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: (score / 100).clamp(0.0, 1.0)),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                color: color,
                backgroundColor: scheme.outline,
              ),
              Center(
                child: Text(
                  score.toStringAsFixed(0),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 20),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}