import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiwee/core/consts.dart';
import 'package:tiwee/core/providers.dart';
import 'package:tiwee/core/theme/app_colors.dart';
import 'package:tiwee/presentation/screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Loaded up front so favourites, parental settings and the chosen palette
  // are readable synchronously while widgets build.
  final preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
      child: const TiweeApp(),
    ),
  );
}

class TiweeApp extends ConsumerWidget {
  const TiweeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(ref.watch(themePaletteProvider));

    // The app is dark-only, so the status bar needs light icons on both
    // platforms — the default dark icons were invisible on Android.
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: colors.background,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'Tiwee',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Declaring the dark scheme keeps Material widgets (snack bars,
        // progress indicators, dialogs) readable on the dark background.
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPurple,
          brightness: Brightness.dark,
        ),
        brightness: Brightness.dark,
        textTheme: GoogleFonts.soraTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: colors.background,
        extensions: [colors],
        snackBarTheme: SnackBarThemeData(
          backgroundColor: colors.card,
          contentTextStyle: const TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
