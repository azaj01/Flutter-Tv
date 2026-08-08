import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/core/providers.dart';
import 'package:tiwee/core/theme/app_colors.dart';
import 'package:tiwee/domain/entities/category_entity.dart';
import 'package:tiwee/domain/entities/channel_entity.dart';
import 'package:tiwee/gen/assets.gen.dart';
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
      return Center(child: Assets.animation.loading.lottie(width: size.width / 4));
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
  final SvgGenImage icon;
  final String? categoryId;

  // Not const: the generated asset refs are getters, so the list is built
  // once at first use instead of being folded into a const literal.
  static final List<_MenuCardConfig> defaults = [
        _MenuCardConfig(title: 'Live Tv', icon: Assets.icons.tv),
        _MenuCardConfig(
          title: 'Movies',
          icon: Assets.icons.popcorn,
          categoryId: 'movies',
        ),
        _MenuCardConfig(
          title: 'Series',
          icon: Assets.icons.movie,
          categoryId: 'series',
        ),
        _MenuCardConfig(
          title: 'Animation',
          icon: Assets.icons.animation,
          categoryId: 'animation',
        ),
        _MenuCardConfig(
          title: 'Music',
          icon: Assets.icons.music,
          categoryId: 'music',
        ),
        _MenuCardConfig(
          title: 'Auto',
          icon: Assets.icons.auto,
          categoryId: 'auto',
        ),
        _MenuCardConfig(
          title: 'Sport',
          icon: Assets.icons.sport,
          categoryId: 'sports',
        ),
        _MenuCardConfig(
          title: 'News',
          icon: Assets.icons.news,
          categoryId: 'news',
        ),
        _MenuCardConfig(
          title: 'Cooking',
          icon: Assets.icons.cooking,
          categoryId: 'cooking',
        ),
        _MenuCardConfig(
          title: 'Kids',
          icon: Assets.icons.kids,
          categoryId: 'kids',
        ),
        _MenuCardConfig(
          title: 'Education',
          icon: Assets.icons.education,
          categoryId: 'education',
        ),
        _MenuCardConfig(
          title: 'Business',
          icon: Assets.icons.business,
          categoryId: 'business',
        ),
        _MenuCardConfig(
          title: 'Relaxation',
          icon: Assets.icons.relaxation,
          categoryId: 'relax',
        ),
        _MenuCardConfig(
          title: 'Entertainment',
          icon: Assets.icons.entertainment,
          categoryId: 'entertainment',
        ),
        _MenuCardConfig(
          title: 'Lifestyle',
          icon: Assets.icons.lifeStyle,
          categoryId: 'lifestyle',
        ),
        _MenuCardConfig(
          title: 'Science',
          icon: Assets.icons.science,
          categoryId: 'science',
        ),
        _MenuCardConfig(
          title: 'Comedy',
          icon: Assets.icons.comedy,
          categoryId: 'comedy',
        ),
        _MenuCardConfig(
          title: 'Family',
          icon: Assets.icons.family,
          categoryId: 'family',
        ),
        _MenuCardConfig(
          title: 'Shop',
          icon: Assets.icons.shop,
          categoryId: 'shop',
        ),
      ];
}
