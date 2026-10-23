import 'models.dart';
import 'career_data.dart';

// The scoring engine. In the architecture from Deliverable 3 this runs in a
// Cloud Function, but for the prototype it runs on the phone. If it gets moved
// later, getRecommendations() below is the only thing that has to change - the
// screens just call it and use what comes back.

// Out of 100. These are the five factors from the proposal. The assessment
// screen repeats these percentages in its wording, so if one changes here the
// text on that screen has to change too.
const double interestWeight = 30;
const double skillWeight = 25;
const double academicWeight = 20;
const double workStyleWeight = 15;
const double goalWeight = 10;

// what fraction of the career's list the student covers, 0 to 1
double overlap(List<String> studentHas, List<String> careerWants) {
  if (careerWants.isEmpty) {
    return 0;
  }
  int matched = 0;
  for (var item in careerWants) {
    if (studentHas.contains(item)) {
      matched++;
    }
  }
  return matched / careerWants.length;
}

// The items the student and the career have in common, used to name what
// matched in the explanation sentence.
List<String> matchedItems(List<String> studentHas, List<String> careerWants) {
  List<String> found = [];
  for (var item in careerWants) {
    if (studentHas.contains(item)) {
      found.add(item);
    }
  }
  return found;
}

// Joins a list the way a person would say it: "a", "a and b", "a, b and c".
String joinNatural(List<String> items) {
  if (items.length <= 1) {
    return items.join();
  }
  return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
}

// The average of every module mark the student has captured, or 0 if there
// are none yet.
double overallAverage(Student s) {
  if (s.academicRecords.isEmpty) {
    return 0;
  }
  double total = 0;
  for (var r in s.academicRecords) {
    total = total + r.mark;
  }
  return total / s.academicRecords.length;
}

// Average for just the modules that are relevant to this career. The proposal
// said to work out strength per subject area instead of using one overall
// average, so we only fall back to the overall one when the student hasn't done
// any modules in those areas yet.
double subjectAverage(Student s, List<String> areas) {
  double total = 0;
  int count = 0;
  for (var r in s.academicRecords) {
    if (areas.contains(r.subjectArea)) {
      total = total + r.mark;
      count++;
    }
  }
  if (count == 0) {
    return overallAverage(s);
  }
  return total / count;
}

// 40% scores nothing and 85% or better scores full marks. Anything under 40
// comes out negative so it has to be clamped.
double academicScore(double average) {
  double score = (average - 40) / 45;
  if (score < 0) {
    score = 0;
  }
  if (score > 1) {
    score = 1;
  }
  return score;
}

// 1 for the same work style, 0.5 if either side is hybrid, otherwise 0.
double workStyleScore(String studentStyle, String careerStyle) {
  if (studentStyle == careerStyle) {
    return 1;
  }
  // hybrid is half a match either way, someone happy in the office can usually
  // cope with hybrid and the other way around
  if (studentStyle == 'Hybrid' || careerStyle == 'Hybrid') {
    return 0.5;
  }
  return 0;
}

// Builds the sentence on the career detail screen out of the two strongest
// factors, so it names what actually matched instead of being generic.
String buildExplanation(Student s, Career c, Map<String, double> breakdown) {
  // sort the factor names by how much they contributed
  List<String> factors = breakdown.keys.toList();
  factors.sort((a, b) => breakdown[b]!.compareTo(breakdown[a]!));

  List<String> parts = [];
  for (var f in factors) {
    if (breakdown[f]! <= 0) {
      continue;
    }
    if (f == 'Interests') {
      var m = matchedItems(s.interests, c.relatedInterests);
      parts.add('your interest in ${joinNatural(m)}');
    } else if (f == 'Skills') {
      var m = matchedItems(s.skills, c.requiredSkills);
      parts.add('your ${joinNatural(m)} skills');
    } else if (f == 'Academic performance') {
      var avg = subjectAverage(s, c.relevantSubjectAreas);
      parts.add('your ${avg.toStringAsFixed(0)}% average in related modules');
    } else if (f == 'Work style') {
      // only a full match is a "preference"; a hybrid half match is described
      // as a partial fit so the explanation does not overstate it
      if (s.workStyle == c.workStyle) {
        parts.add('your preference for ${s.workStyle.toLowerCase()} work');
      } else {
        parts.add('a partial fit with your preferred way of working');
      }
    } else if (f == 'Goals') {
      var m = matchedItems(s.goals, c.goalTags);
      parts.add('your goal to ${m.first.toLowerCase()}');
    }
    if (parts.length == 2) {
      break;
    }
  }

  if (parts.isEmpty) {
    return 'This career did not match your profile strongly. Try adding more detail to your assessment.';
  }
  return '${c.title} was recommended mainly because of ${parts.join(', and ')}.';
}

// Scores every career for the student. Careers whose minimum average the
// student does not meet go into the excluded list with a reason; the rest are
// scored out of 100, ranked, and given an explanation. This is the one that
// would be swapped out for a call to the Cloud Function.
RecommendationRun getRecommendations(Student s) {
  List<Result> scored = [];
  List<ExcludedCareer> excluded = [];

  for (var c in careers) {
    double relevantAvg = subjectAverage(s, c.relevantSubjectAreas);

    // Rule based part. If the student is below the minimum for this career we
    // don't rank it at all, we put it in the excluded list with a reason. We
    // can only do this check if they have actually captured some marks.
    if (s.academicRecords.isNotEmpty && relevantAvg < c.minimumAverage) {
      String reason = 'Needs an average of ${c.minimumAverage.toStringAsFixed(0)}% in '
          '${c.relevantSubjectAreas.join(', ')}. Yours is currently ${relevantAvg.toStringAsFixed(0)}%.';
      excluded.add(ExcludedCareer(c.careerId, c.title, reason));
      continue;
    }

    // Weighted part. Each factor comes back as 0 to 1 and gets multiplied by
    // its weight, so the five of them add up to a score out of 100.
    Map<String, double> breakdown = {};
    breakdown['Interests'] = overlap(s.interests, c.relatedInterests) * interestWeight;
    breakdown['Skills'] = overlap(s.skills, c.requiredSkills) * skillWeight;
    breakdown['Academic performance'] = academicScore(relevantAvg) * academicWeight;
    breakdown['Work style'] = workStyleScore(s.workStyle, c.workStyle) * workStyleWeight;
    breakdown['Goals'] = overlap(s.goals, c.goalTags) * goalWeight;

    double total = 0;
    for (var v in breakdown.values) {
      total = total + v;
    }

    var result = Result(c.careerId, c.title, total, breakdown);
    result.explanation = buildExplanation(s, c, breakdown);
    scored.add(result);
  }

  // best score first, then number them so rank 1 is the top match
  scored.sort((a, b) => b.totalScore.compareTo(a.totalScore));
  for (int i = 0; i < scored.length; i++) {
    scored[i].rank = i + 1;
  }

  return RecommendationRun(scored, excluded);
}