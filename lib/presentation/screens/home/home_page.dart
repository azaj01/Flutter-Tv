import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/presentation/screens/home/menu.dart';
import 'package:tiwee/presentation/screens/home/setting.dart';

final pageControllerProvider = Provider<PageController>((ref) {
  final controller = PageController();
  ref.onDispose(controller.dispose);
  return controller;
});

/// Which of the two home pages is showing: 0 = menu, 1 = settings.
class HomePageIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  // ignore: use_setters_to_change_properties
  void select(int index) => state = index;
}

final homePageIndexProvider =
    NotifierProvider<HomePageIndexNotifier, int>(HomePageIndexNotifier.new);

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const List<Widget> _pages = [Menu(), Setting()];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(pageControllerProvider);

    return PageView.builder(
      itemCount: _pages.length,
      controller: controller,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => _pages[index],
    );
  }
}
