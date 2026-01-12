import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/deposits/models/pending_deposit_payment.dart';
import 'package:glow/utils/error_parser.dart';
import 'package:glow/utils/formatters.dart';
import 'package:glow/widgets/card_wrapper.dart';
import 'package:glow/widgets/expandable_detail_row.dart';
import 'package:glow/widgets/warning_box.dart';

final AutoSizeGroup _labelGroup = AutoSizeGroup();

/// Layout for deposit approval (rendering)
///
/// Shows deposit details and gives user option to approve or reject the claim fee
/// If onAccept and onReject are null, displays error in unactionable state
class DepositApprovalLayout extends StatelessWidget {
  const DepositApprovalLayout({
    required this.pendingDeposit,
    required this.onAccept,
    required this.onReject,
    super.key,
  });

  final PendingDepositPayment pendingDeposit;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final bool hasError = pendingDeposit.deposit.claimError != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Claim on-chain transaction')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: pendingDeposit.hasFeeRequirement
              ? const EdgeInsets.all(24)
              : const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (pendingDeposit.hasFeeRequirement)
                _buildFeeAcceptanceCard(context)
              else if (hasError)
                _buildErrorCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeeAcceptanceCard(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(5.0)),
          border: Border.all(color: colorScheme.onSurface.withValues(alpha: .4)),
          color: colorScheme.surface,
        ),
        child: Column(
          children: <Widget>[
            // Deposit Amount
            _FeeDetailRow(
              title: 'Sent:',
              amountSat: pendingDeposit.amountSats,
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
            const Divider(height: 8.0, color: Color.fromRGBO(40, 59, 74, 0.5), indent: 16.0, endIndent: 16.0),
            // Claim Fee
            _FeeDetailRow(
              title: 'Transaction Fee:',
              amountSat: pendingDeposit.requiredFeeSats,
              textTheme: textTheme,
              colorScheme: colorScheme,
              isNegative: true,
              subtitle: pendingDeposit.requiredFeeRateSatPerVbyte > BigInt.zero
                  ? '${pendingDeposit.requiredFeeRateSatPerVbyte} sat/vByte'
                  : null,
            ),
            const Divider(height: 8.0, color: Color.fromRGBO(40, 59, 74, 0.5), indent: 16.0, endIndent: 16.0),
            // Net Amount
            _FeeDetailRow(
              title: 'To Receive:',
              amountSat: pendingDeposit.amountSats - pendingDeposit.requiredFeeSats,
              textTheme: textTheme,
              colorScheme: colorScheme,
              isBold: true,
            ),
            // Info message
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
              child: Text(
                'Expect fee variation depending on network usage.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                  fontSize: 13.5,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            // Action buttons
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 16, right: 16, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(36)),
                      onPressed: onReject,
                      child: const Text('REJECT'),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(36)),
                      onPressed: onAccept,
                      child: const Text('ACCEPT'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    final DepositClaimError error = pendingDeposit.deposit.claimError!;
    final TextTheme textTheme = Theme.of(context).textTheme;

    // Get error message
    final String errorMessage = ErrorParser.parseError(error);
    return Column(
      children: <Widget>[
        CardWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Transaction row with expandable detail
              ExpandableDetailRow(
                title: 'Transaction',
                value: pendingDeposit.deposit.txid,
                isExpanded: true,
                labelAutoSizeGroup: _labelGroup,
                linkUrl: 'https://mempool.space/tx/${pendingDeposit.deposit.txid}',
                linkTooltip: 'View on blockchain explorer',
              ),
              const Divider(
                height: 32.0,
                color: Color.fromRGBO(40, 59, 74, 0.5),
                indent: 0.0,
                endIndent: 0.0,
              ),
              // Amount row
              _buildAmountRow(context),
            ],
          ),
        ),

        WarningBox.text(message: errorMessage, textStyle: textTheme.bodySmall),
      ],
    );
  }

  Widget _buildAmountRow(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: AutoSizeText(
            'Amount:',
            style: themeData.textTheme.titleMedium?.copyWith(
              fontSize: 18.0,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.left,
            maxLines: 1,
            group: _labelGroup,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              '${formatSats(pendingDeposit.amountSats)} sats',
              style: themeData.textTheme.displaySmall?.copyWith(fontSize: 18.0, color: Colors.white),
              textAlign: TextAlign.right,
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }
}

/// Fee detail row widget (matching payment details style)
class _FeeDetailRow extends StatelessWidget {
  const _FeeDetailRow({
    required this.title,
    required this.amountSat,
    required this.textTheme,
    required this.colorScheme,
    this.isNegative = false,
    this.isBold = false,
    this.subtitle,
  });

  final String title;
  final BigInt amountSat;
  final TextTheme textTheme;
  final ColorScheme colorScheme;
  final bool isNegative;
  final bool isBold;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '${isNegative ? '-' : ''}$amountSat sats',
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  color: isNegative
                      ? colorScheme.error
                      : (isBold ? colorScheme.primary : colorScheme.onSurface),
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
