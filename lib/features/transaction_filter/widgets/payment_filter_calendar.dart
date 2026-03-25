import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:glow/features/transaction_filter/providers/transaction_filter_provider.dart';
import 'package:glow/providers/sdk_provider.dart';

class PaymentsFilterCalendar extends ConsumerWidget {
  const PaymentsFilterCalendar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Payment>> paymentsAsync = ref.watch(paymentsProvider);

    return IconButton(
      icon: SvgPicture.asset(
        'assets/svg/calendar.svg',
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcATop),
        width: 24.0,
        height: 24.0,
      ),
      // Disable the button if there are no payments to select a range from.
      onPressed: paymentsAsync.asData?.value.isNotEmpty == true
          ? () async {
              final List<Payment> payments = paymentsAsync.asData!.value;
              // The list is backwards, so the last element is the first chronologically.
              final DateTime firstDate = DateTime.fromMillisecondsSinceEpoch(
                payments.last.timestamp.toInt() * 1000,
              );
              final DateTime lastDate = DateTime.now();

              final DateTimeRange<DateTime>? picked = await showDateRangePicker(
                context: context,
                initialDateRange: ref.read(transactionFilterProvider).startDate != null
                    ? DateTimeRange(
                        start: ref.read(transactionFilterProvider).startDate!,
                        end: ref.read(transactionFilterProvider).endDate!,
                      )
                    : null,
                firstDate: firstDate,
                lastDate: lastDate,
                confirmText: 'Apply Filter'.toUpperCase(),
                cancelText: 'Clear'.toUpperCase(),
              );
              if (picked != null) {
                // Adjust the end date to be the end of that day to include all transactions.
                final DateTime endDate = picked.end.add(const Duration(days: 1, milliseconds: -1));
                ref.read(transactionFilterProvider.notifier).setDateRange(picked.start, endDate);
              } else {
                // User pressed "Clear" — remove the date filter
                ref.read(transactionFilterProvider.notifier).clearDateRange();
              }
            }
          : null,
    );
  }
}
