import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:line_icons/line_icons.dart';
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

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _rotation = Tween<double>(begin: 0, end: 3.1).animate(_controller);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Moves between the menu (page 0) and the settings page (page 1).
  ///
  /// The target is derived from the page that is actually showing. The old code
  /// derived it from a toggle read before it was flipped, so the first tap
  /// animated to the page the user was already on and did nothing visible.
  Future<void> _togglePage(WidgetRef ref) async {
    final currentIndex = ref.read(homePageIndexProvider);
    final targetIndex = currentIndex == 0 ? 1 : 0;

    unawaited(
      targetIndex == 1 ? _controller.forward() : _controller.reverse(),
    );

    ref.read(homePageIndexProvider.notifier).select(targetIndex);
    await ref.read(pageControllerProvider).animateToPage(
          targetIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
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
                  onTap: () => _togglePage(ref),
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
                      child: RotationTransition(
                        turns: _rotation,
                        child: SvgPicture.asset(
                          'assets/icons/setting.svg',
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
