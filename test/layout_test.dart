import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiwee/core/providers.dart';
import 'package:tiwee/domain/entities/channel_entity.dart';
import 'package:tiwee/domain/entities/country_entity.dart';
import 'package:tiwee/domain/repositories/i_channel_repository.dart';
import 'package:tiwee/gen/assets.gen.dart';
import 'package:tiwee/presentation/screens/home/parental_control_page.dart';
import 'package:tiwee/presentation/screens/home/saved_channels_page.dart';
import 'package:tiwee/presentation/screens/home/setting.dart';
import 'package:tiwee/presentation/screens/home/sorted_by_country_page.dart';
import 'package:tiwee/presentation/widgets/home_page_widget/big_card_channel.dart';

import 'helpers.dart';

/// A portrait phone, close to the iPhone 17 Pro logical size.
const Size _portrait = Size(402, 874);

/// The size a menu tile gets in portrait: half the padded width, square.
const Size _menuTile = Size(171, 171);

Future<void> _pumpAt(WidgetTester tester, Size size, Widget child) =>
    pumpApp(tester, child, surfaceSize: size);

ChannelEntity _channel(String id, String country) => ChannelEntity(
      id: id,
      name: id,
      altNames: const [],
      country: country,
      categories: const ['general'],
      isNsfw: false,
      streams: const [StreamEntity(url: 'https://a/live.m3u8', title: 'a')],
    );

class _FakeChannelRepository implements IChannelRepository {
  _FakeChannelRepository(this.channels);

  final List<ChannelEntity> channels;

  @override
  Future<List<ChannelEntity>> getChannels({bool includeNsfw = false}) async =>
      channels;

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

class _FakeCountryRepository implements ICountryRepository {
  @override
  Future<List<CountryEntity>> getCountries() async => const [
        CountryEntity(name: 'United States', code: 'US', flag: '🇺🇸'),
      ];

  @override
  Future<CountryEntity?> getCountryByCode(String countryCode) async => null;

  @override
  Future<void> refresh() async {}
}

void main() {
  group('BigCardChannels', () {
    // A five-digit count used to overflow the tile by 21 logical pixels and
    // paint the debug stripe across the card.
    testWidgets('fits a five-digit channel count in a portrait tile',
        (tester) async {
      await _pumpAt(
        tester,
        _portrait,
        Center(
          child: SizedBox.fromSize(
            size: _menuTile,
            child: BigCardChannels(
              icon: Assets.icons.tv,
              text: 'Live Tv',
              channelsCount: 10469,
              isLiveCard: true,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('10,469 Channels'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
    });

    testWidgets('fits the longest category name', (tester) async {
      await _pumpAt(
        tester,
        _portrait,
        Center(
          child: SizedBox.fromSize(
            size: _menuTile,
            child: BigCardChannels(
              icon: Assets.icons.entertainment,
              text: 'Entertainment',
              channelsCount: 1234,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('marks an empty group with a grey dot', (tester) async {
      await _pumpAt(
        tester,
        _portrait,
        Center(
          child: SizedBox.fromSize(
            size: _menuTile,
            child: BigCardChannels(
              icon: Assets.icons.shop,
              text: 'Shop',
              channelsCount: 0,
            ),
          ),
        ),
      );

      expect(find.text('0 Channels'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Setting', () {
    // The old grid mixed 2- and 6-cell-wide tiles into a 3-column staggered
    // grid, so several tiles were never placed and never appeared on screen.
    testWidgets('shows every tile in portrait', (tester) async {
      await _pumpAt(tester, _portrait, const Setting());

      for (final label in [
        'Saved show',
        'Toggle theme',
        'Sleep timer',
        'Parental',
        'Control',
        'Check for update',
      ]) {
        expect(find.text(label), findsOneWidget, reason: '$label is missing');
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets('lays out without overflow in landscape', (tester) async {
      await _pumpAt(tester, const Size(874, 402), const Setting());

      expect(tester.takeException(), isNull);
    });
  });

  group('SavedChannelsPage', () {
    testWidgets('explains how to save when nothing is saved yet',
        (tester) async {
      await pumpApp(
        tester,
        const SavedChannelsPage(),
        surfaceSize: _portrait,
        wrapInScaffold: false,
      );

      expect(find.text('Nothing saved yet'), findsOneWidget);
      expect(find.text('Clear all'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lists saved channels and offers to clear them',
        (tester) async {
      await pumpApp(
        tester,
        const SavedChannelsPage(),
        surfaceSize: _portrait,
        wrapInScaffold: false,
        preferences: await mockPreferences({
          'favourite_channel_ids': ['Alpha.us'],
        }),
      );

      expect(find.text('Clear all'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ParentalControlPage', () {
    testWidgets('offers the switch and PIN setup', (tester) async {
      await pumpApp(
        tester,
        const ParentalControlPage(),
        surfaceSize: _portrait,
        wrapInScaffold: false,
      );

      expect(find.text('Show adult channels'), findsOneWidget);
      expect(find.text('Adult channels are hidden everywhere.'), findsOneWidget);
      expect(find.text('Set a PIN'), findsOneWidget);
      expect(find.text('Remove PIN'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('offers to remove an existing PIN', (tester) async {
      await pumpApp(
        tester,
        const ParentalControlPage(),
        surfaceSize: _portrait,
        wrapInScaffold: false,
        preferences: await mockPreferences({'parental_pin': '1234'}),
      );

      expect(find.text('Change PIN'), findsOneWidget);
      expect(find.text('Remove PIN'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('SortedByCountryPage', () {
    // The country name and channel count used to render inside a ~68pt
    // carousel slot, which clipped every name to "Uni…", wrapped the count
    // over three lines and overflowed the row.
    testWidgets('shows the full country name and count in portrait',
        (tester) async {
      await tester.binding.setSurfaceSize(_portrait);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(await mockPreferences()),
            channelRepositoryProvider.overrideWithValue(
              _FakeChannelRepository([
                for (var i = 0; i < 1797; i++) _channel('Channel$i', 'US'),
              ]),
            ),
            countryRepositoryProvider
                .overrideWithValue(_FakeCountryRepository()),
          ],
          child: const MaterialApp(
            home: SortedByCountryPage(allChannelsCount: 10469),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('United States'), findsOneWidget);
      expect(find.text('1,797 channels'), findsOneWidget);
      expect(find.text('10,469'), findsOneWidget, reason: 'the All card count');
      expect(tester.takeException(), isNull);
    });
  });
}
