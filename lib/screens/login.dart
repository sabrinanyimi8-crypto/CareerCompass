import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../recommender.dart';
import '../cloud.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_state.dart';
import 'register.dart';
import 'home.dart';
import 'profile_setup.dart';
import 'admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final emailBox = TextEditingController();
  final passwordBox = TextEditingController();
  String error = '';

  // true while we wait for Firebase, so the button shows a spinner
  bool loading = false;

  // One animation plays when the page opens: the ticks sweep round the
  // ring, then the needle swings and settles pointing north-east.
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final Animation<double> _sweep = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _needle = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
  );

  @override
  void initState() {
    super.initState();
    // Respect the device's "reduce motion" setting.
    final reduce = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (reduce) {
      _anim.value = 1;
    } else {
      _anim.forward();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    emailBox.dispose();
    passwordBox.dispose();
    super.dispose();
  }

  // Called by the Log in button. It turns the spinner on, runs the sign in,
  // and always turns the spinner off again afterwards, even if something fails.
  Future<void> doLogin() async {
    if (loading) return;
    setState(() {
      loading = true;
    });
    try {
      await _signIn();
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // Sends a password reset link to the email typed in the box.
  Future<void> resetPassword() async {
    final email = emailBox.text.trim().toLowerCase();

    if (email == '') {
      setState(() {
        error = 'Type your email above first, then tap Forgot password';
      });
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() {
        error = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'If an account exists for $email, a reset link has been sent. '
                'Check your inbox and your spam folder.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'invalid-email') {
          error = 'That email address is not valid';
        } else {
          error = 'Could not send the reset email. Please try again later';
        }
      });
    }
  }

  // Checks the typed details, signs in with Firebase, then sends the user
  // to the admin screen, the home screen or profile setup.
  Future<void> _signIn() async {
    String email = emailBox.text.trim().toLowerCase();
    String password = passwordBox.text;

    if (email == '' || password == '') {
      setState(() {
        error = 'Please enter your email and password';
      });
      return;
    }

    // get the latest careers from Firestore first, so the matching and the
    // admin screen both use the up to date list
    await loadCareersFromCloud();

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'invalid-email') {
          error = 'That email address is not valid';
        } else if (e.code == 'too-many-requests') {
          error = 'Too many attempts. Please try again later';
        } else {
          error = 'Wrong email or password';
        }
      });
      return;
    }

    // the admin is a real Firebase account that goes to the admin screen.
    // We compare the email Firebase actually signed in, not just what was typed.
    final signedInEmail =
    (FirebaseAuth.instance.currentUser?.email ?? email).toLowerCase();

    if (signedInEmail == adminEmail || email == adminEmail) {
      if (!mounted) return;
      setState(() {
        error = '';
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminScreen()),
      );
      return;
    }

    try {
      await loadStudent();
      await loadSavedCareers();
    } catch (e) {
      // if loading fails we carry on with a blank profile
    }
    currentStudent.email = email;
    if (currentStudent.assessmentDone &&
        currentStudent.academicRecords.isNotEmpty) {
      runHistory.add(getRecommendations(currentStudent));
    }

    if (!mounted) return;

    // students who finished profile setup go home, new ones set up first
    if (currentStudent.profileDone) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth >= 860) {
            return _wideLayout(scheme, text);
          }
          return _narrowLayout(scheme, text);
        },
      ),
    );
  }

  // The animated compass: ring, ticks and needle.
  Widget _compass(ColorScheme scheme, double size) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return CustomPaint(
          size: Size(size, size),
          painter: _CompassPainter(
            color: scheme.secondary,
            hole: scheme.primary,
            sweep: _sweep.value,
            needle: _needle.value,
          ),
        );
      },
    );
  }

  List<Widget> _formFields(ColorScheme scheme) {
    return [
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
        onSubmitted: (_) => doLogin(),
        decoration: const InputDecoration(labelText: 'Password'),
      ),
      if (error != '')
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(error, style: TextStyle(color: scheme.error)),
        ),
      const SizedBox(height: 20),
      FilledButton(
        // greyed out while loading so it cannot be tapped twice
        onPressed: loading ? null : doLogin,
        style: FilledButton.styleFrom(
          backgroundColor: scheme.secondary,
          foregroundColor: scheme.onSecondary,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: loading
            ? SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: scheme.onSecondary,
          ),
        )
            : const Text(
          'Log in',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: resetPassword,
        child: const Text('Forgot password?'),
      ),
      TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RegisterScreen()),
          );
        },
        child: const Text("Don't have an account? Register"),
      ),
    ];
  }



  // Phone and narrow windows: dark page, compass on top, form on a card.
  Widget _narrowLayout(ColorScheme scheme, TextTheme text) {
    return ColoredBox(
      color: scheme.primary,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: _compass(scheme, 230)),
                  const SizedBox(height: 16),
                  Text(
                    'CareerCompass',
                    textAlign: TextAlign.center,
                    style: text.headlineMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Find the career that fits your marks',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _formFields(scheme),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Wide windows (laptop, Chrome): big dark compass panel on the left,
  // the form on a light panel on the right.
  Widget _wideLayout(ColorScheme scheme, TextTheme text) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: ColoredBox(
            color: scheme.primary,
            child: LayoutBuilder(
              builder: (context, c) {
                final size = math.min(c.maxWidth, c.maxHeight * 0.85);
                return ClipRect(
                  child: Stack(
                    children: [
                      Positioned(
                        top: -size * 0.05,
                        right: -size * 0.18,
                        child: _compass(scheme, size),
                      ),
                      Positioned(
                        top: 44,
                        left: 56,
                        child: Row(
                          children: [
                            Icon(Icons.explore, size: 28, color: scheme.secondary),
                            const SizedBox(width: 10),
                            Text(
                              'CareerCompass',
                              style: text.titleLarge?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 56,
                        bottom: 64,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Find the career that fits your marks.',
                                style: text.displaySmall?.copyWith(
                                  color: Colors.white,
                                  fontSize: 46,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Career guidance for university students',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Welcome back', style: text.headlineMedium),
                      const SizedBox(height: 6),
                      const Text(
                        'Log in to see your career matches.',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 28),
                      ..._formFields(scheme),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Draws the ring, the tick marks and the needle. `sweep` goes from 0 to 1
// as the ticks appear clockwise from north. `needle` drives the needle's
// swing; it overshoots slightly, which gives the settling wobble.
class _CompassPainter extends CustomPainter {
  final Color color;
  final Color hole;
  final double sweep;
  final double needle;

  _CompassPainter({
    required this.color,
    required this.hole,
    required this.sweep,
    required this.needle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2 - 2;
    final s = sweep.clamp(0.0, 1.0);

    final ring = Paint()
      ..color = color.withValues(alpha: 0.55 * s)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final inner = Paint()
      ..color = color.withValues(alpha: 0.25 * s)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, r, ring);
    canvas.drawCircle(center, r * 0.78, inner);

    // Ticks every 5 degrees, appearing clockwise from north.
    final shown = s * 72;
    for (int i = 0; i < 72; i++) {
      if (i > shown) break;
      final angle = -math.pi / 2 + i * 5 * math.pi / 180;
      final dx = math.cos(angle);
      final dy = math.sin(angle);
      final major = i % 18 == 0;
      final mid = i % 6 == 0;
      final length = major ? r * 0.2 : (mid ? r * 0.12 : r * 0.06);

      final tick = Paint()
        ..color = color.withValues(alpha: major ? 0.8 : 0.4)
        ..strokeWidth = major ? 2 : 1;

      canvas.drawLine(
        Offset(center.dx + dx * r, center.dy + dy * r),
        Offset(center.dx + dx * (r - length), center.dy + dy * (r - length)),
        tick,
      );
    }

    // Needle: spins in, then settles pointing north-east.
    if (needle > 0.01) {
      final angle = -math.pi / 4 + (1 - needle) * 4 * math.pi;
      final dir = Offset(math.cos(angle), math.sin(angle));
      final side = Offset(-dir.dy, dir.dx);
      final tip = r * 0.6;
      final tail = r * 0.28;
      final half = r * 0.07;

      final front = Path()
        ..moveTo(center.dx + dir.dx * tip, center.dy + dir.dy * tip)
        ..lineTo(center.dx + side.dx * half, center.dy + side.dy * half)
        ..lineTo(center.dx - side.dx * half, center.dy - side.dy * half)
        ..close();
      final back = Path()
        ..moveTo(center.dx - dir.dx * tail, center.dy - dir.dy * tail)
        ..lineTo(center.dx + side.dx * half, center.dy + side.dy * half)
        ..lineTo(center.dx - side.dx * half, center.dy - side.dy * half)
        ..close();

      canvas.drawPath(
        back,
        Paint()..color = Colors.white.withValues(alpha: 0.5 * s),
      );
      canvas.drawPath(front, Paint()..color = color);

      canvas.drawCircle(center, r * 0.045, Paint()..color = color);
      canvas.drawCircle(center, r * 0.02, Paint()..color = hole);
    }
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) =>
      old.sweep != sweep ||
          old.needle != needle ||
          old.color != color ||
          old.hole != hole;
}