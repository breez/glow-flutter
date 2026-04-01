import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/wallet_onboarding/models/onboarding_state.dart';
import 'package:glow/features/wallet_onboarding/widgets/animated_logo.dart';
import 'package:glow/features/wallet_onboarding/widgets/breez_sdk_footer.dart';
import 'package:glow/features/wallet_onboarding/widgets/onboarding_actions.dart';
import 'package:glow/widgets/back_button.dart';
import 'package:glow/widgets/warning_box.dart';

class OnboardingLayout extends StatelessWidget {
  final OnboardingState state;
  final bool isPrfAvailable;
  final VoidCallback onRegister;
  final VoidCallback onPasskey;
  final VoidCallback onRestore;
  final VoidCallback onPasskeyConfirm;
  final VoidCallback onPasskeyBack;
  final VoidCallback onPasskeyRetry;
  final VoidCallback onPasskeyGoBackFromError;
  final ValueChanged<String> onSelectLabel;
  final ValueChanged<String> onSelectNewLabel;
  final ValueChanged<String> onManualLabelChanged;
  final VoidCallback onShowManualInput;
  final ValueChanged<String?> onLabelTapped;

  const OnboardingLayout({
    required this.state,
    required this.isPrfAvailable,
    required this.onRegister,
    required this.onPasskey,
    required this.onRestore,
    required this.onPasskeyConfirm,
    required this.onPasskeyBack,
    required this.onPasskeyRetry,
    required this.onPasskeyGoBackFromError,
    required this.onSelectLabel,
    required this.onSelectNewLabel,
    required this.onManualLabelChanged,
    required this.onShowManualInput,
    required this.onLabelTapped,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (state.passkeyPhase != null) {
      return _PasskeyFlowLayout(
        state: state,
        onConfirm: onPasskeyConfirm,
        onBack: onPasskeyBack,
        onRetry: onPasskeyRetry,
        onGoBackFromError: onPasskeyGoBackFromError,
        onSelectLabel: onSelectLabel,
        onSelectNewLabel: onSelectNewLabel,
        onManualLabelChanged: onManualLabelChanged,
        onShowManualInput: onShowManualInput,
        onLabelTapped: onLabelTapped,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: <Widget>[
              const Spacer(flex: 3),
              const AnimatedLogo(),
              const Spacer(flex: 3),
              OnboardingActions(
                state: state,
                isPrfAvailable: isPrfAvailable,
                onRegister: onRegister,
                onPasskey: onPasskey,
                onRestore: onRestore,
              ),
              const Spacer(),
              const BreezSdkFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Full-screen passkey flow
// =============================================================================

class _PasskeyFlowLayout extends StatelessWidget {
  final OnboardingState state;
  final VoidCallback onConfirm;
  final VoidCallback onBack;
  final VoidCallback onRetry;
  final VoidCallback onGoBackFromError;
  final ValueChanged<String> onSelectLabel;
  final ValueChanged<String> onSelectNewLabel;
  final ValueChanged<String> onManualLabelChanged;
  final VoidCallback onShowManualInput;
  final ValueChanged<String?> onLabelTapped;

  const _PasskeyFlowLayout({
    required this.state,
    required this.onConfirm,
    required this.onBack,
    required this.onRetry,
    required this.onGoBackFromError,
    required this.onSelectLabel,
    required this.onSelectNewLabel,
    required this.onManualLabelChanged,
    required this.onShowManualInput,
    required this.onLabelTapped,
  });

  /// Stepper step index for new-user flow (3 steps).
  int get _stepIndex {
    return switch (state.passkeyPhase) {
      PasskeyPhase.creating => 0,
      PasskeyPhase.storing => 1,
      PasskeyPhase.connecting => 2,
      _ => 3, // all complete
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GlowBackButton(onPressed: onBack),
        centerTitle: true,
        title: const Text('Get Started'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Stepper — only for new user flow
            if (state.isNewUser)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: _StepperBar(stepCount: 3, activeIndex: _stepIndex),
              ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: _buildContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final PasskeyPhase phase = state.passkeyPhase!;
    final String? error = state.passkeyError;

    return switch (phase) {
      PasskeyPhase.detecting => _buildSpinner(context, 'Detecting passkey...'),
      PasskeyPhase.review => _buildReview(context, error),
      PasskeyPhase.creating => error != null
          ? _buildError(
              context,
              title: 'Failed to create passkey',
              subtitle: 'Please ensure your device supports passkeys and is the correct device.',
            )
          : _buildSpinner(context, 'Initializing passkey...'),
      PasskeyPhase.storing => error != null
          ? _buildError(
              context,
              title: 'Failed to save label',
              subtitle: 'Please check your internet connection and try again.',
            )
          : _buildSpinner(context, 'Saving label...'),
      PasskeyPhase.authPick => _buildAuthPick(context),
      PasskeyPhase.connecting => error != null
          ? _buildError(
              context,
              title: 'Failed to connect',
              subtitle: 'Please check your internet connection and try again.',
            )
          : _buildSpinner(context, 'Starting Glow...'),
    };
  }

  Widget _buildSpinner(BuildContext context, String text) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: <Widget>[
          const SizedBox(height: 32),
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildReview(BuildContext context, String? error) {
    final ThemeData theme = Theme.of(context);


    return Column(
      children: <Widget>[
        const SizedBox(height: 32),

        // Passkey icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.key, size: 32, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 20),

        // Title
        Text(
          'Create your passkey',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          'A passkey will be created on your device to secure your funds.',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Warning card with icon
        WarningBox(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.warning_rounded, size: 20, color: theme.colorScheme.error),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Your passkey is how you access your funds',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Deleting your passkey from your device, browser, or password '
                      'manager may make your funds permanently inaccessible.',
                      style: TextStyle(fontSize: 14, letterSpacing: 0.4, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (error != null) ...<Widget>[
          const SizedBox(height: 16),
          Text(error, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
        ],

        const Spacer(),

        // "I understand" + "Go Back"
        SizedBox(
          height: 48.0,
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
              elevation: 0.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
            onPressed: onConfirm,
            child: AutoSizeText(
              'I understand',
              style: theme.textTheme.labelLarge?.copyWith(color: theme.primaryColor),
              maxLines: 1,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _goBackButton(context),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAuthPick(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final String trimmedManual = state.manualLabel.trim();
    final bool isDuplicate = trimmedManual.isNotEmpty &&
        state.labels.any(
          (String l) => l.toLowerCase() == trimmedManual.toLowerCase(),
        );
    final bool canContinue = state.showManualInput
        ? trimmedManual.isNotEmpty && !isDuplicate
        : state.selectedLabel != null;

    return Column(
      children: <Widget>[
        const SizedBox(height: 48),

        // Icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.vpn_key_outlined, size: 32, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          'Select a label',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Select an existing label or create a new one to connect with.',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Label list — takes available space
        Expanded(
          child: ListView(
            children: <Widget>[
              for (final String label in state.labels)
                _LabelTile(
                  label: label,
                  isSelected: !state.showManualInput && state.selectedLabel == label,
                  onTap: () => onLabelTapped(label),
                ),

              // "Create a new label..." button
              if (!state.showManualInput)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextButton.icon(
                    onPressed: onShowManualInput,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create a new label...'),
                  ),
                ),

              // Manual input
              if (state.showManualInput)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: _ManualLabelInput(
                    value: state.manualLabel,
                    isValid: canContinue,
                    isDuplicate: isDuplicate,
                    onChanged: onManualLabelChanged,
                  ),
                ),
            ],
          ),
        ),

        // Continue
        SizedBox(
          height: 48.0,
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
              elevation: 0.0,
              disabledBackgroundColor: theme.disabledColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
            onPressed: canContinue
                ? () {
                    if (state.showManualInput) {
                      onSelectNewLabel(trimmedManual);
                    } else {
                      onSelectLabel(state.selectedLabel!);
                    }
                  }
                : null,
            child: AutoSizeText(
              'Continue',
              style: theme.textTheme.labelLarge?.copyWith(color: theme.primaryColor),
              maxLines: 1,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _goBackButton(context),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildError(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: <Widget>[
          const SizedBox(height: 32),

          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.error_outline, size: 32, color: theme.colorScheme.error),
          ),
          const SizedBox(height: 24),

          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          SizedBox(
            height: 48.0,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                elevation: 0.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              onPressed: onRetry,
              child: AutoSizeText(
                'Retry',
                style: theme.textTheme.labelLarge?.copyWith(color: theme.primaryColor),
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _goBackButton(context, onPressed: onGoBackFromError),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _goBackButton(BuildContext context, {VoidCallback? onPressed}) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      height: 48.0,
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
        onPressed: onPressed ?? onBack,
        child: AutoSizeText(
          'Go Back',
          style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
          maxLines: 1,
        ),
      ),
    );
  }
}

// =============================================================================
// Stepper bar — matches glow-web OnboardingStepper
// =============================================================================

class _StepperBar extends StatelessWidget {
  final int stepCount;
  final int activeIndex;

  const _StepperBar({required this.stepCount, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        for (int i = 0; i < stepCount; i++) ...<Widget>[
          // Step circle
          if (i < activeIndex)
            // Completed: primary bg with dark checkmark
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
              ),
              child: Icon(Icons.check, size: 16, color: theme.scaffoldBackgroundColor),
            )
          else if (i == activeIndex)
            // Active: outlined with primary, number inside
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withAlpha(40),
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            )
          else
            // Upcoming: muted outline with number
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white38,
                  ),
                ),
              ),
            ),
          // Connector line
          if (i < stepCount - 1)
            Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: i < activeIndex
                    ? theme.colorScheme.primary
                    : Colors.white24,
              ),
            ),
        ],
      ],
    );
  }
}

// =============================================================================
// Label tile
// =============================================================================

class _LabelTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LabelTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primary.withAlpha(30)
            : theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Manual label input — matches label tile style when valid
// =============================================================================

class _ManualLabelInput extends StatelessWidget {
  final String value;
  final bool isValid;
  final bool isDuplicate;
  final ValueChanged<String> onChanged;

  const _ManualLabelInput({
    required this.value,
    required this.isValid,
    required this.isDuplicate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: isValid
            ? theme.colorScheme.primary.withAlpha(30)
            : theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isValid
              ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
              : BorderSide(color: theme.colorScheme.outline.withAlpha(80)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Label name',
                    border: InputBorder.none,
                    counterText: '',
                    errorText: isDuplicate ? 'A label with this name already exists' : null,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isValid ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLength: 24,
                  onChanged: onChanged,
                  controller: TextEditingController(text: value)
                    ..selection = TextSelection.collapsed(offset: value.length),
                ),
              ),
              if (isValid)
                Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
