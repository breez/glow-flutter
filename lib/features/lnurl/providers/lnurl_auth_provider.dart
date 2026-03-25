import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:glow/features/lnurl/models/lnurl_auth_state.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('LnurlAuthNotifier');

/// Provider for LNURL auth state
///
/// This provider manages the state for authenticating via LNURL
final NotifierProviderFamily<LnurlAuthNotifier, LnurlAuthState, LnurlAuthRequestDetails>
lnurlAuthProvider = NotifierProvider.autoDispose
    .family<LnurlAuthNotifier, LnurlAuthState, LnurlAuthRequestDetails>(LnurlAuthNotifier.new);

/// Notifier for LNURL auth flow
class LnurlAuthNotifier extends Notifier<LnurlAuthState> {
  LnurlAuthNotifier(this.arg);
  final LnurlAuthRequestDetails arg;

  @override
  LnurlAuthState build() {
    return const LnurlAuthInitial();
  }

  /// Authenticate with the service via LNURL-Auth (LUD-04)
  Future<void> authenticate() async {
    state = const LnurlAuthProcessing();

    try {
      final BreezSdk sdk = await ref.read(sdkProvider.future);

      _log.i('Authenticating with ${arg.domain}');

      final LnurlCallbackStatus result = await sdk.lnurlAuth(requestData: arg);

      switch (result) {
        case LnurlCallbackStatus_Ok():
          _log.i('Authentication successful for ${arg.domain}');
          state = const LnurlAuthSuccess();
        case LnurlCallbackStatus_ErrorStatus(:final LnurlErrorDetails errorDetails):
          _log.e('Authentication failed: ${errorDetails.reason}');
          state = LnurlAuthError(
            message: 'Authentication failed',
            technicalDetails: errorDetails.reason,
          );
      }
    } catch (e) {
      _log.e('Failed to authenticate: $e');
      state = LnurlAuthError(
        message: _extractErrorMessage(e),
        technicalDetails: e.toString(),
      );
    }
  }

  /// Extract user-friendly error message
  String _extractErrorMessage(Object error) {
    final String errorStr = error.toString();

    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Network error, please try again';
    }
    if (errorStr.contains('timeout')) {
      return 'Request timed out';
    }
    if (errorStr.contains('denied') || errorStr.contains('reject')) {
      return 'Authentication rejected';
    }

    return 'Authentication failed';
  }
}
