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
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
