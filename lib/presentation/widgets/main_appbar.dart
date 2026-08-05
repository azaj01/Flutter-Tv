import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:tiwee/gen/assets.gen.dart';
import 'package:tiwee/presentation/screens/home/home_page.dart';

class MainAppbar extends StatefulWidget {
  const MainAppbar({
    required this.widget,
    super.key,
    this.havSettingBtn = false,
  });
  final Widget widget;
  final bool havSettingBtn;

  @override
  State<MainAppbar> createState() => _MainAppbarState();
}

class _MainAppbarState extends State<MainAppbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  late Animation<double> _scale;
  bool _isSwitching = false;

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _rotation = Tween<double>(begin: 0, end: 1).animate(curved);
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 0.82), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 0.82, end: 1), weight: 55),
    ]).animate(curved);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Selects the other home page and spins the settings icon.
  ///
  /// [HomePage] owns the page transition so navigation is driven directly by
  /// the selected index instead of coupling this app bar to a PageController.
  Future<void> _togglePage(WidgetRef ref) async {
    if (_isSwitching) return;
    _isSwitching = true;

    final currentIndex = ref.read(homePageIndexProvider);
    final targetIndex = currentIndex == 0 ? 1 : 0;

    // Finish a visible wheel animation before the app bar starts leaving the
    // screen. Running both together made the fading page hide the gear spin.
    await _controller.forward(from: 0);
    if (!mounted) return;

    ref.read(homePageIndexProvider.notifier).select(targetIndex);
    _isSwitching = false;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xff6A359C), Color(0xff9969C7)],
                    ),
                  ),
                  child: const Icon(
                    LineIcons.play,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(
                  width: 5,
                ),
                const Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    'Tiwee',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 21,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 35,
                  child: VerticalDivider(color: Colors.grey, thickness: 1),
                ),
                Expanded(child: widget.widget),
              ],
            ),
          ),
          if (widget.havSettingBtn)
            Consumer(
              builder: (context, ref, child) {
                return GestureDetector(
                  key: const Key('settings-toggle-button'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => unawaited(_togglePage(ref)),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Transform.scale(
                      scale: 0.8,
                      child: ScaleTransition(
                        scale: _scale,
                        child: RotationTransition(
                          key: const Key('settings-toggle-rotation'),
                          turns: _rotation,
                          child: Assets.icons.setting.svg(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
