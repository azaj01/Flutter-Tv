import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:tiwee/core/consts.dart';
import 'package:tiwee/core/providers.dart';
import 'package:tiwee/presentation/screens/home/home_page.dart';

/// Minimum time the splash animation stays on screen, so a warm start does not
/// flash past.
const Duration _kMinimumSplashDuration = Duration(milliseconds: 1200);

/// Upper bound on how long the splash waits for data. After this the menu
/// takes over and shows its own loading state, so a slow network can never
/// leave the user staring at the splash.
const Duration _kMaximumSplashDuration = Duration(seconds: 8);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start loading the catalog now instead of when the menu first builds, so
    // the download overlaps the splash animation rather than following it.
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    final minimumDelay = Future<void>.delayed(_kMinimumSplashDuration);

    try {
      await Future.wait([
        ref.read(channelsProvider.future),
        ref.read(categoriesProvider.future),
      ]).timeout(_kMaximumSplashDuration);
    } catch (error) {
      // Failures and timeouts both fall through: the menu renders the loading
      // or error state, with a retry, from the same providers.
      debugPrint('Tiwee: catalog not ready when leaving splash ($error)');
    }

    await minimumDelay;
    if (!mounted) return;

    unawaited(
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (context) => const HomePage()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              kSplashLoading,
              width: width / 4,
            ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              'hmm its time to TV show 😜',
              style: TextStyle(fontSize: 20, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
