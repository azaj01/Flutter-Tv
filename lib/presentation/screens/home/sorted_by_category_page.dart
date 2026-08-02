import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart';
import 'package:tiwee/core/consts.dart';
import 'package:tiwee/core/providers.dart';
import 'package:tiwee/domain/entities/channel_entity.dart';
import 'package:tiwee/presentation/widgets/channel_logo.dart';
import 'package:tiwee/presentation/widgets/channel_player.dart';
import 'package:tiwee/presentation/widgets/error_view.dart';

class SortedByCategoryPage extends ConsumerStatefulWidget {
  const SortedByCategoryPage({
    required this.categoryId,
    required this.categoryTitle,
    super.key,
    this.preloadedChannels = const [],
  });

  final String categoryId;
  final String categoryTitle;
  final List<ChannelEntity> preloadedChannels;

  @override
  ConsumerState<SortedByCategoryPage> createState() =>
      _SortedByCategoryPageState();
}

class _SortedByCategoryPageState extends ConsumerState<SortedByCategoryPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final channelsAsync = ref.watch(
      channelsForCategoryProvider(widget.categoryId),
    );

    if (channelsAsync.hasError && channelsAsync.value == null) {
      return Scaffold(
        body: SafeArea(child: CatalogErrorView(error: channelsAsync.error)),
      );
    }

    final channels = channelsAsync.value ?? widget.preloadedChannels;

    if (channelsAsync.isLoading && channels.isEmpty) {
      return Scaffold(
        body: Center(child: Lottie.asset(kLoading, width: size.width / 4)),
      );
    }

    if (channels.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: SizedBox(
              width: size.width / 3,
              child: Lottie.asset(kNotFound, width: 100),
            ),
          ),
        ),
      );
    }

    // The carousel index outlives list changes (a refresh can return fewer
    // channels), so it has to be clamped before it is used to index.
    final selectedIndex = _currentIndex.clamp(0, channels.length - 1);
    final backdrop = kCategoryType[widget.categoryTitle];

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            if (backdrop != null)
              SizedBox(
                width: double.infinity,
                child: AnimatedOpacity(
                  opacity: 0.2,
                  duration: const Duration(seconds: 1),
                  child: CachedNetworkImage(
                    imageUrl: backdrop,
                    placeholder: (context, url) => const SizedBox.shrink(),
                    errorWidget: (context, url, error) =>
                        const SizedBox.shrink(),
                    fit: BoxFit.cover,
                    fadeInCurve: Curves.bounceIn,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back),
                        color: Colors.white70,
                      ),
                      Expanded(
                        child: Text(
                          widget.categoryTitle,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${channels.length} channels',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 140,
                            child: ChannelLogo(
                              channel: channels[selectedIndex],
                              padding: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: AnimationLimiter(
                            child: CarouselSlider.builder(
                              itemCount: channels.length,
                              itemBuilder: (context, index, realIndex) {
                                return AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration: const Duration(milliseconds: 700),
                                  child: SlideAnimation(
                                    verticalOffset: 50,
                                    child: FadeInAnimation(
                                      child: _ChannelRow(
                                        channel: channels[index],
                                        isSelected: index == selectedIndex,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              options: CarouselOptions(
                                onPageChanged: (index, reason) {
                                  setState(() => _currentIndex = index);
                                },
                                aspectRatio: 1 / 5,
                                viewportFraction: 0.2,
                                enlargeCenterPage: true,
                                scrollPhysics: const BouncingScrollPhysics(),
                                scrollDirection: Axis.vertical,
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
          ],
        ),
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.channel, required this.isSelected});

  final ChannelEntity channel;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final textColor =
        Colors.white.withValues(alpha: isSelected ? 0.7 : 0.3);

    return GestureDetector(
      onTap: () => launchChannelPlayer(context, channel),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: isSelected ? 0.6 : 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  channel.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                channel.country,
                style: TextStyle(color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
