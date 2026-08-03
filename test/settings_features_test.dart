import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiwee/core/providers.dart';
import 'package:tiwee/core/theme/app_colors.dart';
import 'package:tiwee/core/utils/sleep_timer.dart';
import 'package:tiwee/data/datasources/preferences_store.dart';
import 'package:tiwee/data/datasources/update_checker.dart';
import 'package:tiwee/domain/entities/channel_entity.dart';
import 'package:tiwee/domain/entities/parental_settings.dart';
import 'package:tiwee/domain/repositories/i_channel_repository.dart';

import 'helpers.dart';

ChannelEntity _channel(String id, {bool isNsfw = false}) => ChannelEntity(
      id: id,
      name: id,
      altNames: const [],
      country: 'US',
      categories: const ['general'],
      isNsfw: isNsfw,
      streams: const [StreamEntity(url: 'https://a/live.m3u8', title: 'a')],
    );

class _FakeChannelRepository implements IChannelRepository {
  _FakeChannelRepository(this.channels);

  final List<ChannelEntity> channels;

  @override
  Future<List<ChannelEntity>> getChannels({bool includeNsfw = false}) async =>
      includeNsfw
          ? channels
          : channels.where((channel) => !channel.isNsfw).toList();

  @override
  Future<List<ChannelEntity>> getChannelsByCategory(String categoryId) async =>
      channels;

  @override
  Future<List<ChannelEntity>> getChannelsByCountry(String countryCode) async =>
      channels;

  @override
  Future<ChannelEntity?> getChannelById(String channelId) async => null;

  @override
  Future<void> refresh() async {}
}

/// Serves a canned HTTP response so the update check can be tested offline.
class _CannedAdapter implements HttpClientAdapter {
  _CannedAdapter({required this.statusCode, this.body = ''});

  final int statusCode;
  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioReturning({required int statusCode, String body = ''}) {
  return Dio()..httpClientAdapter = _CannedAdapter(
      statusCode: statusCode,
      body: body,
    );
}

void main() {
  group('favourites', () {
    test('toggling adds, removes, and persists', () async {
      final container = await testContainer();
      final notifier = container.read(favouritesProvider.notifier);

      expect(notifier.toggle('Alpha.us'), isTrue);
      expect(container.read(favouritesProvider), {'Alpha.us'});

      expect(notifier.toggle('Alpha.us'), isFalse);
      expect(container.read(favouritesProvider), isEmpty);
    });

    test('starts from what was saved last run', () async {
      final container = await testContainer(
        values: {
          'favourite_channel_ids': ['Alpha.us', 'Beta.fr'],
        },
      );

      expect(container.read(favouritesProvider), {'Alpha.us', 'Beta.fr'});
      expect(container.read(isFavouriteProvider('Beta.fr')), isTrue);
      expect(container.read(isFavouriteProvider('Gamma.de')), isFalse);
    });

    test('resolves saved ids against the catalog, skipping stale ones',
        () async {
      final container = await testContainer(
        values: {
          'favourite_channel_ids': ['Beta.fr', 'Deleted.xx'],
        },
        channelRepository: _FakeChannelRepository([
          _channel('Alpha.us'),
          _channel('Beta.fr'),
        ]),
      );

      await container.read(channelsProvider.future);
      final saved = container.read(favouriteChannelsProvider).value;

      expect(saved!.map((channel) => channel.id), ['Beta.fr']);
    });
  });

  group('parental control', () {
    test('hides adult channels until the setting is turned on', () async {
      final container = await testContainer(
        channelRepository: _FakeChannelRepository([
          _channel('Alpha.us'),
          _channel('Adult.us', isNsfw: true),
        ]),
      );

      expect(
        (await container.read(channelsProvider.future))
            .map((channel) => channel.id),
        ['Alpha.us'],
      );

      container
          .read(parentalSettingsProvider.notifier)
          .setAllowAdultChannels(allow: true);

      expect(
        (await container.read(channelsProvider.future))
            .map((channel) => channel.id),
        ['Alpha.us', 'Adult.us'],
      );
    });

    // The category and country lists used to call the repository directly,
    // which defaults to hiding adult channels, so the switch did nothing on
    // those two screens.
    test('the switch also reaches the category and country lists', () async {
      final container = await testContainer(
        channelRepository: _FakeChannelRepository([
          _channel('Alpha.us'),
          _channel('Adult.us', isNsfw: true),
        ]),
      );

      Future<List<String>> categoryIds() async =>
          (await container.read(channelsForCategoryProvider('general').future))
              .map((channel) => channel.id)
              .toList();
      Future<List<String>> countryIds() async =>
          (await container.read(channelsForCountryProvider('US').future))
              .map((channel) => channel.id)
              .toList();

      expect(await categoryIds(), ['Alpha.us']);
      expect(await countryIds(), ['Alpha.us']);

      container
          .read(parentalSettingsProvider.notifier)
          .setAllowAdultChannels(allow: true);

      expect(await categoryIds(), ['Alpha.us', 'Adult.us']);
      expect(await countryIds(), ['Alpha.us', 'Adult.us']);
    });

    test('persists the switch and the PIN', () async {
      final container = await testContainer();
      final notifier = container.read(parentalSettingsProvider.notifier)
        ..setAllowAdultChannels(allow: true)
        ..setPin('1234');

      final settings = container.read(parentalSettingsProvider);
      expect(settings.allowAdultChannels, isTrue);
      expect(settings.pin, '1234');

      notifier.setPin(null);
      expect(container.read(parentalSettingsProvider).hasPin, isFalse);
    });

    test('unlocks only with the right PIN', () {
      const guarded = ParentalSettings(allowAdultChannels: false, pin: '4321');

      expect(guarded.unlocks('4321'), isTrue);
      expect(guarded.unlocks('0000'), isFalse);
      expect(
        const ParentalSettings(allowAdultChannels: false).unlocks('anything'),
        isTrue,
        reason: 'no PIN means no lock',
      );
    });

    test('defaults to hiding adult channels', () async {
      final prefs = await mockPreferences();

      expect(PreferencesStore(prefs).allowAdultChannels(), isFalse);
    });
  });

  group('theme palette', () {
    test('starts on the tinted dark palette', () async {
      final container = await testContainer();

      expect(container.read(themePaletteProvider), ThemePalette.dark);
      expect(AppColors.of(ThemePalette.dark).background, isNot(Colors.black));
    });

    test('toggles to true black and persists the choice', () async {
      final container = await testContainer();

      container.read(themePaletteProvider.notifier).toggle();
      expect(container.read(themePaletteProvider), ThemePalette.amoled);
      expect(AppColors.of(ThemePalette.amoled).background, Colors.black);

      container.read(themePaletteProvider.notifier).toggle();
      expect(container.read(themePaletteProvider), ThemePalette.dark);
    });

    test('restores the saved palette on the next launch', () async {
      final container = await testContainer(
        values: {'theme_palette': 'amoled'},
      );

      expect(container.read(themePaletteProvider), ThemePalette.amoled);
    });

    test('falls back to dark for an unknown stored value', () {
      expect(ThemePalette.fromName('neon'), ThemePalette.dark);
      expect(ThemePalette.fromName(null), ThemePalette.dark);
    });
  });

  group('sleep timer', () {
    test('reports the pending stop and clears on cancel', () async {
      final container = await testContainer();
      final notifier = container.read(sleepTimerProvider.notifier);

      expect(container.read(sleepTimerProvider).isActive, isFalse);

      notifier.start(const Duration(minutes: 30));
      final active = container.read(sleepTimerProvider);
      expect(active.isActive, isTrue);
      expect(active.remaining.inMinutes, closeTo(29, 1));

      notifier.cancel();
      expect(container.read(sleepTimerProvider).isActive, isFalse);
    });

    test('signals expiry when it runs out, so the player can close', () async {
      final container = await testContainer();
      expect(container.read(sleepTimerExpiredProvider), 0);

      container
          .read(sleepTimerProvider.notifier)
          .start(const Duration(milliseconds: 50));
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(container.read(sleepTimerExpiredProvider), 1);
      expect(container.read(sleepTimerProvider).isActive, isFalse);
    });

    test('a cancelled timer never fires', () async {
      final container = await testContainer();

      container.read(sleepTimerProvider.notifier)
        ..start(const Duration(milliseconds: 50))
        ..cancel();
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(container.read(sleepTimerExpiredProvider), 0);
    });
  });

  group('update check', () {
    test('normalises tags and compares versions', () {
      expect(normalizeVersion('v1.2.0'), '1.2.0');
      expect(normalizeVersion('1.2.0+7'), '1.2.0');

      expect(compareVersions('1.2.0', '1.1.9'), greaterThan(0));
      expect(compareVersions('1.0.0', '1.0.0'), 0);
      expect(compareVersions('1.0.0', '1.0.1'), lessThan(0));
      expect(compareVersions('v1.10.0', '1.9.0'), greaterThan(0));
    });

    test('reports a newer release', () async {
      final checker = UpdateChecker(
        dio: _dioReturning(
          statusCode: 200,
          body: jsonEncode({
            'tag_name': 'v2.0.0',
            'html_url': 'https://github.com/neffex97/Tiwee/releases/tag/v2.0.0',
          }),
        ),
      );

      final status = await checker.check(currentVersion: '1.0.0');

      expect(status.isUpdateAvailable, isTrue);
      expect(status.latestVersion, '2.0.0');
      expect(status.releaseUrl, contains('releases/tag/v2.0.0'));
    });

    test('reports being up to date', () async {
      final checker = UpdateChecker(
        dio: _dioReturning(
          statusCode: 200,
          body: jsonEncode({'tag_name': '1.0.0', 'html_url': 'https://x'}),
        ),
      );

      final status = await checker.check(currentVersion: '1.0.0');

      expect(status.hasError, isFalse);
      expect(status.isUpdateAvailable, isFalse);
    });

    test('explains a repository with no releases', () async {
      final checker = UpdateChecker(dio: _dioReturning(statusCode: 404));

      final status = await checker.check(currentVersion: '1.0.0');

      expect(status.hasError, isTrue);
      expect(status.error, contains('No releases'));
      expect(status.isUpdateAvailable, isFalse);
    });
  });
}
