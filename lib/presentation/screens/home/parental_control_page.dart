import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/core/consts.dart';
import 'package:tiwee/core/providers.dart';
import 'package:tiwee/core/theme/app_colors.dart';

/// Controls whether channels the API flags as adult reach the catalog.
///
/// Adult channels are hidden by default. Once a PIN is set, both revealing
/// them and removing the PIN require entering it.
class ParentalControlPage extends ConsumerWidget {
  const ParentalControlPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(parentalSettingsProvider);
    final notifier = ref.read(parentalSettingsProvider.notifier);

    return SafeArea(
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white70,
                ),
                const Expanded(
                  child: Text(
                    'Parental control',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _Card(
              child: SwitchListTile(
                value: settings.allowAdultChannels,
                onChanged: (value) async {
                  // The PIN guards both directions: without that, hiding the
                  // channels again would be the only protected action.
                  if (settings.hasPin &&
                      !await _promptForPin(context, settings.pin!)) {
                    return;
                  }
                  notifier.setAllowAdultChannels(allow: value);
                },
                title: const Text(
                  'Show adult channels',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  settings.allowAdultChannels
                      ? 'Adult channels appear in every list.'
                      : 'Adult channels are hidden everywhere.',
                  style: const TextStyle(color: Colors.white54),
                ),
                activeThumbColor: kPurple,
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: ListTile(
                title: Text(
                  settings.hasPin ? 'Change PIN' : 'Set a PIN',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  settings.hasPin
                      ? 'A PIN is required to change the switch above.'
                      : 'Without a PIN anyone can flip the switch above.',
                  style: const TextStyle(color: Colors.white54),
                ),
                trailing: const Icon(Icons.lock_outline, color: Colors.white54),
                onTap: () async {
                  if (settings.hasPin &&
                      !await _promptForPin(context, settings.pin!)) {
                    return;
                  }
                  if (!context.mounted) return;

                  final pin = await _promptForNewPin(context);
                  if (pin != null) notifier.setPin(pin);
                },
              ),
            ),
            if (settings.hasPin) ...[
              const SizedBox(height: 12),
              _Card(
                child: ListTile(
                  title: const Text(
                    'Remove PIN',
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: const Icon(Icons.lock_open, color: Colors.white54),
                  onTap: () async {
                    if (await _promptForPin(context, settings.pin!)) {
                      notifier.setPin(null);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Returns true when the user entered [expectedPin].
  Future<bool> _promptForPin(BuildContext context, String expectedPin) async {
    final entered = await _showPinDialog(
      context,
      title: 'Enter PIN',
      confirmLabel: 'Unlock',
    );
    if (entered == null) return false;

    if (entered != expectedPin) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wrong PIN')),
        );
      }
      return false;
    }
    return true;
  }

  Future<String?> _promptForNewPin(BuildContext context) => _showPinDialog(
        context,
        title: 'Choose a 4-digit PIN',
        confirmLabel: 'Save',
      );

  Future<String?> _showPinDialog(
    BuildContext context, {
    required String title,
    required String confirmLabel,
  }) {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.card,
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(counterText: ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text;
              Navigator.pop(context, value.length == 4 ? value : null);
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
