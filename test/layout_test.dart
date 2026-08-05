import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:tiwee/core/providers.dart';
import 'package:tiwee/data/datasources/update_checker.dart';
import 'package:tiwee/domain/entities/category_entity.dart';
import 'package:tiwee/domain/entities/channel_entity.dart';
import 'package:tiwee/domain/entities/country_entity.dart';
import 'package:tiwee/domain/repositories/i_channel_repository.dart';
import 'package:tiwee/gen/assets.gen.dart';
import 'package:tiwee/presentation/screens/home/home_page.dart';
import 'package:tiwee/presentation/screens/home/menu.dart';
import 'package:tiwee/presentation/screens/home/parental_control_page.dart';
import 'package:tiwee/presentation/screens/home/saved_channels_page.dart';
import 'package:tiwee/presentation/screens/home/setting.dart';
import 'package:tiwee/presentation/screens/home/sorted_by_category_page.dart';
import 'package:tiwee/presentation/screens/home/sorted_by_country_page.dart';
import 'package:tiwee/presentation/widgets/channel_grid.dart';
import 'package:tiwee/presentation/widgets/home_page_widget/big_card_channel.dart';
import 'package:tiwee/presentation/widgets/setting/setting_card.dart';
import 'package:tiwee/presentation/widgets/tv_card.dart';

import 'helpers.dart';

/// A portrait phone, close to the iPhone 17 Pro logical size.
const Size _portrait = Size(402, 874);

/// The same phone on its side.
const Size _landscape = Size(874, 402);

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

class _FakeCategoryRepository implements ICategoryRepository {
  @override
  Future<List<CategoryEntity>> getCategories() async => const [
        CategoryEntity(id: 'general', name: 'General'),
      ];

  @override
  Future<CategoryEntity?> getCategoryById(String categoryId) async => null;

  @override
  Future<void> refresh() async {}
}

class _PendingUpdateChecker extends UpdateChecker {
  final Completer<UpdateStatus> _result = Completer<UpdateStatus>();

  @override
  Future<UpdateStatus> check({required String currentVersion}) =>
      _result.future;
}

void main() {
  group('HomePage navigation', () {
    Future<void> pumpHome(WidgetTester tester) async {
      setViewSize(tester, _portrait);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(
              await mockPreferences(),
            ),
            channelRepositoryProvider.overrideWithValue(
              _FakeChannelRepository([_channel('Alpha', 'US')]),
            ),
            categoryRepositoryProvider.overrideWithValue(
              _FakeCategoryRepository(),
            ),
          ],
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('animates from the menu to settings', (tester) async {
      await pumpHome(tester);

      expect(find.byType(Menu), findsOneWidget);
      expect(find.byType(Setting), findsNothing);

      await tester.tap(find.byKey(const Key('settings-toggle-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final rotatingGear = tester.widget<RotationTransition>(
        find.byKey(const Key('settings-toggle-rotation')),
      );
      expect(rotatingGear.turns.value, greaterThan(0));
      expect(rotatingGear.turns.value, lessThan(1));
      expect(find.byType(Menu), findsOneWidget);
      expect(find.byType(Setting), findsNothing);

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(find.byType(Menu), findsOneWidget);
      expect(find.byType(Setting), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(Menu), findsNothing);
      expect(find.byType(Setting), findsOneWidget);

      await tester.tap(find.byKey(const Key('settings-toggle-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(Menu), findsNothing);
      expect(find.byType(Setting), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(find.byType(Menu), findsOneWidget);
      expect(find.byType(Setting), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(Menu), findsOneWidget);
      expect(find.byType(Setting), findsNothing);
    });

    testWidgets('requires a second back press to exit', (tester) async {
      final platformCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          platformCalls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await pumpHome(tester);
      platformCalls.clear();

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(find.text('Press back again to exit Tiwee.'), findsOneWidget);
      expect(
        platformCalls.where((call) => call.method == 'SystemNavigator.pop'),
        isEmpty,
      );

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(
        platformCalls.where((call) => call.method == 'SystemNavigator.pop'),
        hasLength(1),
      );
    });
  });

  group('BigCardChannels', () {
    // A five-digit count used to overflow the tile by 21 logical pixels and
    // paint the debug stripe across the card.
    testWidgets('fits a five-digit channel count in a portrait tile', (
      tester,
    ) async {
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

      final grid = tester.widget<GridView>(
        find.byKey(const Key('settings-landscape-grid')),
      );
      final firstCardSize = tester.getSize(find.byType(SettingCard).first);

      expect(grid.scrollDirection, Axis.horizontal);
      expect(firstCardSize.width, closeTo(firstCardSize.height, 0.01));

      await tester.drag(
        find.byKey(const Key('settings-landscape-grid')),
        const Offset(-900, 0),
      );
      await tester.pumpAndSettle();

      final utilityCard = find.byKey(
        const Key('settings-landscape-utility-card'),
      );
      expect(utilityCard, findsOneWidget);
      expect(
        find.descendant(of: utilityCard, matching: find.text('Telegram')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: utilityCard, matching: find.text('GitHub')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: utilityCard,
          matching: find.text('Check for update'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses the home loader while checking for updates', (
      tester,
    ) async {
      setViewSize(tester, _portrait);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(
              await mockPreferences(),
            ),
            appVersionProvider.overrideWith((ref) async => '1.0.0'),
            updateCheckerProvider.overrideWithValue(_PendingUpdateChecker()),
          ],
          child: const MaterialApp(home: Setting()),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Check for update'));
      await tester.pump();
      await tester.pump();

      final loader = tester.widget<LottieBuilder>(
        find.byKey(const Key('update-check-loader')),
      );

      expect(
        (loader.lottie as AssetLottie).assetName,
        'assets/animation/loading.json',
      );
    });
  });

  group('SavedChannelsPage', () {
    testWidgets('explains how to save when nothing is saved yet', (
      tester,
    ) async {
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

    testWidgets('lists saved channels and offers to clear them', (
      tester,
    ) async {
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
      expect(
        find.text('Adult channels are hidden everywhere.'),
        findsOneWidget,
      );
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

  group('ParentalControlPage PIN dialog', () {
    // The controller was disposed in showDialog().whenComplete, which fires
    // while the route is still animating out and rebuilding the TextField.
    testWidgets('survives setting a PIN', (tester) async {
      await _pumpAt(tester, _portrait, const ParentalControlPage());

      await tester.tap(find.text('Set a PIN'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Remove PIN'), findsOneWidget);
    });

    testWidgets('survives cancelling the dialog', (tester) async {
      await _pumpAt(tester, _portrait, const ParentalControlPage());

      await tester.tap(find.text('Set a PIN'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('SortedByCategoryPage', () {
    Future<void> pumpCategory(WidgetTester tester, Size size) async {
      setViewSize(tester, size);

      final channels = [
        _channel('Animax Asia', 'SG'),
        _channel('Cartoon Network', 'US'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(
              await mockPreferences(),
            ),
            channelRepositoryProvider.overrideWithValue(
              _FakeChannelRepository(channels),
            ),
          ],
          child: MaterialApp(
            home: SortedByCategoryPage(
              categoryId: 'general',
              categoryTitle: 'Animation',
              preloadedChannels: channels,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
    }

    // Portrait used to squeeze the landscape layout sideways: the artwork got
    // a ~90pt column and only five channels fitted down a tall screen.
    testWidgets('shows the channel grid in portrait', (tester) async {
      await pumpCategory(tester, _portrait);

      expect(tester.takeException(), isNull);
      expect(find.byType(ChannelGrid), findsOneWidget);
      expect(find.byType(TvCard), findsNWidgets(2));
      expect(find.text('Animax Asia'), findsOneWidget);
    });

    // The carousel is landscape-only now, but it still has to survive the
    // AspectRatio(1/5) bug: that took the width from the available height and
    // squeezed every row to ~65pt, rendering names at zero width.
    testWidgets('keeps the preview and carousel in landscape', (tester) async {
      await pumpCategory(tester, _landscape);

      expect(tester.takeException(), isNull);
      expect(find.byType(ChannelGrid), findsNothing);
      // .first because the carousel loops, so it builds each row more than
      // once.
      expect(
        tester.getSize(find.text('Animax Asia').first).width,
        greaterThan(60),
        reason: 'the name column was collapsing to zero width',
      );
    });
  });

  group('SortedByCountryPage', () {
    // The country name and channel count used to render inside a ~68pt
    // carousel slot, which clipped every name to "Uni…", wrapped the count
    // over three lines and overflowed the row.
    testWidgets('shows the full country name and count in portrait', (
      tester,
    ) async {
      setViewSize(tester, _portrait);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(
              await mockPreferences(),
            ),
            channelRepositoryProvider.overrideWithValue(
              _FakeChannelRepository([
                for (var i = 0; i < 1797; i++) _channel('Channel$i', 'US'),
              ]),
            ),
            countryRepositoryProvider.overrideWithValue(
              _FakeCountryRepository(),
            ),
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
