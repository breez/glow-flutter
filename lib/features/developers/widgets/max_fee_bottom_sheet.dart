import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/developers/widgets/toggle_button.dart';

class MaxFeeBottomSheet extends StatefulWidget {
  final MaxFee currentFee;
  final Function(MaxFee) onSave;
  final VoidCallback onReset;
  // Recommended fees to show as guide markers
  final BigInt? requiredFeeRate;
  final BigInt? requiredFeeSats;

  const MaxFeeBottomSheet({
    required this.currentFee,
    required this.onSave,
    required this.onReset,
    super.key,
    this.requiredFeeRate,
    this.requiredFeeSats,
  });

  @override
  State<MaxFeeBottomSheet> createState() => _MaxFeeBottomSheetState();
}

class _MaxFeeBottomSheetState extends State<MaxFeeBottomSheet> {
  late bool _useFixedFee;
  late double _sliderValue;

  // Base rate options (1-10 sat/vByte)
  static const double _minRate = 1.0;
  static const double _baseMaxRate = 10.0;

  // Base fixed fee options (100-1000 sats)
  static const double _minFixed = 100.0;
  static const double _baseMaxFixed = 1000.0;

  // Conversion factor: assuming ~100 vBytes for a typical transaction
  static const double _conversionFactor = 100.0;

  // Dynamic max values that adjust based on required fees
  double get _maxRate {
    if (widget.requiredFeeRate != null) {
      final double required = widget.requiredFeeRate!.toDouble();
      // If required exceeds base max, extend to 150% of required (rounded up to next whole number)
      if (required > _baseMaxRate) {
        return (required * 1.5).ceilToDouble();
      }
    }
    return _baseMaxRate;
  }

  double get _maxFixed {
    if (widget.requiredFeeSats != null) {
      final double required = widget.requiredFeeSats!.toDouble();
      // If required exceeds base max, extend to 150% of required (rounded up to nearest 100)
      if (required > _baseMaxFixed) {
        return ((required * 1.5 + 99) ~/ 100 * 100).toDouble();
      }
    }
    return _baseMaxFixed;
  }

  @override
  void initState() {
    super.initState();
    _useFixedFee = widget.currentFee.when(
      rate: (_) => false,
      fixed: (_) => true,
      networkRecommended: (_) => false,
    );
    _sliderValue = widget.currentFee.when(
      rate: (BigInt rate) => rate.toDouble(),
      fixed: (BigInt amount) => amount.toDouble(),
      networkRecommended: (BigInt leeway) => leeway.toDouble(),
    );
  }

  // Convert rate to fixed fee
  double _rateToFixed(double rate) {
    return (rate * _conversionFactor).floorToDouble().clamp(_minFixed, _maxFixed);
  }

  // Convert fixed fee to rate
  double _fixedToRate(double fixedFee) {
    return (fixedFee / _conversionFactor).floorToDouble().clamp(_minRate, _maxRate);
  }

  MaxFee get _currentFee {
    final BigInt rate = BigInt.from(_sliderValue.round());
    if (_useFixedFee) {
      return MaxFee.fixed(amount: rate);
    } else {
      return MaxFee.rate(satPerVbyte: rate);
    }
  }

  String get _feeDescription {
    final int rate = _sliderValue.round();
    if (_useFixedFee) {
      return '$rate sats fixed';
    } else {
      final int estimatedFee = (_conversionFactor * rate).round();
      return '$rate sat/vByte (~$estimatedFee sats)';
    }
  }

  String get _speedLabel {
    if (_useFixedFee) {
      if (_sliderValue < 300) {
        return 'Economy';
      }
      if (_sliderValue < 500) {
        return 'Standard';
      }
      if (_sliderValue < 800) {
        return 'Fast';
      }
      return 'Priority';
    } else {
      if (_sliderValue < 2) {
        return 'Economy';
      }
      if (_sliderValue < 4) {
        return 'Standard';
      }
      if (_sliderValue < 7) {
        return 'Fast';
      }
      return 'Priority';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Title
                Text(
                  'Deposit Claim Fee',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set the maximum fee for claiming Bitcoin deposits',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 32),

                // Current fee display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.primaryColorLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            _speedLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _feeDescription,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimary.withValues(alpha: 0.75),
                                fontWeight: FontWeight.w500,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Fee type toggle
                Container(
                  decoration: BoxDecoration(
                    color: theme.primaryColorLight.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: ToggleButton(
                          label: 'Rate',
                          isSelected: !_useFixedFee,
                          onTap: () {
                            setState(() {
                              // Convert current fixed fee to rate
                              final double newRate = _fixedToRate(_sliderValue);
                              _useFixedFee = false;
                              _sliderValue = newRate;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: ToggleButton(
                          label: 'Fixed',
                          isSelected: _useFixedFee,
                          onTap: () {
                            setState(() {
                              // Convert current rate to fixed fee
                              final double newFixed = _rateToFixed(_sliderValue);
                              _useFixedFee = true;
                              _sliderValue = newFixed;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Slider with optional guide marker
                Column(
                  children: <Widget>[
                    Stack(
                      alignment: Alignment.centerLeft,
                      children: <Widget>[
                        // Guide marker (if required fee rate is provided and we're in rate mode)
                        if (widget.requiredFeeRate != null && !_useFixedFee)
                          Positioned.fill(
                            child: LayoutBuilder(
                              builder: (BuildContext context, BoxConstraints constraints) {
                                final double requiredRate = widget.requiredFeeRate!.toDouble();
                                final double position =
                                    ((requiredRate - _minRate) / (_maxRate - _minRate)).clamp(
                                      0.0,
                                      1.0,
                                    );
                                final double leftPosition =
                                    position * (constraints.maxWidth - 48) + 24;

                                return Stack(
                                  children: <Widget>[
                                    Positioned(
                                      left: leftPosition,
                                      top: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 2,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.tertiary.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(1),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: leftPosition - 20,
                                      bottom: 30,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.tertiaryContainer.withValues(
                                            alpha: 0.25,
                                          ),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: theme.colorScheme.tertiary.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          '${requiredRate.round()}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onTertiaryContainer,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        // Guide marker (if required fee sats is provided and we're in fixed mode)
                        if (widget.requiredFeeSats != null && _useFixedFee)
                          Positioned.fill(
                            child: LayoutBuilder(
                              builder: (BuildContext context, BoxConstraints constraints) {
                                final double requiredFixed = widget.requiredFeeSats!.toDouble();
                                final double position =
                                    ((requiredFixed - _minFixed) / (_maxFixed - _minFixed)).clamp(
                                      0.0,
                                      1.0,
                                    );
                                final double leftPosition =
                                    position * (constraints.maxWidth - 48) + 24;

                                return Stack(
                                  children: <Widget>[
                                    Positioned(
                                      left: leftPosition,
                                      top: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 2,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.tertiary.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(1),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: leftPosition - 24,
                                      bottom: 30,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.tertiaryContainer.withValues(
                                            alpha: 0.25,
                                          ),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: theme.colorScheme.tertiary.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          '${requiredFixed.round()} sats',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onTertiaryContainer,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                        // Slider
                        Slider(
                          activeColor: Theme.of(context).primaryColorLight.withValues(alpha: 0.75),
                          thumbColor: Theme.of(context).primaryColorLight,
                          value: _sliderValue,
                          min: _useFixedFee ? _minFixed : _minRate,
                          max: _useFixedFee ? _maxFixed : _maxRate,
                          divisions: _useFixedFee
                              ? ((_maxFixed - _minFixed) / 50)
                                    .round() // 50 sats per division
                              : (_maxRate - _minRate).round(), // 1 sat/vByte per division
                          label: _feeDescription,
                          onChanged: (double value) {
                            setState(() {
                              _sliderValue = value;
                            });
                          },
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            _useFixedFee
                                ? '${_minFixed.round()} sats'
                                : '${_minRate.floor()} sat/vB',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            _useFixedFee
                                ? '${_maxFixed.round()} sats'
                                : '${_maxRate.floor()} sat/vB',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Info box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.info_outline, size: 20, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.requiredFeeRate != null && !_useFixedFee
                              ? 'Recommended: ${widget.requiredFeeRate} sat/vByte or higher to claim this deposit'
                              : widget.requiredFeeSats != null && _useFixedFee
                              ? 'Recommended: ${widget.requiredFeeSats} sats or higher to claim this deposit'
                              : 'Higher fees ensure deposits are claimed during network congestion',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    FilledButton(
                      onPressed: () {
                        widget.onSave(_currentFee);
                        Navigator.pop(context);
                      },
                      child: const Text('Save'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        widget.onReset();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      child: const Text('Reset'),
                    ),
                  ],
                ),

                // Bottom padding for safe area
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
