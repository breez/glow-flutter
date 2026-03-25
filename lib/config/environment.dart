import 'package:flutter/foundation.dart';

/// App environment configuration
enum Environment {
  dev,
  prod;

  /// Get the current environment based on debug mode
  static Environment get current {
    return kDebugMode ? Environment.dev : Environment.prod;
  }

  /// Get environment suffix for storage keys
  String get storageSuffix => switch (this) {
    Environment.dev => '_dev2',
    Environment.prod => '',
  };
}
