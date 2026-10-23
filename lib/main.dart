import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'push.dart';

// Palette. Brass is the single accent: use it for match scores and the
// main action on a screen, and nowhere else.
const Color spruce = Color(0xFF0B2B2E);
const Color brass = Color(0xFFC9A227);
const Color lagoon = Color(0xFF3A8F9B);
const Color mist = Color(0xFFF4F6F5);
const Color ink = Color(0xFF17252A);
const Color hairline = Color(0xFFD3DCDA);
const Color lagoonTint = Color(0xFFD6ECEF);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // not awaited, so the app opens straight away while the permission
  // pop-up is waiting for an answer
  setUpPush();
  runApp(const CareerCompassApp());
}

ThemeData _buildTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: spruce,
    onPrimary: Colors.white,
    secondary: brass,
    onSecondary: ink,
    tertiary: lagoon,
    onTertiary: Colors.white,
    error: Color(0xFFB3261E),
    onError: Colors.white,
    surface: Colors.white,
    onSurface: ink,
    outline: hairline,
    secondaryContainer: lagoonTint,
    onSecondaryContainer: spruce,
  );

  // Source Sans 3 for body text, Fraunces for headings.
  final base = GoogleFonts.sourceSans3TextTheme(ThemeData.light().textTheme)
      .apply(bodyColor: ink, displayColor: ink);

  TextStyle heading(TextStyle? s, FontWeight w) =>
      GoogleFonts.fraunces(textStyle: s, fontWeight: w, color: ink);

  final textTheme = base.copyWith(
    displayLarge: heading(base.displayLarge, FontWeight.w600),
    displayMedium: heading(base.displayMedium, FontWeight.w600),
    displaySmall: heading(base.displaySmall, FontWeight.w600),
    headlineLarge: heading(base.headlineLarge, FontWeight.w600),
    headlineMedium: heading(base.headlineMedium, FontWeight.w600),
    headlineSmall: heading(base.headlineSmall, FontWeight.w600),
    titleLarge: heading(base.titleLarge, FontWeight.w600),
  );

  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: hairline),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: mist,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: spruce,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.fraunces(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: spruce, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: spruce,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: spruce,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: spruce,
        side: const BorderSide(color: spruce),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: lagoon),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: hairline),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: lagoonTint,
      side: const BorderSide(color: hairline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: lagoonTint,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: spruce,
      linearTrackColor: hairline,
    ),
    dividerTheme: const DividerThemeData(color: hairline, thickness: 1),
  );
}

class CareerCompassApp extends StatelessWidget {
  const CareerCompassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareerCompass',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
      theme: _buildTheme(),
      home: const LoginScreen(),
    );
  }
}