// The field names here are the same ones we used in the Firestore design in


class Student {
  String fullName = '';
  String email = '';
  String institution = '';
  String qualification = '';
  int yearOfStudy = 1;

  // these four come from the assessment screens
  List<String> interests = [];
  List<String> skills = [];
  String workStyle = '';
  List<String> goals = [];

  List<AcademicRecord> academicRecords = [];

  // profile setup is done once institution/qualification are filled in
  bool get profileDone => institution != '' && qualification != '';

  bool get assessmentDone =>
      interests.isNotEmpty && skills.isNotEmpty && workStyle != '' && goals.isNotEmpty;

  // used by the POPIA screen to show the student everything we hold on them
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'institution': institution,
      'qualification': qualification,
      'yearOfStudy': yearOfStudy,
      'interests': interests,
      'skills': skills,
      'workStyle': workStyle,
      'goals': goals,
      'academicRecords': academicRecords.length,
    };
  }
}

class AcademicRecord {
  String moduleCode;
  String moduleName;
  double mark;
  int year;
  String subjectArea;

  AcademicRecord(this.moduleCode, this.moduleName, this.mark, this.year, this.subjectArea);
}

class Career {
  String careerId;
  String title;
  String description;
  String field;
  List<String> relatedInterests;
  List<String> requiredSkills;
  List<String> relevantSubjectAreas;
  double minimumAverage;
  String workStyle;
  String salaryRange;
  List<String> qualificationsNeeded;
  List<String> goalTags;

  Career({
    required this.careerId,
    required this.title,
    required this.description,
    required this.field,
    required this.relatedInterests,
    required this.requiredSkills,
    required this.relevantSubjectAreas,
    required this.minimumAverage,
    required this.workStyle,
    required this.salaryRange,
    required this.qualificationsNeeded,
    required this.goalTags,
  });
}

// One scored career inside a results run.
class Result {
  int rank;
  String careerId;
  String careerTitle;
  double totalScore;
  Map<String, double> breakdown;
  String explanation;

  Result(this.careerId, this.careerTitle, this.totalScore, this.breakdown)
      : rank = 0,
        explanation = '';
}

class ExcludedCareer {
  String careerId;
  String careerTitle;
  String reason;

  ExcludedCareer(this.careerId, this.careerTitle, this.reason);
}


// document in the recommendations collection.
class RecommendationRun {
  List<Result> results;
  List<ExcludedCareer> excludedCareers;
  DateTime generatedAt;

  RecommendationRun(this.results, this.excludedCareers) : generatedAt = DateTime.now();
}

// One answer to a follow-up check-in: Applied, Not yet or Need help.
class CheckIn {
  String status;
  DateTime date;

  CheckIn(this.status) : date = DateTime.now();
}

class SavedCareer {
  String careerId;
  String careerTitle;
  DateTime savedAt;
  String notes;
  List<CheckIn> checkIns = [];

  SavedCareer(this.careerId, this.careerTitle, this.notes) : savedAt = DateTime.now();

  // latest answer, or empty if the student has not been checked in on yet
  String get latestStatus => checkIns.isEmpty ? '' : checkIns.last.status;

  // the time we measure the next check-in from
  DateTime get lastTouched => checkIns.isEmpty ? savedAt : checkIns.last.date;
}