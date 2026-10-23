import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'app_state.dart';
import 'career_data.dart';
import 'models.dart';

// How long to wait for Firestore before giving up.
const Duration _timeout = Duration(seconds: 10);

// The admin signs in with a real Firebase account that uses this email.
const String adminEmail = 'admin@careercompass.com';

String? get _uid => FirebaseAuth.instance.currentUser?.uid;

// Safe readers: a missing or wrongly typed field gives a default
// instead of crashing the whole load.
String _str(dynamic v) => v is String ? v : '';

int _int(dynamic v, int fallback) => v is num ? v.toInt() : fallback;

double _dbl(dynamic v) => v is num ? v.toDouble() : 0.0;

List<String> _strList(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : <String>[];

// Every function below returns true on success and false on failure.
// Existing code that just awaits them keeps working. If you want to show
// a message when something fails, check the returned value.

// ---------- Student profile ----------

// Saves the current student's profile and academic records.
Future<bool> saveStudent() async {
  final uid = _uid;
  if (uid == null) return true;

  try {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fullName': currentStudent.fullName,
      'email': currentStudent.email,
      'institution': currentStudent.institution,
      'qualification': currentStudent.qualification,
      'yearOfStudy': currentStudent.yearOfStudy,
      'interests': currentStudent.interests,
      'skills': currentStudent.skills,
      'workStyle': currentStudent.workStyle,
      'goals': currentStudent.goals,
      'academicRecords': currentStudent.academicRecords
          .map((r) => {
        'moduleCode': r.moduleCode,
        'moduleName': r.moduleName,
        'mark': r.mark,
        'year': r.year,
        'subjectArea': r.subjectArea,
      })
          .toList(),
    }, SetOptions(merge: true)).timeout(_timeout);
    return true;
  } catch (e) {
    debugPrint('saveStudent failed: $e');
    return false;
  }
}

// Loads the student's profile after login. If they have no saved profile
// yet, the blank one from registration is left alone.
Future<bool> loadStudent() async {
  final uid = _uid;
  if (uid == null) return true;

  try {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get()
        .timeout(_timeout);
    if (!snap.exists) return true;

    final d = snap.data() ?? {};
    final s = Student();
    s.fullName = _str(d['fullName']);
    s.email = _str(d['email']);
    s.institution = _str(d['institution']);
    s.qualification = _str(d['qualification']);
    s.yearOfStudy = _int(d['yearOfStudy'], 1);
    s.interests = _strList(d['interests']);
    s.skills = _strList(d['skills']);
    s.workStyle = _str(d['workStyle']);
    s.goals = _strList(d['goals']);

    final rawRecords = d['academicRecords'];
    if (rawRecords is List) {
      s.academicRecords = rawRecords.whereType<Map>().map((m) {
        return AcademicRecord(
          _str(m['moduleCode']),
          _str(m['moduleName']),
          _dbl(m['mark']),
          _int(m['year'], 0),
          _str(m['subjectArea']),
        );
      }).toList();
    }

    // Only replace the in-memory student once everything parsed cleanly.
    currentStudent = s;
    return true;
  } catch (e) {
    debugPrint('loadStudent failed: $e');
    return false;
  }
}

// ---------- Saved careers ----------

// Saved careers live in users/{uid}/saved, one document per career.
// The check-in answers are stored inside the same document.
Future<bool> saveCareerToCloud(SavedCareer c) async {
  final uid = _uid;
  if (uid == null) return true;

  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('saved')
        .doc(c.careerId)
        .set({
      'careerId': c.careerId,
      'careerTitle': c.careerTitle,
      'notes': c.notes,
      'savedAt': Timestamp.fromDate(c.savedAt),
      'checkIns': c.checkIns
          .map((x) => {
        'status': x.status,
        'date': Timestamp.fromDate(x.date),
      })
          .toList(),
    }).timeout(_timeout);
    return true;
  } catch (e) {
    debugPrint('saveCareerToCloud failed: $e');
    return false;
  }
}

// Removes one saved career from the student's saved list.
Future<bool> removeCareerFromCloud(String careerId) async {
  final uid = _uid;
  if (uid == null) return true;

  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('saved')
        .doc(careerId)
        .delete()
        .timeout(_timeout);
    return true;
  } catch (e) {
    debugPrint('removeCareerFromCloud failed: $e');
    return false;
  }
}

// Loads the student's saved careers after login.
Future<bool> loadSavedCareers() async {
  final uid = _uid;
  if (uid == null) return true;

  try {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('saved')
        .get()
        .timeout(_timeout);

    savedCareers = snap.docs.map((doc) {
      final d = doc.data();
      final id = _str(d['careerId']);
      final c = SavedCareer(
        id.isEmpty ? doc.id : id,
        _str(d['careerTitle']),
        _str(d['notes']),
      );
      final t = d['savedAt'];
      if (t is Timestamp) {
        c.savedAt = t.toDate();
      }

      final raw = d['checkIns'];
      if (raw is List) {
        c.checkIns = raw.whereType<Map>().map((m) {
          final ci = CheckIn(_str(m['status']));
          final when = m['date'];
          if (when is Timestamp) {
            ci.date = when.toDate();
          }
          return ci;
        }).toList();
      }
      return c;
    }).toList();
    return true;
  } catch (e) {
    debugPrint('loadSavedCareers failed: $e');
    return false;
  }
}

// Loads the profile and saved careers at the same time, which is faster
// than awaiting them one after the other. Returns true only if both worked.
Future<bool> loadAllUserData() async {
  final results = await Future.wait([loadStudent(), loadSavedCareers()]);
  return results.every((ok) => ok);
}

// ---------- Careers (the admin manages these) ----------

// Turns a Career into the map that Firestore stores.
Map<String, dynamic> _careerToMap(Career c) {
  return {
    'careerId': c.careerId,
    'title': c.title,
    'description': c.description,
    'field': c.field,
    'relatedInterests': c.relatedInterests,
    'requiredSkills': c.requiredSkills,
    'relevantSubjectAreas': c.relevantSubjectAreas,
    'minimumAverage': c.minimumAverage,
    'workStyle': c.workStyle,
    'salaryRange': c.salaryRange,
    'qualificationsNeeded': c.qualificationsNeeded,
    'goalTags': c.goalTags,
  };
}

// Turns a Firestore document back into a Career.
Career _careerFromMap(String id, Map<String, dynamic> d) {
  return Career(
    careerId: id,
    title: _str(d['title']),
    description: _str(d['description']),
    field: _str(d['field']),
    relatedInterests: _strList(d['relatedInterests']),
    requiredSkills: _strList(d['requiredSkills']),
    relevantSubjectAreas: _strList(d['relevantSubjectAreas']),
    minimumAverage: _dbl(d['minimumAverage']),
    workStyle: _str(d['workStyle']),
    salaryRange: _str(d['salaryRange']),
    qualificationsNeeded: _strList(d['qualificationsNeeded']),
    goalTags: _strList(d['goalTags']),
  );
}

// Replaces the built-in career list with the one in Firestore.
// If Firestore has no careers yet, or the load fails, the built-in list stays.
Future<bool> loadCareersFromCloud() async {
  try {
    final snap = await FirebaseFirestore.instance
        .collection('careers')
        .get()
        .timeout(_timeout);
    if (snap.docs.isEmpty) return true;

    final list =
    snap.docs.map((doc) => _careerFromMap(doc.id, doc.data())).toList();
    list.sort((a, b) => a.careerId.compareTo(b.careerId));
    careers = list;
    return true;
  } catch (e) {
    debugPrint('loadCareersFromCloud failed: $e');
    return false;
  }
}

// True if Firestore already has at least one career. Gives true if it
// cannot tell, so the admin screen does not offer an upload by mistake.
Future<bool> cloudHasCareers() async {
  try {
    final snap = await FirebaseFirestore.instance
        .collection('careers')
        .limit(1)
        .get()
        .timeout(_timeout);
    return snap.docs.isNotEmpty;
  } catch (e) {
    return true;
  }
}

// Creates a career, or overwrites it if the id already exists (used for
// both Add and Edit on the admin form).
Future<bool> saveCareerDoc(Career c) async {
  try {
    await FirebaseFirestore.instance
        .collection('careers')
        .doc(c.careerId)
        .set(_careerToMap(c))
        .timeout(_timeout);
    return true;
  } catch (e) {
    debugPrint('saveCareerDoc failed: $e');
    return false;
  }
}

// Deletes one career from Firestore.
Future<bool> deleteCareerDoc(String careerId) async {
  try {
    await FirebaseFirestore.instance
        .collection('careers')
        .doc(careerId)
        .delete()
        .timeout(_timeout);
    return true;
  } catch (e) {
    debugPrint('deleteCareerDoc failed: $e');
    return false;
  }
}

// Sends every career currently in the app up to Firestore in one go.
// Used once, so the 15 starting careers end up in the database.
Future<bool> uploadAllCareers() async {
  try {
    final batch = FirebaseFirestore.instance.batch();
    for (var c in careers) {
      final ref =
      FirebaseFirestore.instance.collection('careers').doc(c.careerId);
      batch.set(ref, _careerToMap(c));
    }
    await batch.commit().timeout(_timeout);
    return true;
  } catch (e) {
    debugPrint('uploadAllCareers failed: $e');
    return false;
  }
}

// ---------- Notices (the admin posts these) ----------

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _niceDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

// Replaces the built-in notices with the ones in Firestore, newest first.
// If Firestore has none yet, or the load fails, the built-in list stays.
Future<bool> loadNoticesFromCloud() async {
  try {
    final snap = await FirebaseFirestore.instance
        .collection('notices')
        .get()
        .timeout(_timeout);
    if (snap.docs.isEmpty) return true;

    final items = snap.docs.map((doc) {
      final d = doc.data();
      final t = d['createdAt'];
      final made =
      t is Timestamp ? t.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
      final date = _str(d['date']).isEmpty ? _niceDate(made) : _str(d['date']);
      return MapEntry(
        made,
        Notice(_str(d['title']), _str(d['body']), date, _str(d['type']), doc.id),
      );
    }).toList();

    items.sort((a, b) => b.key.compareTo(a.key));
    notices = items.map((e) => e.value).toList();
    return true;
  } catch (e) {
    debugPrint('loadNoticesFromCloud failed: $e');
    return false;
  }
}

// True if Firestore already has at least one notice. Gives true if it
// cannot tell, so the admin screen does not offer an upload by mistake.
Future<bool> cloudHasNotices() async {
  try {
    final snap = await FirebaseFirestore.instance
        .collection('notices')
        .limit(1)
        .get()
        .timeout(_timeout);
    return snap.docs.isNotEmpty;
  } catch (e) {
    return true;
  }
}

// Posts a new notice. Returns the notice (with its id) or null if it failed.
Future<Notice?> addNoticeDoc(String title, String body, String type) async {
  try {
    final now = DateTime.now();
    final date = _niceDate(now);
    final ref = await FirebaseFirestore.instance.collection('notices').add({
      'title': title,
      'body': body,
      'type': type,
      'date': date,
      'createdAt': Timestamp.fromDate(now),
    }).timeout(_timeout);
    return Notice(title, body, date, type, ref.id);
  } catch (e) {
    debugPrint('addNoticeDoc failed: $e');
    return null;
  }
}

// Deletes one notice from Firestore.
Future<bool> deleteNoticeDoc(String id) async {
  try {
    await FirebaseFirestore.instance
        .collection('notices')
        .doc(id)
        .delete()
        .timeout(_timeout);
    return true;
  } catch (e) {
    debugPrint('deleteNoticeDoc failed: $e');
    return false;
  }
}

// Sends the notices currently in the app up to Firestore in one go.
// Used once, so the four starting notices end up in the database.
Future<bool> uploadAllNotices() async {
  try {
    final batch = FirebaseFirestore.instance.batch();
    final refs = <DocumentReference>[];
    final now = DateTime.now();

    for (var i = 0; i < notices.length; i++) {
      final n = notices[i];
      final ref = FirebaseFirestore.instance.collection('notices').doc();
      refs.add(ref);
      batch.set(ref, {
        'title': n.title,
        'body': n.body,
        'type': n.type,
        'date': n.date,
        // keeps the same order they have now
        'createdAt': Timestamp.fromDate(now.subtract(Duration(hours: i))),
      });
    }

    await batch.commit().timeout(_timeout);
    for (var i = 0; i < notices.length; i++) {
      notices[i].id = refs[i].id;
    }
    return true;
  } catch (e) {
    debugPrint('uploadAllNotices failed: $e');
    return false;
  }
}

// ---------- Delete my data (POPIA) ----------

// Deletes everything we hold on the signed-in student: their saved careers
// (which include the check-ins), their profile document, and their login
// account. Returns true if the data was deleted.
Future<bool> deleteMyCloudData() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return true;

  try {
    final userDoc =
    FirebaseFirestore.instance.collection('users').doc(user.uid);

    // the saved careers sit under the profile document, so they go in the same batch
    final saved = await userDoc.collection('saved').get().timeout(_timeout);
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in saved.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(userDoc);
    await batch.commit().timeout(_timeout);
  } catch (e) {
    debugPrint('deleteMyCloudData failed: $e');
    return false;
  }

  // Then the login account. Firebase can refuse this if the student logged in
  // a long time ago. In that case the data is still gone and we just sign out.
  try {
    await user.delete();
  } catch (e) {
    debugPrint('account delete skipped: $e');
  }
  return true;
}