import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiwee/core/providers.dart';
import 'package:tiwee/domain/repositories/i_channel_repository.dart';

/// In-memory preferences for tests.
Future<SharedPreferences> mockPreferences([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

/// Sizes the test viewport, and resets it when the test ends.
///
/// This has to go through tester.view: MediaQuery is built from the view's
/// physicalSize, which binding.setSurfaceSize does not touch. Using that
/// instead left every "portrait" test running at the default 800x600
/// landscape surface, so orientation-dependent layouts were never exercised.
void setViewSize(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Pumps [child] inside a scope with preferences wired up.
///
/// Widgets read favourites and parental settings synchronously, so the
/// preferences override is required almost everywhere.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  Size? surfaceSize,
  SharedPreferences? preferences,
  bool wrapInScaffold = true,
}) async {
  final prefs = preferences ?? await mockPreferences();

  if (surfaceSize != null) {
    setViewSize(tester, surfaceSize);
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        home: wrapInScaffold ? Scaffold(body: child) : child,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

/// A container with preferences wired up, for testing providers directly.
///
/// Pass [channelRepository] to fake the catalog as well.
Future<ProviderContainer> testContainer({
  Map<String, Object> values = const {},
  IChannelRepository? channelRepository,
}) async {
  final prefs = await mockPreferences(values);

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      if (channelRepository != null)
        channelRepositoryProvider.overrideWithValue(channelRepository),
    ],
  );
  addTearDown(container.dispose);
  return container;
}
