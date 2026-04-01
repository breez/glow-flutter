/// Passkey onboarding phases matching glow-web UX.
enum PasskeyPhase {
  /// Trying to list labels with an existing passkey.
  detecting,

  /// No passkey found — show warning + "I understand" / "Go Back".
  review,

  /// Creating a new passkey on device.
  creating,

  /// Saving label to Nostr relays.
  storing,

  /// Returning user: label picker / new label creation.
  authPick,

  /// Deriving wallet from passkey PRF.
  connecting,
}

class OnboardingState {
  final bool isLoading;

  /// Non-null when the passkey flow is active.
  final PasskeyPhase? passkeyPhase;

  /// Error message for the current passkey phase, if any.
  final String? passkeyError;

  /// True when user had no existing passkey (went through review → creating).
  final bool isNewUser;

  /// Labels discovered from Nostr during detecting phase.
  final List<String> labels;

  /// Currently selected label (for connecting).
  final String? selectedLabel;

  /// Typed label in manual input mode (auth-pick).
  final String manualLabel;

  /// Whether manual label input is shown in auth-pick.
  final bool showManualInput;

  const OnboardingState({
    this.isLoading = false,
    this.passkeyPhase,
    this.passkeyError,
    this.isNewUser = false,
    this.labels = const <String>[],
    this.selectedLabel,
    this.manualLabel = '',
    this.showManualInput = false,
  });

  OnboardingState copyWith({
    bool? isLoading,
    PasskeyPhase? passkeyPhase,
    String? passkeyError,
    bool? isNewUser,
    List<String>? labels,
    String? selectedLabel,
    String? manualLabel,
    bool? showManualInput,
  }) {
    return OnboardingState(
      isLoading: isLoading ?? this.isLoading,
      passkeyPhase: passkeyPhase ?? this.passkeyPhase,
      passkeyError: passkeyError ?? this.passkeyError,
      isNewUser: isNewUser ?? this.isNewUser,
      labels: labels ?? this.labels,
      selectedLabel: selectedLabel ?? this.selectedLabel,
      manualLabel: manualLabel ?? this.manualLabel,
      showManualInput: showManualInput ?? this.showManualInput,
    );
  }
}
