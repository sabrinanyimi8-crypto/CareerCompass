import 'app_state.dart';
import 'career_data.dart';
import 'models.dart';
import 'recommender.dart';

// The rule-based answers for the Ask screen. They work out the reply from the
// student's own results using simple rules, so they need no internet and cost
// nothing. The Ask screen uses them when the AI answer is not available.

const String _noResultsYet =
    'I cannot see your results yet. Finish the assessment on the Home tab and '
    'generate your recommendations, then ask me again.';

// Words that appear in several career titles, so on their own they cannot
// tell us which career the student means.
const Set<String> _genericWords = {
  'engineer', 'developer', 'analyst', 'manager', 'administrator', 'designer',
  'tester', 'lecturer', 'application', 'business', 'project', 'mobile',
};

// Small words that are ignored when matching a career title.
const Set<String> _stopWords = {'it', 'and', 'the'};

// True if the question contains any of the keywords.
bool _has(String q, List<String> keywords) {
  for (var k in keywords) {
    if (q.contains(k)) {
      return true;
    }
  }
  return false;
}

// The lowercase words of a career title, for example
// "Cyber Security Analyst" becomes cyber, security, analyst.
List<String> _titleWords(String title) {
  return title
      .toLowerCase()
      .split(RegExp(r'[^a-z]+'))
      .where((w) => w.isNotEmpty && !_stopWords.contains(w))
      .toList();
}

// Works out if the student named a career in their question. First it looks
// for a career whose whole title is in the question. If there is none, it
// looks for a single career that owns one of the words in the question.
Career? _careerMentioned(String q) {
  final qWords = q.split(RegExp(r'[^a-z]+')).where((w) => w.isNotEmpty).toSet();

  for (var c in careers) {
    final words = _titleWords(c.title);
    if (words.isNotEmpty && words.every((w) => qWords.contains(w))) {
      return c;
    }
  }

  Career? only;
  int count = 0;
  for (var c in careers) {
    final words = _titleWords(c.title).where((w) => !_genericWords.contains(w));
    if (words.any((w) => qWords.contains(w))) {
      only = c;
      count++;
    }
  }
  return count == 1 ? only : null;
}

// The student's best match from the latest run, or null if there is none yet.
Result? _topResult() {
  final run = latestRun;
  if (run == null || run.results.isEmpty) {
    return null;
  }
  return run.results.first;
}

// This student's result for one career, or null if it was not scored.
Result? _resultFor(String careerId) {
  final run = latestRun;
  if (run == null) {
    return null;
  }
  for (var r in run.results) {
    if (r.careerId == careerId) {
      return r;
    }
  }
  return null;
}

String _careerAnswer(Career c) {
  var text = '${c.title} (${c.field}): ${c.description}\n\n'
      'Typical salary: ${c.salaryRange}.\n'
      'Qualifications that lead here: ${c.qualificationsNeeded.join(', ')}.';

  final r = _resultFor(c.careerId);
  final run = latestRun;
  if (r != null) {
    text += '\n\nFor you it ranks #${r.rank} with a score of '
        '${r.totalScore.toStringAsFixed(0)} out of 100.';
  } else if (run != null) {
    for (var e in run.excludedCareers) {
      if (e.careerId == c.careerId) {
        text += '\n\nIt is not recommended for you yet. ${e.reason}';
      }
    }
  }
  return text;
}

String _salaryAnswer(Career c, String who) {
  return '$who typically pays ${c.salaryRange}. These are rough figures from '
      'job sites, so use them as a guide only.';
}

String _qualificationsAnswer(Career c) {
  return 'These qualifications lead to ${c.title}: ${c.qualificationsNeeded.join(', ')}.\n\n'
      'It asks for an average of ${c.minimumAverage.toStringAsFixed(0)}% in '
      '${c.relevantSubjectAreas.join(', ')}. Your average in those areas is '
      '${subjectAverage(currentStudent, c.relevantSubjectAreas).toStringAsFixed(0)}%.';
}

String _skillsAnswer(Career c) {
  final missing = c.requiredSkills.where((s) => !currentStudent.skills.contains(s)).toList();
  if (missing.isEmpty) {
    return 'You already picked every skill ${c.title} asks for '
        '(${c.requiredSkills.join(', ')}). Keep building them through module projects and practice.';
  }
  return 'For ${c.title}, employers look for ${c.requiredSkills.join(', ')}. '
      'You have not picked these yet: ${missing.join(', ')}. You can build them '
      'through module projects, short online courses or a part-time job.';
}

String _noticesAnswer() {
  if (notices.isEmpty) {
    return 'There are no notices right now. Check back soon.';
  }
  final lines = notices.take(3).map((n) => '- ${n.title} (${n.type}, ${n.date})').join('\n');
  return 'Here are the latest notices:\n$lines\n\n'
      'Tap the bell icon on the Home screen to read them in full, and always '
      'check the closing date with the institution itself.';
}

String _averageAnswer() {
  final run = latestRun;
  if (run == null) {
    return _noResultsYet;
  }
  final text = 'Your overall average is ${overallAverage(currentStudent).toStringAsFixed(1)}%.';
  if (run.excludedCareers.isEmpty) {
    return '$text You meet the minimum average for every career in the app.';
  }
  final e = run.excludedCareers.first;
  return '$text ${run.excludedCareers.length} career(s) are not recommended yet '
      'because of the minimum average. For example, ${e.careerTitle}: ${e.reason}';
}

String _workStyleAnswer(Career c) {
  final mine = currentStudent.workStyle;
  var text = 'You prefer ${mine.toLowerCase()} work. Your top match, ${c.title}, '
      'is ${c.workStyle.toLowerCase()} work.';
  if (mine == c.workStyle) {
    text += ' That is a full match.';
  } else if (mine == 'Hybrid' || c.workStyle == 'Hybrid') {
    text += ' That counts as a half match.';
  } else {
    text += ' That is a different style, which lowers the score a little.';
  }
  return text;
}

// Works out the reply to one question. The short wait stands in for the time
// an answer takes, so the chat does not feel instant and robotic.
Future<String> ruleBasedAnswer(String question) async {
  await Future.delayed(const Duration(milliseconds: 600));

  final q = question.toLowerCase();
  final words = q.split(RegExp(r'[^a-z]+')).where((w) => w.isNotEmpty).toSet();

  final career = _careerMentioned(q);
  final top = _topResult();
  final topCareer = top == null ? null : findCareer(top.careerId);

  final asksSalary = _has(q, ['salary', 'earn', 'pay', 'paid', 'money', 'income']);
  final asksQualification = _has(q, [
    'qualification', 'degree', 'diploma', 'study', 'course', 'honours', 'certificat',
  ]);
  final asksSkills = _has(q, ['skill', 'missing', 'improve', 'lack', 'gap']);
  final asksNotices = _has(q, [
    'deadline', 'apply', 'application', 'bursary', 'nsfas', 'notice', 'opportunit', 'event',
  ]);
  final asksAverage = _has(q, [
    'average', 'mark', 'requirement', 'minimum', 'qualify', 'excluded', 'not recommended',
  ]);
  final asksWorkStyle = _has(q, ['remote', 'office', 'hybrid', 'work style', 'fieldwork']);
  final asksTop = _has(q, ['top', 'best', 'recommend', 'match', 'why', 'suit', 'fit', 'result']);

  // the student named a career, so answer about that career
  if (career != null) {
    if (asksSalary) return _salaryAnswer(career, career.title);
    if (asksQualification) return _qualificationsAnswer(career);
    if (asksSkills) return _skillsAnswer(career);
    return _careerAnswer(career);
  }

  if (asksNotices) return _noticesAnswer();
  if (asksAverage) return _averageAnswer();

  // everything below needs the student's results
  if (asksSkills || asksSalary || asksQualification || asksWorkStyle || asksTop) {
    if (top == null || topCareer == null) {
      return _noResultsYet;
    }
    if (asksSkills) return _skillsAnswer(topCareer);
    if (asksSalary) return _salaryAnswer(topCareer, 'Your top match, ${topCareer.title},');
    if (asksQualification) return _qualificationsAnswer(topCareer);
    if (asksWorkStyle) return _workStyleAnswer(topCareer);
    return 'Your top match is ${top.careerTitle}, with a score of '
        '${top.totalScore.toStringAsFixed(0)} out of 100.\n\n${top.explanation}';
  }

  if (words.contains('thanks') || words.contains('thank')) {
    return 'You are welcome! Ask me anything else about your results.';
  }
  if (words.contains('hi') || words.contains('hello') || words.contains('hey')) {
    return 'Hi! Ask me about your top match, the skills you are missing, what to '
        'study, salaries or deadlines.';
  }

  return 'I am not sure about that one. I can help with:\n'
      '- your top match and why\n'
      '- skills you are missing\n'
      '- what to study\n'
      '- salaries\n'
      '- deadlines and bursaries\n'
      '- any career by name, like "tell me about a data analyst"';
}