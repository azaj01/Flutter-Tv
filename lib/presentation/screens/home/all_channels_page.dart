import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:tiwee/core/consts.dart';
import 'package:tiwee/core/providers.dart';
import 'package:tiwee/core/theme/app_colors.dart';
import 'package:tiwee/presentation/widgets/channel_grid.dart';
import 'package:tiwee/presentation/widgets/error_view.dart';

/// Every playable channel, with a name search.
///
/// Browsing by country or category only gets you so far with ten thousand
/// channels; this is the "All" entry point from the live TV screen.
class AllChannelsPage extends ConsumerStatefulWidget {
  const AllChannelsPage({super.key});

  @override
  ConsumerState<AllChannelsPage> createState() => _AllChannelsPageState();
}

class _AllChannelsPageState extends ConsumerState<AllChannelsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(channelQueryProvider).trim();
    final channelsAsync = ref.watch(filteredChannelsProvider);

    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white70,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(color: Colors.white),
                      onChanged:
                          ref.read(channelQueryProvider.notifier).update,
                      decoration: InputDecoration(
                        hintText: 'Search channels',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.white38),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close),
                                color: Colors.white38,
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(channelQueryProvider.notifier)
                                      .update('');
                                },
                              ),
                        filled: true,
                        fillColor: context.colors.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: channelsAsync.when(
                  data: (channels) {
                    if (channels.isEmpty) {
                      return Center(
                        child: Text(
                          query.isEmpty
                              ? 'No channels available'
                              : 'Nothing matches "$query"',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    }
                    return ChannelGrid(channels: channels);
                  },
                  error: (error, stackTrace) => CatalogErrorView(error: error),
                  loading: () => Center(
                    child: SizedBox(
                      width: 50,
                      child: Lottie.asset(kLoading, width: 60),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
