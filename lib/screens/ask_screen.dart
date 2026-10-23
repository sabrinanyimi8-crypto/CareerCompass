import 'package:cloud_functions/cloud_functions.dart'
    show FirebaseFunctions, HttpsCallableOptions;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../recommender.dart';
import '../rule_based_answers.dart';

// A short summary of the student's results, sent along with the question so
// the AI answers about this student. The name and email are never sent.
Map<String, dynamic> _studentSummary() {
  final s = currentStudent;
  final run = latestRun;

  final topMatches = <Map<String, dynamic>>[];
  final notYet = <Map<String, dynamic>>[];
  if (run != null) {
    for (var r in run.results.take(5)) {
      topMatches.add({
        'career': r.careerTitle,
        'score': r.totalScore.round(),
        'why': r.explanation,
      });
    }
    for (var e in run.excludedCareers.take(5)) {
      notYet.add({'career': e.careerTitle, 'reason': e.reason});
    }
  }

  return {
    'qualification': s.qualification,
    'year': s.yearOfStudy,
    'average': double.parse(overallAverage(s).toStringAsFixed(1)),
    'interests': s.interests,
    'skills': s.skills,
    'workStyle': s.workStyle,
    'goals': s.goals,
    'topMatches': topMatches,
    'notRecommendedYet': notYet,
  };
}

// Answers one question. Signed-in students get a real AI answer from the
// Cloud Function (the API key stays on the server). If that fails for any
// reason, it uses the rule-based answers instead, so the screen never breaks.
Future<String> getAnswer(String question) async {
  if (FirebaseAuth.instance.currentUser != null) {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'askCareerCompass',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 25)),
      );
      final result = await callable.call({
        'question': question,
        'profile': _studentSummary(),
      });
      final data = result.data;
      if (data is Map && data['answer'] is String) {
        final answer = (data['answer'] as String).trim();
        if (answer.isNotEmpty) {
          return answer;
        }
      }
    } catch (e) {
      debugPrint('AI answer failed, using rule-based answer: $e');
    }
  }
  return ruleBasedAnswer(question);
}

// One message in the chat.
class _Msg {
  final bool fromUser;
  final String text;
  _Msg(this.fromUser, this.text);
}

// The question screen: a chat where the student can type a question or tap
// one of the suggested ones.
class AskScreen extends StatefulWidget {
  const AskScreen({super.key});

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final List<_Msg> messages = [];
  final TextEditingController controller = TextEditingController();
  final ScrollController scroll = ScrollController();

  // true while an answer is on its way, so the screen shows "Thinking..."
  bool thinking = false;

  final suggestions = const [
    'What is my top match?',
    'What skills am I missing?',
    'What should I study next?',
    'How much could I earn?',
    'Any deadlines coming up?',
  ];

  @override
  void initState() {
    super.initState();
    final first = currentStudent.fullName.trim().split(' ')[0];
    final name = first.isEmpty ? 'there' : first;
    messages.add(_Msg(
      false,
      'Hi $name! Ask me about your career results, or tap one of the questions below.',
    ));
  }

  @override
  void dispose() {
    controller.dispose();
    scroll.dispose();
    super.dispose();
  }

  // keeps the newest message in view
  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> send(String question) async {
    if (question.trim().isEmpty || thinking) return;

    setState(() {
      messages.add(_Msg(true, question.trim()));
      thinking = true;
    });
    controller.clear();
    _scrollDown();

    final answer = await getAnswer(question);
    if (!mounted) return;

    setState(() {
      messages.add(_Msg(false, answer));
      thinking = false;
    });
    _scrollDown();
  }

  Widget _bubble(String text, bool fromUser, ColorScheme scheme) {
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: fromUser ? scheme.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(color: fromUser ? scheme.onPrimary : Colors.black87),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ask CareerCompass')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.all(16),
              children: [
                for (var m in messages) _bubble(m.text, m.fromUser, scheme),
                if (thinking) _bubble('Thinking...', false, scheme),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              children: [
                for (var s in suggestions)
                  ActionChip(
                    label: Text(s),
                    onPressed: thinking ? null : () => send(s),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Type your question',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: send,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: thinking ? null : () => send(controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}