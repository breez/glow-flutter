import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/balance/balance_display_layout.dart';
import 'package:glow/features/balance/models/balance_state.dart';
import 'package:glow/features/transactions/models/transaction_list_state.dart';
import 'package:glow/features/transactions/transaction_list_layout.dart';

/// Demo catalog for Home feature components
/// Demonstrates the power of SoC - easy to create demos with any state
class HomeDemoScreen extends StatelessWidget {
  const HomeDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Demos')),
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Balance Display Demos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              title: const Text('Balance - Loaded'),
              subtitle: const Text('Normal state with balance'),
              onTap: () => _openBalanceDemo(context, _createLoadedBalanceState()),
            ),
            ListTile(
              title: const Text('Balance - Loading'),
              subtitle: const Text('Loading/syncing state'),
              onTap: () => _openBalanceDemo(context, BalanceState.loading()),
            ),
            ListTile(
              title: const Text('Balance - With Fiat'),
              subtitle: const Text('Balance with fiat conversion'),
              onTap: () => _openBalanceDemo(context, _createBalanceWithFiatState()),
            ),
            ListTile(
              title: const Text('Balance - Large Amount'),
              subtitle: const Text('Test with large balance'),
              onTap: () => _openBalanceDemo(context, _createLargeBalanceState()),
            ),
            const Divider(height: 32),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Transaction List Demos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              title: const Text('Transactions - With Data'),
              subtitle: const Text('List with multiple transactions'),
              onTap: () => _openTransactionDemo(context, _createLoadedTransactionState()),
            ),
            ListTile(
              title: const Text('Transactions - Empty'),
              subtitle: const Text('Glow is ready to receive funds.'),
              onTap: () => _openTransactionDemo(context, TransactionListState.empty()),
            ),
            ListTile(
              title: const Text('Transactions - Loading'),
              subtitle: const Text('Loading state'),
              onTap: () => _openTransactionDemo(context, TransactionListState.loading()),
            ),
            ListTile(
              title: const Text('Transactions - Error'),
              subtitle: const Text('Error state'),
              onTap: () => _openTransactionDemo(
                context,
                TransactionListState.error('Failed to load transactions'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openBalanceDemo(BuildContext context, BalanceState state) {
    Navigator.push(
      context,
      MaterialPageRoute<Scaffold>(
        builder: (BuildContext context) => Scaffold(
          appBar: AppBar(title: const Text('Balance Demo')),
          body: BalanceDisplayLayout(state: state),
        ),
      ),
    );
  }

  void _openTransactionDemo(BuildContext context, TransactionListState state) {
    Navigator.push(
      context,
      MaterialPageRoute<Scaffold>(
        builder: (BuildContext context) => Scaffold(
          appBar: AppBar(title: const Text('Transaction List Demo')),
          body: TransactionListLayout(state: state),
        ),
      ),
    );
  }

  // Demo state factories
  BalanceState _createLoadedBalanceState() {
    return BalanceState.loaded(
      balance: BigInt.from(1000000),
      hasSynced: true,
      formattedBalance: '1,000,000',
    );
  }

  BalanceState _createBalanceWithFiatState() {
    return BalanceState.loaded(
      balance: BigInt.from(500000),
      hasSynced: true,
      formattedBalance: '500,000',
      formattedFiat: '\$450.00',
    );
  }

  BalanceState _createLargeBalanceState() {
    return BalanceState.loaded(
      balance: BigInt.from(21000000000000),
      hasSynced: true,
      formattedBalance: '21,000,000,000,000',
    );
  }

  TransactionListState _createLoadedTransactionState() {
    final Payment mockPayment1 = Payment(
      id: 'demo_tx_001',
      amount: BigInt.from(50000),
      fees: BigInt.from(100),
      status: PaymentStatus.completed,
      paymentType: PaymentType.receive,
      method: PaymentMethod.lightning,
      timestamp: BigInt.from(
        DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch ~/ 1000,
      ),
      details: PaymentDetails_Lightning(
        description: 'Coffee payment',
        invoice: 'lnbc500n1...',
        htlcDetails: SparkHtlcDetails(paymentHash: 'abc123...', preimage: 'def456...', expiryTime: BigInt.zero, status: SparkHtlcStatus.preimageShared),
        destinationPubkey: '03xyz...',
      ),
    );

    final Payment mockPayment2 = Payment(
      id: 'demo_tx_002',
      amount: BigInt.from(25000),
      fees: BigInt.from(50),
      status: PaymentStatus.completed,
      paymentType: PaymentType.send,
      method: PaymentMethod.lightning,
      timestamp: BigInt.from(
        DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000,
      ),
      details: PaymentDetails_Lightning(
        description: 'Lunch',
        invoice: 'lnbc250n1...',
        htlcDetails: SparkHtlcDetails(paymentHash: 'xyz789...', preimage: 'uvw012...', expiryTime: BigInt.zero, status: SparkHtlcStatus.preimageShared),
        destinationPubkey: '03abc...',
      ),
    );

    final Payment mockPayment3 = Payment(
      id: 'demo_tx_003',
      amount: BigInt.from(100000),
      fees: BigInt.zero,
      status: PaymentStatus.pending,
      paymentType: PaymentType.receive,
      method: PaymentMethod.lightning,
      timestamp: BigInt.from(
        DateTime.now().subtract(const Duration(minutes: 10)).millisecondsSinceEpoch ~/ 1000,
      ),
      details: PaymentDetails_Lightning(
        description: 'Incoming payment',
        invoice: 'lnbc1m1...',
        htlcDetails: SparkHtlcDetails(paymentHash: 'pending123...', expiryTime: BigInt.zero, status: SparkHtlcStatus.waitingForPreimage),
        destinationPubkey: '03pending...',
      ),
    );

    final List<TransactionItemState> transactions = <TransactionItemState>[
      TransactionItemState(
        payment: mockPayment1,
        formattedAmount: '50,000',
        formattedAmountWithSign: '+ 50,000',
        formattedTime: '2h ago',
        formattedStatus: 'Completed',
        formattedMethod: 'Lightning',
        description: 'Coffee payment',
        isReceive: true,
      ),
      TransactionItemState(
        payment: mockPayment2,
        formattedAmount: '25,000',
        formattedAmountWithSign: '- 25,000',
        formattedTime: '1d ago',
        formattedStatus: 'Completed',
        formattedMethod: 'Lightning',
        description: 'Lunch',
        isReceive: false,
      ),
      TransactionItemState(
        payment: mockPayment3,
        formattedAmount: '100,000',
        formattedAmountWithSign: '+ 100,000',
        formattedTime: '10m ago',
        formattedStatus: 'Pending',
        formattedMethod: 'Lightning',
        description: 'Incoming payment',
        isReceive: true,
      ),
    ];

    return TransactionListState.loaded(transactions: transactions, hasSynced: true);
  }
}
