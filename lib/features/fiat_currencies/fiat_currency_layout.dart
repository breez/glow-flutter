import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/fiat_currencies/models/fiat_state.dart';
import 'package:glow/features/fiat_currencies/widgets/fiat_currency_tile.dart';
import 'package:glow/widgets/back_button.dart';

/// Pure presentation widget for fiat currency settings.
/// Two sections: reorderable preferred currencies at top, then all currencies.
class FiatCurrencyLayout extends StatefulWidget {
  const FiatCurrencyLayout({
    required this.state,
    required this.onCurrencyToggled,
    required this.onCurrenciesReordered,
    super.key,
  });

  final FiatCurrencyState state;
  final ValueChanged<String> onCurrencyToggled;
  final void Function(int oldIndex, int newIndex) onCurrenciesReordered;

  @override
  State<FiatCurrencyLayout> createState() => _FiatCurrencyLayoutState();
}

class _FiatCurrencyLayoutState extends State<FiatCurrencyLayout> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Sort available currencies alphabetically, preferred first
    final List<FiatCurrency> sortedCurrencies = _buildSortedCurrencyList();

    return Scaffold(
      appBar: AppBar(
        leading: const GlowBackButton(),
        title: const Text('Fiat Currency'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search currencies...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  isDense: true,
                ),
                onChanged: (String value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),

            // Preferred currencies section (reorderable)
            if (_searchQuery.isEmpty &&
                widget.state.preferredCurrencyIds.isNotEmpty) ...<Widget>[
              _SectionHeader(
                title: 'Preferred Currencies',
                theme: theme,
              ),
              _PreferredCurrenciesList(
                state: widget.state,
                onReorder: widget.onCurrenciesReordered,
                onToggle: widget.onCurrencyToggled,
              ),
              const Divider(indent: 16, endIndent: 16),
              _SectionHeader(
                title: 'All Currencies',
                theme: theme,
              ),
            ],

            // All currencies (filtered by search)
            Expanded(
              child: ListView.builder(
                itemCount: sortedCurrencies.length,
                itemBuilder: (BuildContext context, int index) {
                  final FiatCurrency currency = sortedCurrencies[index];
                  final bool isPreferred = widget.state.isPreferred(
                    currency.id,
                  );
                  final bool isLastPreferred = isPreferred &&
                      widget.state.preferredCurrencyIds.length <= 1;

                  return FiatCurrencyTile(
                    currency: currency,
                    isPreferred: isPreferred,
                    isLastPreferred: isLastPreferred,
                    onToggle: () => widget.onCurrencyToggled(currency.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FiatCurrency> _buildSortedCurrencyList() {
    List<FiatCurrency> currencies = List<FiatCurrency>.from(
      widget.state.availableCurrencies,
    );

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      currencies = currencies.where((FiatCurrency c) {
        return c.id.toLowerCase().contains(_searchQuery) ||
            c.info.name.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Sort alphabetically by ID, but preferred currencies first
    currencies.sort((FiatCurrency a, FiatCurrency b) {
      final bool aPreferred = widget.state.isPreferred(a.id);
      final bool bPreferred = widget.state.isPreferred(b.id);
      if (aPreferred && !bPreferred) {
        return -1;
      }
      if (!aPreferred && bPreferred) {
        return 1;
      }
      return a.id.compareTo(b.id);
    });

    return currencies;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.theme,
  });

  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 8.0,
        bottom: 4.0,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _PreferredCurrenciesList extends StatelessWidget {
  const _PreferredCurrenciesList({
    required this.state,
    required this.onReorder,
    required this.onToggle,
  });

  final FiatCurrencyState state;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final List<FiatCurrency> preferred = state.preferredCurrencies;

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: preferred.length,
      onReorder: onReorder,
      proxyDecorator: (
        Widget child,
        int index,
        Animation<double> animation,
      ) {
        return Material(
          elevation: 4.0,
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8.0),
          child: child,
        );
      },
      itemBuilder: (BuildContext context, int index) {
        final FiatCurrency currency = preferred[index];
        final String symbolText = currency.info.symbol?.grapheme ??
            currency.info.uniqSymbol?.grapheme ??
            '';
        final String titleText = symbolText.isNotEmpty
            ? '${currency.id} ($symbolText)'
            : currency.id;

        return ListTile(
          key: ValueKey<String>(currency.id),
          leading: const Icon(Icons.drag_handle),
          title: Text(
            titleText,
            style: const TextStyle(
              fontSize: 16.3,
              letterSpacing: 0.25,
            ),
          ),
          subtitle: Text(currency.info.name),
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 20.0),
            onPressed: state.preferredCurrencyIds.length > 1
                ? () => onToggle(currency.id)
                : null,
          ),
        );
      },
    );
  }
}
