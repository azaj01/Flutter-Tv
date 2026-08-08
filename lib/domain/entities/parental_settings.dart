import 'package:equatable/equatable.dart';

/// Parental control state.
class ParentalSettings extends Equatable {
  const ParentalSettings({required this.allowAdultChannels, this.pin});

  /// Whether channels the API flags as adult are shown.
  final bool allowAdultChannels;

  /// PIN required to change [allowAdultChannels], or null when unprotected.
  final String? pin;

  bool get hasPin => pin != null && pin!.isNotEmpty;

  /// Whether [candidate] unlocks the settings. Always true when no PIN is set.
  bool unlocks(String candidate) => !hasPin || candidate == pin;

  @override
  List<Object?> get props => [allowAdultChannels, pin];

  ParentalSettings copyWith({bool? allowAdultChannels, String? pin}) {
    return ParentalSettings(
      allowAdultChannels: allowAdultChannels ?? this.allowAdultChannels,
      pin: pin ?? this.pin,
    );
  }

  /// [copyWith] cannot clear the PIN, so removing it gets its own method.
  ParentalSettings withoutPin() =>
      ParentalSettings(allowAdultChannels: allowAdultChannels);
}
