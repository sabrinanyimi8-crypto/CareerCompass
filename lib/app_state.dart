import 'models.dart';

// The data the app holds while it is running.
// Students, saved careers, check-ins, careers and notices are stored in
// Firestore (see cloud.dart) and loaded into these variables after login.

Student currentStudent = Student();

List<SavedCareer> savedCareers = [];

// every time the engine runs we add the result here, so the home screen can
// show whether the top score went up or down after a profile change
List<RecommendationRun> runHistory = [];

RecommendationRun? get latestRun {
  if (runHistory.isEmpty) {
    return null;
  }
  return runHistory.last;
}

bool isSaved(String careerId) {
  for (var s in savedCareers) {
    if (s.careerId == careerId) {
      return true;
    }
  }
  return false;
}

void removeSaved(String careerId) {
  savedCareers.removeWhere((s) => s.careerId == careerId);
}

// Called when the student logs out or deletes their data under POPIA.
void clearEverything() {
  currentStudent = Student();
  savedCareers = [];
  runHistory = [];
}

// One notice posted by the admin. The id is the Firestore document id,
// which the admin screen needs to delete the notice.
class Notice {
  String title;
  String body;
  String date;
  String type;
  String id;

  Notice(this.title, this.body, this.date, this.type, [this.id = '']);
}

// The starting notices. The admin uploads these to Firestore once, and after
// that this list is replaced by whatever is in the database.
List<Notice> notices = [
  Notice(
    'NSFAS applications closing soon',
    'Applications for the next academic year close on 31 January. Make sure your supporting documents are uploaded before the deadline.',
    '12 Oct 2026',
    'Deadline',
  ),
  Notice(
    'Standard Bank IT graduate programme',
    'Applications are open for the 2027 graduate programme. Open to final year IT students with an average above 60%.',
    '08 Oct 2026',
    'Opportunity',
  ),
  Notice(
    'Eduvos career day',
    'Employers will be on the Bedfordview campus on 20 October. Bring a printed CV.',
    '05 Oct 2026',
    'Event',
  ),
  Notice(
    'Women in Tech bursary',
    'Covers tuition and a laptop allowance for female students in IT qualifications. Closing 30 November.',
    '01 Oct 2026',
    'Bursary',
  ),
];