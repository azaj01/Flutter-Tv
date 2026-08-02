import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:tiwee/core/consts.dart';
import 'package:tiwee/core/providers.dart';
import 'package:tiwee/core/theme/app_colors.dart';
import 'package:tiwee/domain/entities/category_entity.dart';
import 'package:tiwee/domain/entities/channel_entity.dart';
import 'package:tiwee/presentation/screens/home/sorted_by_category_page.dart';
import 'package:tiwee/presentation/screens/home/sorted_by_country_page.dart';
import 'package:tiwee/presentation/widgets/clock_label.dart';
import 'package:tiwee/presentation/widgets/error_view.dart';
import 'package:tiwee/presentation/widgets/home_page_widget/big_card_channel.dart';
import 'package:tiwee/presentation/widgets/main_appbar.dart';

class Menu extends ConsumerWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(channelsProvider);
    final categories = ref.watch(categoriesProvider);
    final channelsByCategory = ref.watch(channelsByCategoryProvider);

    final size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [context.colors.background, context.colors.backgroundEnd],
              begin: Alignment.topLeft,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Column(
              children: [
                const MainAppbar(
                  havSettingBtn: true,
                  widget: ClockLabel(),
                ),
                const SizedBox(
                  height: 30,
                ),
                Expanded(
                  child: _MenuGrid(
                    size: size,
                    channels: channels,
                    categories: categories,
                    channelsByCategory: channelsByCategory,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuGrid extends ConsumerWidget {
  const _MenuGrid({
    required this.size,
    required this.channels,
    required this.categories,
    required this.channelsByCategory,
  });

  final Size size;
  final AsyncValue<List<ChannelEntity>> channels;
  final AsyncValue<List<CategoryEntity>> categories;
  final AsyncValue<Map<String, List<ChannelEntity>>> channelsByCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error =
        channels.error ?? categories.error ?? channelsByCategory.error;
    if (error != null) {
      return CatalogErrorView(error: error);
    }

    final isLoading = channels.isLoading ||
        categories.isLoading ||
        channelsByCategory.isLoading;
    if (isLoading) {
      return Center(child: Lottie.asset(kLoading, width: size.width / 4));
    }

    final channelList = channels.value ?? const [];
    final categoryList = categories.value ?? const [];
    final categoryMap = channelsByCategory.value ?? const {};
    final categoryNames = {
      for (final category in categoryList) category.id: category.name,
    };

    final cards = _MenuCardConfig.defaults;

    return RefreshIndicator(
      onRefresh: ref.read(catalogRefresherProvider).refreshQuietly,
      child: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;

          return GridView.count(
            crossAxisCount: isLandscape ? 1 : 2,
            physics: const AlwaysScrollableScrollPhysics(),
            scrollDirection: isLandscape ? Axis.horizontal : Axis.vertical,
            children: [
              for (var index = 0; index < cards.length; index++)
                _MenuCard(
                  card: cards[index],
                  allChannels: channelList,
                  categoryChannels:
                      categoryMap[cards[index].categoryId] ?? const [],
                  displayName: cards[index].categoryId == null
                      ? cards[index].title
                      : categoryNames[cards[index].categoryId] ??
                          cards[index].title,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.card,
    required this.allChannels,
    required this.categoryChannels,
    required this.displayName,
  });

  final _MenuCardConfig card;
  final List<ChannelEntity> allChannels;
  final List<ChannelEntity> categoryChannels;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final isLive = card.categoryId == null;
    final channels = isLive ? allChannels : categoryChannels;

    return FadeInUp(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => isLive
                  ? SortedByCountryPage(allChannelsCount: allChannels.length)
                  : SortedByCategoryPage(
                      categoryId: card.categoryId!,
                      categoryTitle: displayName,
                      preloadedChannels: categoryChannels,
                    ),
            ),
          ),
          child: BigCardChannels(
            channelsCount: channels.length,
            icon: card.icon,
            text: displayName,
            isLiveCard: isLive,
          ),
        ),
      ),
    );
  }
}

class _MenuCardConfig {
  const _MenuCardConfig({
    required this.title,
    required this.icon,
    this.categoryId,
  });

  final String title;
  final String icon;
  final String? categoryId;

  static List<_MenuCardConfig> get defaults => const [
        _MenuCardConfig(title: 'Live Tv', icon: 'assets/icons/tv.svg'),
        _MenuCardConfig(
          title: 'Movies',
          icon: 'assets/icons/popcorn.svg',
          categoryId: 'movies',
        ),
        _MenuCardConfig(
          title: 'Series',
          icon: 'assets/icons/movie.svg',
          categoryId: 'series',
        ),
        _MenuCardConfig(
          title: 'Animation',
          icon: 'assets/icons/animation.svg',
          categoryId: 'animation',
        ),
        _MenuCardConfig(
          title: 'Music',
          icon: 'assets/icons/music.svg',
          categoryId: 'music',
        ),
        _MenuCardConfig(
          title: 'Auto',
          icon: 'assets/icons/auto.svg',
          categoryId: 'auto',
        ),
        _MenuCardConfig(
          title: 'Sport',
          icon: 'assets/icons/sport.svg',
          categoryId: 'sports',
        ),
        _MenuCardConfig(
          title: 'News',
          icon: 'assets/icons/news.svg',
          categoryId: 'news',
        ),
        _MenuCardConfig(
          title: 'Cooking',
          icon: 'assets/icons/coocking.svg',
          categoryId: 'cooking',
        ),
        _MenuCardConfig(
          title: 'Kids',
          icon: 'assets/icons/kids.svg',
          categoryId: 'kids',
        ),
        _MenuCardConfig(
          title: 'Education',
          icon: 'assets/icons/education.svg',
          categoryId: 'education',
        ),
        _MenuCardConfig(
          title: 'Business',
          icon: 'assets/icons/business.svg',
          categoryId: 'business',
        ),
        _MenuCardConfig(
          title: 'Relaxation',
          icon: 'assets/icons/relaxation.svg',
          categoryId: 'relax',
        ),
        _MenuCardConfig(
          title: 'Entertainment',
          icon: 'assets/icons/entertainment.svg',
          categoryId: 'entertainment',
        ),
        _MenuCardConfig(
          title: 'Lifestyle',
          icon: 'assets/icons/lifeStyle.svg',
          categoryId: 'lifestyle',
        ),
        _MenuCardConfig(
          title: 'Science',
          icon: 'assets/icons/science.svg',
          categoryId: 'science',
        ),
        _MenuCardConfig(
          title: 'Comedy',
          icon: 'assets/icons/comedy.svg',
          categoryId: 'comedy',
        ),
        _MenuCardConfig(
          title: 'Family',
          icon: 'assets/icons/family.svg',
          categoryId: 'family',
        ),
        _MenuCardConfig(
          title: 'Shop',
          icon: 'assets/icons/shop.svg',
          categoryId: 'shop',
        ),
      ];
}
