import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tiwee/core/providers.dart';
import 'package:tiwee/domain/entities/channel_entity.dart';
import 'package:tiwee/domain/entities/country_entity.dart';
import 'package:tiwee/gen/assets.gen.dart';
import 'package:tiwee/presentation/screens/home/all_channels_page.dart';
import 'package:tiwee/presentation/screens/home/country_channels.dart';
import 'package:tiwee/presentation/screens/home/saved_channels_page.dart';
import 'package:tiwee/presentation/widgets/channel_grid.dart';
import 'package:tiwee/presentation/widgets/error_view.dart';
import 'package:tiwee/presentation/widgets/main_appbar.dart';
import 'package:tiwee/presentation/widgets/sorted_by_category_widget/fav_all_card.dart';

/// Index of the highlighted country in the carousel.
///
/// Auto-disposed so re-entering the screen starts at the first country instead
/// of pointing at a position from a previous visit.
class CurrentIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  // ignore: use_setters_to_change_properties
  void set(int value) => state = value;
}

final currentIndexProvider =
    NotifierProvider.autoDispose<CurrentIndexNotifier, int>(
  CurrentIndexNotifier.new,
);

class SortedByCountryPage extends ConsumerWidget {
  const SortedByCountryPage({required this.allChannelsCount, super.key});

  final int allChannelsCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countries = ref.watch(countriesProvider);
    final channelsByCountry = ref.watch(channelsByCountryProvider);

    if (countries.hasError || channelsByCountry.hasError) {
      return Scaffold(
        body: SafeArea(
          child: CatalogErrorView(
            error: countries.error ?? channelsByCountry.error,
          ),
        ),
      );
    }

    if (countries.isLoading || channelsByCountry.isLoading) {
      return Scaffold(
        body: Center(child: Assets.animation.loading.lottie(width: 60)),
      );
    }

    final entries = _buildEntries(
      channelsByCountry.value ?? const {},
      countries.value ?? const [],
    );

    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
          child: Column(
            children: [
              MainAppbar(
                widget: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        color: Colors.red,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 1,
                          horizontal: 7,
                        ),
                        child: Text(
                          'Live',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Tv',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              if (entries.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No countries available',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                )
              else
                Expanded(child: _CountryBrowser(entries: entries)),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: FavAllCard(
                        text: 'Fav',
                        icon: Icons.star,
                        // Real count now; this used to advertise a hard-coded
                        // 25 saved channels.
                        count: ref.watch(favouritesProvider).length,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const SavedChannelsPage(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FavAllCard(
                        text: 'All',
                        icon: Icons.tv,
                        count: allChannelsCount,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const AllChannelsPage(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Countries that actually have channels, most channels first.
  List<_CountryEntry> _buildEntries(
    Map<String, List<ChannelEntity>> channelsByCountry,
    List<CountryEntity> countries,
  ) {
    final countryMeta = {
      for (final country in countries) country.code.toUpperCase(): country,
    };

    final entries = <_CountryEntry>[];
    for (final entry in channelsByCountry.entries) {
      if (entry.value.isEmpty) continue;

      final code = entry.key.toUpperCase();
      final meta = countryMeta[code];
      entries.add(
        _CountryEntry(
          code: code,
          name: meta?.name ?? code,
          flag: meta?.flag ?? flagFromCode(code),
          channels: entry.value,
        ),
      );
    }

    entries.sort((a, b) => b.channels.length.compareTo(a.channels.length));
    return entries;
  }
}

/// Flag picker with the selected country's channels underneath.
///
/// The channels are already grouped in memory, so showing them here costs
/// nothing and turns what used to be half a screen of empty space into the
/// actual content — pick a flag, see what is on, tap to watch.
class _CountryBrowser extends ConsumerStatefulWidget {
  const _CountryBrowser({required this.entries});

  final List<_CountryEntry> entries;

  @override
  ConsumerState<_CountryBrowser> createState() => _CountryBrowserState();
}

class _CountryBrowserState extends ConsumerState<_CountryBrowser> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    // Clamped because the list can shrink under a stored index after a refresh.
    final currentIndex =
        ref.watch(currentIndexProvider).clamp(0, widget.entries.length - 1);
    final selected = widget.entries[currentIndex];

    return Column(
      children: [
        // Name and count sit at full width. Rendering them inside a carousel
        // item gave them a ~68pt slot, which truncated every country to "Uni…"
        // and wrapped the count over three lines.
        Text(
          selected.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 84,
          width: double.infinity,
          child: CarouselSlider.builder(
            carouselController: _carouselController,
            itemCount: widget.entries.length,
            itemBuilder: (context, index, realIndex) {
              return GestureDetector(
                // Tapping a flag selects it rather than navigating, so the
                // grid below is the reward for browsing.
                onTap: () => _carouselController.animateToPage(index),
                child: Center(
                  child: AnimatedScale(
                    scale: index == currentIndex ? 1 : 0.65,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      widget.entries[index].flag,
                      style: const TextStyle(fontSize: 52),
                    ),
                  ),
                ),
              );
            },
            options: CarouselOptions(
              onPageChanged: (index, reason) =>
                  ref.read(currentIndexProvider.notifier).set(index),
              viewportFraction: 0.2,
              enlargeCenterPage: true,
              scrollPhysics: const BouncingScrollPhysics(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                '${NumberFormat.decimalPattern().format(
                  selected.channels.length,
                )} channels',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => CountryChannels(
                    countryCode: selected.code,
                    countryName: selected.name,
                  ),
                ),
              ),
              child: const Text('See all'),
            ),
          ],
        ),
        Expanded(
          child: ChannelGrid(
            // A fresh scroll position per country, otherwise the grid keeps the
            // offset from the previously selected one.
            key: ValueKey(selected.code),
            channels: selected.channels,
          ),
        ),
      ],
    );
  }
}

class _CountryEntry {
  const _CountryEntry({
    required this.code,
    required this.name,
    required this.flag,
    required this.channels,
  });

  final String code;
  final String name;
  final String flag;
  final List<ChannelEntity> channels;
}

/// Builds a flag emoji from an ISO 3166-1 alpha-2 code.
String flagFromCode(String countryCode) {
  if (countryCode.length != 2) return '🏳️';

  const base = 0x1F1E6;
  const letterA = 0x41;
  final first = countryCode.codeUnitAt(0) - letterA + base;
  final second = countryCode.codeUnitAt(1) - letterA + base;
  if (first < base || first > base + 25 || second < base || second > base + 25) {
    return '🏳️';
  }

  return String.fromCharCodes([first, second]);
}
