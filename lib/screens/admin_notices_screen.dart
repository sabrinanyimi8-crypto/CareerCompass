import 'package:flutter/material.dart';
import '../app_state.dart';
import '../cloud.dart';

const List<String> noticeTypes = ['Deadline', 'Opportunity', 'Event', 'Bursary'];

const String _failMessage =
    'Could not reach Firestore. Check you are logged in as the admin and the rules are published.';

// The admin's notices screen: post a new notice or delete an old one.
class AdminNoticesScreen extends StatefulWidget {
  const AdminNoticesScreen({super.key});

  @override
  State<AdminNoticesScreen> createState() => _AdminNoticesScreenState();
}

class _AdminNoticesScreenState extends State<AdminNoticesScreen> {
  bool showUpload = false;

  @override
  void initState() {
    super.initState();
    loadNoticesFromCloud().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
    cloudHasNotices().then((has) {
      if (mounted) {
        setState(() {
          showUpload = !has;
        });
      }
    });
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _upload() async {
    final ok = await uploadAllNotices();
    if (!mounted) return;
    if (ok) {
      setState(() {
        showUpload = false;
      });
      _message('Notices uploaded to Firestore');
    } else {
      _message(_failMessage);
    }
  }

  Future<void> _addNotice() async {
    final titleBox = TextEditingController();
    final bodyBox = TextEditingController();
    String type = noticeTypes.first;

    final post = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Post a notice'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleBox,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bodyBox,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var t in noticeTypes)
                        ChoiceChip(
                          label: Text(t),
                          selected: type == t,
                          onSelected: (_) => setLocal(() => type = t),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (titleBox.text.trim().isEmpty || bodyBox.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );

    if (post != true) return;

    final n = await addNoticeDoc(titleBox.text.trim(), bodyBox.text.trim(), type);
    if (!mounted) return;
    if (n == null) {
      _message(_failMessage);
      return;
    }
    setState(() {
      notices.insert(0, n);
    });
  }

  Future<void> _confirmDelete(Notice n) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete notice?'),
        content: Text('"${n.title}" will be removed for all students.'),
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

    if (yes != true) return;

    setState(() {
      notices.remove(n);
    });
    if (n.id.isNotEmpty) {
      final ok = await deleteNoticeDoc(n.id);
      if (!ok && mounted) {
        _message(_failMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin: notices')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNotice,
        icon: const Icon(Icons.add),
        label: const Text('Post notice'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              if (showUpload)
                Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No notices in Firestore yet',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Upload the starting notices so students see them from the database.',
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: _upload,
                          child: const Text('Upload starting notices'),
                        ),
                      ],
                    ),
                  ),
                ),
              Text(
                '${notices.length} notices',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              for (var n in notices)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(
                      n.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${n.type}  |  ${n.date}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(n),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}