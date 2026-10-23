import 'package:flutter/material.dart';
import '../cloud.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_state.dart';
import '../models.dart';
import 'profile_setup.dart';

// Sign-up screen: checks the details, creates the Firebase account and
// then sends the new student to profile setup.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameBox = TextEditingController();
  final emailBox = TextEditingController();
  final passwordBox = TextEditingController();
  final confirmBox = TextEditingController();
  String error = '';

  // true while we wait for Firebase, so the button shows a spinner
  bool loading = false;

  @override
  void dispose() {
    nameBox.dispose();
    emailBox.dispose();
    passwordBox.dispose();
    confirmBox.dispose();
    super.dispose();
  }

  // Called by the Register button. It turns the spinner on, runs the sign up,
  // and always turns the spinner off again afterwards, even if something fails.
  Future<void> doRegister() async {
    if (loading) return;
    setState(() {
      loading = true;
    });
    try {
      await _createAccount();
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // Validates the form, creates the Firebase account, saves a blank profile
  // and moves on to profile setup. Any problem shows as a red message.
  Future<void> _createAccount() async {
    String name = nameBox.text.trim();
    String email = emailBox.text.trim().toLowerCase();

    if (name == '' || email == '' || passwordBox.text == '') {
      setState(() {
        error = 'Please fill in all the fields';
      });
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        error = 'That does not look like a valid email address';
      });
      return;
    }
    if (passwordBox.text.length < 6) {
      setState(() {
        error = 'Password must be at least 6 characters';
      });
      return;
    }
    if (passwordBox.text != confirmBox.text) {
      setState(() {
        error = 'The two passwords do not match';
      });
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: passwordBox.text,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'email-already-in-use') {
          error = 'There is already an account with that email';
        } else if (e.code == 'weak-password') {
          error = 'That password is too weak';
        } else if (e.code == 'invalid-email') {
          error = 'That email address is not valid';
        } else if (e.code == 'network-request-failed') {
          error = 'No internet connection. Check your connection and try again';
        } else {
          error = 'Could not create the account. Please try again';
        }
      });
      return;
    }

    // start them off with a blank profile, they fill it in on the next screen
    currentStudent = Student();
    currentStudent.fullName = name;
    currentStudent.email = email;
    try {
      await saveStudent();
    } catch (_) {
      // the profile screen saves again later
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create an account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'We only ask for what we need to work out your recommendations.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameBox,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailBox,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Email address'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordBox,
                obscureText: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmBox,
                obscureText: true,
                onSubmitted: (_) => doRegister(),
                decoration: const InputDecoration(labelText: 'Confirm password'),
              ),
              if (error != '')
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(error, style: TextStyle(color: scheme.error)),
                ),
              const SizedBox(height: 20),
              FilledButton(
                // greyed out while loading so it cannot be tapped twice
                onPressed: loading ? null : doRegister,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: loading
                    ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: scheme.onPrimary,
                  ),
                )
                    : const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}