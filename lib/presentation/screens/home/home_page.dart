import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/presentation/screens/home/menu.dart';
import 'package:tiwee/presentation/screens/home/setting.dart';

const Duration _exitConfirmationWindow = Duration(seconds: 2);

/// Which of the two home pages is showing: 0 = menu, 1 = settings.
class HomePageIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  // ignore: use_setters_to_change_properties
  void select(int index) => state = index;
}

final homePageIndexProvider = NotifierProvider<HomePageIndexNotifier, int>(
  HomePageIndexNotifier.new,
);

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const List<Widget> _pages = [
    Menu(key: ValueKey<int>(0)),
    Setting(key: ValueKey<int>(1)),
  ];

  DateTime? _lastBackPressedAt;

  void _handleBack(bool didPop, Object? result) {
    if (didPop) return;

    final now = DateTime.now();
    final previousPress = _lastBackPressedAt;
    if (previousPress != null &&
        now.difference(previousPress) <= _exitConfirmationWindow) {
      _lastBackPressedAt = null;
      unawaited(SystemNavigator.pop());
      return;
    }

    _lastBackPressedAt = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit Tiwee.'),
          duration: _exitConfirmationWindow,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final pageIndex = ref.watch(homePageIndexProvider);

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: _handleBack,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final isSettings = child.key == const ValueKey<int>(1);
          final slide = Tween<Offset>(
            begin: Offset(isSettings ? 0.12 : -0.12, 0),
            end: Offset.zero,
          ).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: _pages[pageIndex],
      ),
    );
  }
}
