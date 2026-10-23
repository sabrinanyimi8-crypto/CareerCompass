import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../cloud.dart';
import '../recommender.dart';
import 'profile_setup.dart';
import 'assessment.dart';
import 'login.dart';

class ProfileTab extends StatefulWidget {
  final VoidCallback onChanged;

  const ProfileTab({super.key, required this.onChanged});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  void regenerate() {
    runHistory.add(getRecommendations(currentStudent));
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recommendations updated. Check the Results tab.')),
    );
  }

  // POPIA - the student must be able to see exactly what we hold on them.
  void showMyData() {
    var data = currentStudent.toMap();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Information we hold'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.keys.map((key) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('${data[key]}'),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // POPIA - deletes the student's data from Firestore as well as from the app.
  void deleteMyData() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete my data?'),
          content: const Text(
            'This permanently deletes your profile, your marks, your saved careers, '
                'your check-ins and your account. You will be logged out.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(dialogContext);

                // delete online first, while we are still signed in
                final ok = await deleteMyCloudData();
                if (!mounted) return;

                if (!ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not delete your data. Check your connection and try again.',
                      ),
                    ),
                  );
                  return;
                }

                clearEverything();
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              },
              child: const Text('Delete everything'),
            ),
          ],
        );
      },
    );
  }

  // Clears what the app is holding, signs out of Firebase, and goes back
  // to the login screen.
  Future<void> logOut() async {
    clearEverything();
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    var s = currentStudent;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(
                s.fullName == '' ? '?' : s.fullName[0],
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.fullName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(s.email, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        _section('Study details'),
        _row('Institution', s.institution),
        _row('Qualification', s.qualification),
        _row('Year of study', '${s.yearOfStudy}'),
        _row('Modules captured', '${s.academicRecords.length}'),
        _row('Overall average', '${overallAverage(s).toStringAsFixed(1)}%'),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileSetupScreen(editing: true)),
            );
            setState(() {});
            widget.onChanged();
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit study details and marks'),
        ),

        const SizedBox(height: 24),
        _section('My assessment'),
        _row('Interests', s.interests.isEmpty ? 'Not done' : s.interests.join(', ')),
        _row('Skills', s.skills.isEmpty ? 'Not done' : s.skills.join(', ')),
        _row('Work style', s.workStyle == '' ? 'Not done' : s.workStyle),
        _row('Goals', s.goals.isEmpty ? 'Not done' : s.goals.join(', ')),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AssessmentScreen()),
            );
            setState(() {});
            widget.onChanged();
          },
          icon: const Icon(Icons.quiz_outlined),
          label: const Text('Redo my assessment'),
        ),

        const SizedBox(height: 16),
        if (s.assessmentDone)
          FilledButton.icon(
            onPressed: regenerate,
            icon: const Icon(Icons.refresh),
            label: const Text('Regenerate recommendations'),
          ),

        const Divider(height: 36),
        _section('Privacy'),
        const Text(
          'We only collect what is needed to work out your recommendations. Your information is not '
              'shared with employers or recruiters.',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.visibility_outlined),
          title: const Text('See the information we hold'),
          trailing: const Icon(Icons.chevron_right),
          onTap: showMyData,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: const Text('Delete my data', style: TextStyle(color: Colors.red)),
          trailing: const Icon(Icons.chevron_right),
          onTap: deleteMyData,
        ),

        const Divider(height: 36),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.logout),
          title: const Text('Log out'),
          onTap: logOut,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}