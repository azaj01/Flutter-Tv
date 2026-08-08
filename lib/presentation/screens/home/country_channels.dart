import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/core/providers.dart';
import 'package:tiwee/gen/assets.gen.dart';
import 'package:tiwee/presentation/widgets/channel_grid.dart';
import 'package:tiwee/presentation/widgets/error_view.dart';
import 'package:tiwee/presentation/widgets/main_appbar.dart';

class CountryChannels extends ConsumerWidget {
  const CountryChannels({
    required this.countryCode,
    required this.countryName,
    super.key,
  });

  /// ISO country code used to filter channels (matches `ChannelEntity.country`).
  final String countryCode;
  final String countryName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelsForCountryProvider(countryCode));

    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            MainAppbar(
              widget: Text(
                countryName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            Expanded(
              child: channelsAsync.when(
                data: (channels) {
                  if (channels.isEmpty) {
                    return const Center(
                      child: Text(
                        'No channels found',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: ref.read(catalogRefresherProvider).refreshQuietly,
                    child: ChannelGrid(channels: channels),
                  );
                },
                error: (error, stackTrace) => CatalogErrorView(error: error),
                loading: () => Center(
                  child: SizedBox(
                    width: 50,
                    child: Assets.animation.loading.lottie(width: 60),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
