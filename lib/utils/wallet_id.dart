import 'dart:convert';
import 'dart:typed_data';

import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:crypto/crypto.dart';

/// Compute a deterministic 8-character hex ID from a seed.
///
/// Uses SHA-256 of the seed's identifying material:
/// - For mnemonic seeds: hashes the mnemonic string
/// - For entropy seeds: hashes the raw bytes
String computeWalletId(Seed seed) {
  final List<int> input = switch (seed) {
    Seed_Mnemonic(:final String mnemonic) => utf8.encode(mnemonic),
    Seed_Entropy(:final Uint8List field0) => field0,
  };
  return sha256.convert(input).toString().substring(0, 8);
}
