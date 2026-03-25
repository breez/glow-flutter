import 'dart:io' show Platform;

import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/fiat_currencies/models/fiat_state.dart';
import 'package:glow/features/fiat_currencies/providers/fiat_currency_provider.dart';
import 'package:glow/features/fiat_currencies/widgets/exchange_rate_label.dart';
import 'package:glow/features/fiat_currencies/widgets/fiat_currency_chips.dart';
import 'package:glow/features/fiat_currencies/widgets/fiat_input_field.dart';
import 'package:glow/features/fiat_currencies/widgets/sat_equivalent_label.dart';
import 'package:intl/intl.dart';

/// Shows the currency converter bottom sheet and returns the sat amount.
Future<BigInt?> showCurrencyConverterSheet(BuildContext context) async {
  return showModalBottomSheet<BigInt>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) => const CurrencyConverterBottomSheet(),
  );
}

/// Bottom sheet for converting fiat amounts to sats.
/// Shows preferred currency chips, fiat input, sat equivalent, and exchange rate.
class CurrencyConverterBottomSheet extends ConsumerStatefulWidget {
  const CurrencyConverterBottomSheet({super.key});

  @override
  ConsumerState<CurrencyConverterBottomSheet> createState() =>
      _CurrencyConverterBottomSheetState();
}

class _CurrencyConverterBottomSheetState
    extends ConsumerState<CurrencyConverterBottomSheet> {
  final TextEditingController _controller = TextEditingController();

  late String _selectedCurrencyId;

  @override
  void initState() {
    super.initState();
    final FiatCurrencyState? fiatState = ref.read(fiatCurrencyProvider).value;
    _selectedCurrencyId =
        fiatState?.activeCurrencyId ?? fiatState?.preferredCurrencyIds.firstOrNull ?? 'USD';
    _controller.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onInputChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    setState(() {
      // Trigger rebuild for sat equivalent
    });
  }

  BigInt? _calculateSatAmount() {
    final String text = _controller.text;
    if (text.isEmpty) {
      return null;
    }
    final double? fiatAmount = double.tryParse(text);
    if (fiatAmount == null || fiatAmount <= 0) {
      return null;
    }
    return ref.read(fiatCurrencyProvider.notifier).fiatToSats(
      fiatAmount,
      _selectedCurrencyId,
    );
  }

  String _buildExchangeRateText(FiatCurrencyState state) {
    final double? rate = state.rates[_selectedCurrencyId];
    if (rate == null || rate == 0) {
      return '';
    }

    FiatCurrency? currency;
    try {
      currency = state.availableCurrencies.firstWhere(
        (FiatCurrency c) => c.id == _selectedCurrencyId,
      );
    } catch (_) {
      return '';
    }

    final String symbol = currency.info.symbol?.grapheme ??
        currency.info.uniqSymbol?.grapheme ??
        _selectedCurrencyId;

    // rate is sats per unit of fiat
    // 1 BTC = 100_000_000 sats, so 1 BTC = (100_000_000 / rate) fiat units
    final double btcInFiat = 100000000.0 / rate;
    final NumberFormat numberFormat = NumberFormat.decimalPattern(
      Platform.localeName,
    );
    final String formattedFiat = numberFormat.format(btcInFiat);

    return '1 BTC = $symbol$formattedFiat';
  }

  String _getCurrencySymbol(FiatCurrencyState state) {
    try {
      final FiatCurrency currency = state.availableCurrencies.firstWhere(
        (FiatCurrency c) => c.id == _selectedCurrencyId,
      );
      return currency.info.symbol?.grapheme ??
          currency.info.uniqSymbol?.grapheme ??
          _selectedCurrencyId;
    } catch (_) {
      return _selectedCurrencyId;
    }
  }

  int _getFractionSize(FiatCurrencyState state) {
    try {
      final FiatCurrency currency = state.availableCurrencies.firstWhere(
        (FiatCurrency c) => c.id == _selectedCurrencyId,
      );
      return currency.info.fractionSize;
    } catch (_) {
      return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<FiatCurrencyState> fiatAsync = ref.watch(
      fiatCurrencyProvider,
    );

    return fiatAsync.when(
      data: (FiatCurrencyState state) => _buildContent(context, state),
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stackTrace) => SizedBox(
        height: 200,
        child: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, FiatCurrencyState state) {
    final BigInt? satAmount = _calculateSatAmount();
    final String rateText = _buildExchangeRateText(state);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12.0, bottom: 8.0),
              width: 40.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Convert to Sats',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Currency chips
          FiatCurrencyChips(
            preferredCurrencies: state.preferredCurrencies,
            selectedCurrencyId: _selectedCurrencyId,
            onCurrencySelected: (String id) {
              setState(() {
                _selectedCurrencyId = id;
              });
            },
          ),

          const Divider(indent: 16, endIndent: 16),

          // Fiat input
          FiatInputField(
            controller: _controller,
            currencySymbol: _getCurrencySymbol(state),
            fractionSize: _getFractionSize(state),
          ),

          // Sat equivalent
          SatEquivalentLabel(satAmount: satAmount),

          // Exchange rate
          if (rateText.isNotEmpty) ExchangeRateLabel(rateText: rateText),

          // Done button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: satAmount != null && satAmount > BigInt.zero
                    ? () => Navigator.pop(context, satAmount)
                    : null,
                child: const Text('Done'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
