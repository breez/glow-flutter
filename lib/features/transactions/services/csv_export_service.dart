import 'dart:io';

import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:glow/core/services/transaction_formatter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CsvExportService {
  const CsvExportService();

  Future<void> exportCsv({
    required List<Payment> payments,
    required String nodeId,
    required String network,
    List<PaymentType>? paymentTypeFilters,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final String csvContent = _generateCsvContent(payments, nodeId, network);
    final String filePath = await _writeCsvToFile(
      csvContent,
      paymentTypeFilters: paymentTypeFilters,
      startDate: startDate,
      endDate: endDate,
    );
    await _shareFile(filePath);
  }

  String _generateCsvContent(List<Payment> payments, String nodeId, String network) {
    final StringBuffer buffer = StringBuffer();

    // Header Information
    buffer.writeln('Node ID: $nodeId');
    buffer.writeln('Network: $network');
    buffer.writeln(); // Empty line separator

    // CSV Columns
    final List<String> columns = <String>[
      'Date',
      'Type',
      'Status',
      'Amount (Sats)',
      'Fee (Sats)',
      'Total Deducted/Added (Sats)',
      'Memo',
      'Payment Hash',
      'Preimage',
      'Payment ID',
    ];
    buffer.writeln(columns.join(','));

    // Sort payments by date descending (newest first)
    final List<Payment> sortedPayments = List<Payment>.from(payments)
      ..sort((Payment a, Payment b) => b.timestamp.compareTo(a.timestamp));

    final TransactionFormatter formatter = const TransactionFormatter();

    for (final Payment payment in sortedPayments) {
      final String date = _formatDate(payment.timestamp);
      final String type = formatter.formatType(payment.paymentType);
      final String status = formatter.formatStatus(payment.status);

      final BigInt amount = payment.amount;
      final BigInt fee = payment.fees;

      // Fee Calculation Logic:
      // Sent: Total = Amount + Fee (Deducted from balance)
      // Received: Total = Amount (Added to balance)
      final BigInt total = payment.paymentType == PaymentType.send ? amount + fee : amount;

      // Extract payment hash and preimage from details
      String paymentHash = '';
      String preimage = '';
      String memo = '';

      if (payment.details != null) {
        final PaymentDetails details = payment.details!;
        if (details is PaymentDetails_Lightning) {
          paymentHash = details.htlcDetails.paymentHash;
          preimage = details.htlcDetails.preimage ?? '';
          memo = details.description ?? '';
        } else {
          memo = formatter.getShortDescription(details);
        }
      }

      final String escapedMemo = _escapeCsvField(memo);
      final String id = payment.id;

      final List<String> row = <String>[
        date,
        type,
        status,
        amount.toString(),
        fee.toString(),
        payment.paymentType == PaymentType.send ? '-${total.toString()}' : total.toString(),
        escapedMemo,
        paymentHash,
        preimage,
        id,
      ];
      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  String _formatDate(BigInt timestamp) {
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  Future<String> _writeCsvToFile(
    String content, {
    List<PaymentType>? paymentTypeFilters,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final Directory directory = await getTemporaryDirectory();
    final String fileName = _buildFileName(
      paymentTypeFilters: paymentTypeFilters,
      startDate: startDate,
      endDate: endDate,
    );
    final String filePath = '${directory.path}/$fileName';
    final File file = File(filePath);
    await file.writeAsString(content);
    return filePath;
  }

  /// Builds the file name with filter information.
  String _buildFileName({
    List<PaymentType>? paymentTypeFilters,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final StringBuffer name = StringBuffer('GlowPayments');

    // Add payment type filter to filename
    if (paymentTypeFilters != null && paymentTypeFilters.isNotEmpty) {
      if (paymentTypeFilters.contains(PaymentType.send) &&
          !paymentTypeFilters.contains(PaymentType.receive)) {
        name.write('_sent');
      } else if (paymentTypeFilters.contains(PaymentType.receive) &&
          !paymentTypeFilters.contains(PaymentType.send)) {
        name.write('_received');
      }
    }

    // Add date range to filename
    if (startDate != null && endDate != null) {
      final DateFormat formatter = DateFormat('d.M.yy');
      name.write('_${formatter.format(startDate)}-${formatter.format(endDate)}');
    }

    name.write('.csv');
    return name.toString();
  }

  Future<void> _shareFile(String filePath) async {
    await SharePlus.instance.share(ShareParams(title: 'Payments', files: <XFile>[XFile(filePath)]));
  }
}
