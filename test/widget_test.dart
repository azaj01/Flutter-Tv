import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiwee/data/datasources/iptv_remote_data_source.dart';
import 'package:tiwee/domain/entities/channel_entity.dart';
import 'package:tiwee/presentation/screens/home/sorted_by_country_page.dart';
import 'package:tiwee/presentation/widgets/error_view.dart';
import 'package:tiwee/presentation/widgets/tv_card.dart';

import 'helpers.dart';

const ChannelEntity _channelWithoutLogo = ChannelEntity(
  id: 'Alpha.us',
  name: 'Alpha Television',
  altNames: [],
  country: 'US',
  categories: ['news'],
  isNsfw: false,
  streams: [
    StreamEntity(url: 'https://a/live.m3u8', title: 'Alpha', quality: '1080p'),
  ],
);

void main() {
  group('TvCard', () {
    testWidgets('shows the channel name and its best quality', (tester) async {
      await pumpApp(tester, const SizedBox(width: 200, height: 200, child: TvCard(channel: _channelWithoutLogo)));

      expect(find.text('Alpha Television'), findsOneWidget);
      expect(find.text('1080p'), findsOneWidget);
    });

    testWidgets('falls back to initials when a channel has no logo',
        (tester) async {
      await pumpApp(tester, const SizedBox(width: 200, height: 200, child: TvCard(channel: _channelWithoutLogo)));

      expect(find.text('AT'), findsOneWidget);
    });
  });

  group('CatalogErrorView', () {
    testWidgets('explains the failure and offers a retry', (tester) async {
      await pumpApp(
        tester,
        CatalogErrorView(error: ApiException('No internet connection.')),
      );

      expect(find.text('No internet connection.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);
    });

    testWidgets('hides implementation detail for unexpected errors',
        (tester) async {
      await pumpApp(
        tester,
        const CatalogErrorView(error: FormatException('offset 12')),
      );

      expect(find.textContaining('offset 12'), findsNothing);
      expect(find.text('Could not load channels right now.'), findsOneWidget);
    });
  });

  group('flagFromCode', () {
    test('maps ISO codes to flag emoji', () {
      expect(flagFromCode('US'), '🇺🇸');
      expect(flagFromCode('FR'), '🇫🇷');
    });

    test('falls back for codes that are not two letters', () {
      expect(flagFromCode('USA'), '🏳️');
      expect(flagFromCode('12'), '🏳️');
    });
  });
}
