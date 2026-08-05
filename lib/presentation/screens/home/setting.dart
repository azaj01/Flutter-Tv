import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icon.dart';
import 'package:line_icons/line_icons.dart';
import 'package:tiwee/core/consts.dart';
import 'package:tiwee/core/providers.dart';
import 'package:tiwee/core/theme/app_colors.dart';
import 'package:tiwee/core/utils/show_snackbar.dart';
import 'package:tiwee/core/utils/sleep_timer.dart';
import 'package:tiwee/gen/assets.gen.dart';
import 'package:tiwee/presentation/screens/home/parental_control_page.dart';
import 'package:tiwee/presentation/screens/home/saved_channels_page.dart';
import 'package:tiwee/presentation/widgets/clock_label.dart';
import 'package:tiwee/presentation/widgets/main_appbar.dart';
import 'package:tiwee/presentation/widgets/setting/setting_card.dart';
import 'package:url_launcher/url_launcher.dart';

const ColorFilter _whiteSvgFilter = ColorFilter.mode(
  Colors.white70,
  BlendMode.srcIn,
);

const ColorFilter _greenSvgFilter = ColorFilter.mode(
  Colors.green,
  BlendMode.srcIn,
);

/// Height of the short, wide tiles (links and the update row).
const double _kShortTileExtent = 68;

class Setting extends ConsumerWidget {
  const Setting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedCount = ref.watch(favouritesProvider).length;
    final adultAllowed = ref.watch(
      parentalSettingsProvider.select((it) => it.allowAdultChannels),
    );

    Future<void> openLink(String url, String label) async {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ShowSnackBar(context: context, text: 'Could not open $label').show();
      }
    }

    final primaryTiles = <Widget>[
      _IconTile(
        label: 'Saved show',
        asset: Assets.icons.saved,
        badge: savedCount == 0 ? null : '$savedCount',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const SavedChannelsPage(),
          ),
        ),
      ),
      const _ThemeTile(),
      const _SleepTimerTile(),
      SettingCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const ParentalControlPage(),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Assets.icons.parentLock.svg(
              colorFilter: adultAllowed ? _whiteSvgFilter : _greenSvgFilter,
              width: 38,
            ),
            const SizedBox(height: 12),
            const Text(
              'Parental',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const Text(
              'Control',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ];

    final telegramTile = SettingCard(
      onTap: () => openLink(kTelegramUrl, 'Telegram'),
      child: const LineIcon.telegram(color: Colors.blueAccent, size: 30),
    );
    final githubTile = SettingCard(
      onTap: () => openLink(kGithubUrl, 'GitHub'),
      child: const LineIcon.github(color: Colors.white, size: 30),
    );

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
                const MainAppbar(havSettingBtn: true, widget: ClockLabel()),
                const SizedBox(height: 30),
                Expanded(
                  child: OrientationBuilder(
                    builder: (context, orientation) {
                      if (orientation == Orientation.landscape) {
                        // Match the home menu: one row of square cards that
                        // scrolls horizontally across a short viewport.
                        return GridView.count(
                          key: const Key('settings-landscape-grid'),
                          crossAxisCount: 1,
                          scrollDirection: Axis.horizontal,
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            for (final tile in [
                              ...primaryTiles,
                              _LandscapeUtilityTile(
                                onTelegram: () =>
                                    openLink(kTelegramUrl, 'Telegram'),
                                onGithub: () => openLink(kGithubUrl, 'GitHub'),
                              ),
                            ])
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                child: tile,
                              ),
                          ],
                        );
                      }

                      // Two columns of square tiles, then full-width rows.
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: StaggeredGrid.count(
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          crossAxisCount: 2,
                          children: [
                            for (final tile in primaryTiles)
                              StaggeredGridTile.count(
                                crossAxisCellCount: 1,
                                mainAxisCellCount: 1,
                                child: tile,
                              ),
                            const StaggeredGridTile.extent(
                              crossAxisCellCount: 2,
                              mainAxisExtent: _kShortTileExtent,
                              child: _UpdateTile(),
                            ),
                            StaggeredGridTile.extent(
                              crossAxisCellCount: 1,
                              mainAxisExtent: _kShortTileExtent,
                              child: telegramTile,
                            ),
                            StaggeredGridTile.extent(
                              crossAxisCellCount: 1,
                              mainAxisExtent: _kShortTileExtent,
                              child: githubTile,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact landscape-only card: social links share the top row and the update
/// action spans the bottom, so three secondary actions use one home-card slot.
class _LandscapeUtilityTile extends StatelessWidget {
  const _LandscapeUtilityTile({
    required this.onTelegram,
    required this.onGithub,
  });

  final VoidCallback onTelegram;
  final VoidCallback onGithub;

  @override
  Widget build(BuildContext context) {
    return SettingCard(
      key: const Key('settings-landscape-utility-card'),
      onTap: null,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _CompactLinkAction(
                    label: 'Telegram',
                    icon: const LineIcon.telegram(
                      color: Colors.blueAccent,
                      size: 28,
                    ),
                    onTap: onTelegram,
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.white12,
                ),
                Expanded(
                  child: _CompactLinkAction(
                    label: 'GitHub',
                    icon: const LineIcon.github(
                      color: Colors.white,
                      size: 28,
                    ),
                    onTap: onGithub,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Colors.white12),
          const SizedBox(height: 76, child: _UpdateTile(embedded: true)),
        ],
      ),
    );
  }
}

class _CompactLinkAction extends StatelessWidget {
  const _CompactLinkAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Square tile with an SVG icon above a label, and an optional count badge.
class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.label,
    required this.asset,
    required this.onTap,
    this.badge,
  });

  final String label;
  final SvgGenImage asset;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final count = badge;

    return SettingCard(
      onTap: onTap,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                asset.svg(colorFilter: _whiteSvgFilter, width: 44),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          if (count != null)
            Positioned(
              top: 10,
              right: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: kPurple,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: Text(
                    count,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Switches between the two dark palettes.
///
/// Both are dark by design — the app has no light theme — so this trades the
/// purple-tinted surfaces for true black, which switches OLED pixels off.
class _ThemeTile extends ConsumerWidget {
  const _ThemeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(themePaletteProvider);
    final isAmoled = palette == ThemePalette.amoled;

    return SettingCard(
      onTap: () => ref.read(themePaletteProvider.notifier).toggle(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAmoled ? LineIcons.moon : LineIcons.sun,
            size: 44,
            color: Colors.white70,
          ),
          const SizedBox(height: 12),
          const Text(
            'Toggle theme',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            palette.label,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Sleep timer: stops playback after a chosen delay.
///
/// This replaces the old "Set alarm" tile, which never did anything. An alarm
/// that wakes you needs OS notification scheduling; a sleep timer is the thing
/// a TV app can actually deliver, and it is what the icon is useful for.
class _SleepTimerTile extends ConsumerWidget {
  const _SleepTimerTile();

  static const List<Duration> _choices = [
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 45),
    Duration(hours: 1),
    Duration(hours: 2),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(sleepTimerProvider);
    final endsAt = timer.endsAt;

    return SettingCard(
      onTap: () => _pick(context, ref, isActive: timer.isActive),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Assets.icons.alarm.svg(
            colorFilter: timer.isActive ? _greenSvgFilter : _whiteSvgFilter,
            width: 44,
          ),
          const SizedBox(height: 12),
          const Text(
            'Sleep timer',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          if (endsAt != null)
            Text(
              'until ${DateFormat.jm().format(endsAt)}',
              style: const TextStyle(color: Colors.green, fontSize: 12),
            )
          else
            const Text(
              'Off',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref, {
    required bool isActive,
  }) async {
    final choice = await showModalBottomSheet<Duration>(
      context: context,
      backgroundColor: kGray,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Stop playback after',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            for (final duration in _choices)
              ListTile(
                title: Text(
                  _label(duration),
                  style: const TextStyle(color: Colors.white70),
                ),
                onTap: () => Navigator.pop(context, duration),
              ),
            if (isActive)
              ListTile(
                leading: const Icon(Icons.close, color: Colors.redAccent),
                title: const Text(
                  'Turn off',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () => Navigator.pop(context, Duration.zero),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choice == null || !context.mounted) return;

    final notifier = ref.read(sleepTimerProvider.notifier);
    if (choice == Duration.zero) {
      notifier.cancel();
      ShowSnackBar(context: context, text: 'Sleep timer off').show();
      return;
    }

    notifier.start(choice);
    ShowSnackBar(
      context: context,
      text: 'Playback stops in ${_label(choice)}',
    ).show();
  }

  static String _label(Duration duration) {
    if (duration.inMinutes < 60) return '${duration.inMinutes} minutes';
    return duration.inHours == 1 ? '1 hour' : '${duration.inHours} hours';
  }
}

/// "Check for update": asks GitHub for the latest release and reports back.
class _UpdateTile extends ConsumerStatefulWidget {
  const _UpdateTile({this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<_UpdateTile> createState() => _UpdateTileState();
}

class _UpdateTileState extends ConsumerState<_UpdateTile> {
  bool _checking = false;

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);

    final version = await ref.read(appVersionProvider.future);
    final status =
        await ref.read(updateCheckerProvider).check(currentVersion: version);

    if (!mounted) return;
    setState(() => _checking = false);

    if (status.hasError) {
      ShowSnackBar(context: context, text: status.error!).show();
      return;
    }

    if (!status.isUpdateAvailable) {
      ShowSnackBar(
        context: context,
        text: 'Tiwee $version is the latest version.',
      ).show();
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kGray,
        title: Text('Version ${status.latestVersion} is available'),
        content: Text('You are running $version.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              launchUrl(
                Uri.parse(status.releaseUrl!),
                mode: LaunchMode.externalApplication,
              ).ignore();
            },
            child: const Text('Open release'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final version = ref.watch(appVersionProvider).value;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Check for update',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                if (version != null)
                  Text(
                    'Version $version',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          if (_checking)
            SizedBox(
              width: 26,
              height: 26,
              child: Assets.animation.loading.lottie(
                key: const Key('update-check-loader'),
              ),
            )
          else
            Assets.icons.update.svg(colorFilter: _greenSvgFilter, width: 24),
        ],
      ),
    );

    if (widget.embedded) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _check,
        child: content,
      );
    }

    return SettingCard(onTap: _check, child: content);
  }
}
