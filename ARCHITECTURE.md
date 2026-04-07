# Architectural Guidelines

To ensure maintainability, testability, and scalability, we follow strict Separation of Concerns (SoC) principles and a custom Feature-First architecture.

## 1. Feature-First Structure
We organize code by **feature**, but with a flattened internal structure compared to standard Clean Architecture.

### Directory Structure
```
lib/features/feature_name/
├── models/           # Domain models & State classes
├── providers/        # Riverpod Notifiers (Business Logic)
├── services/         # (Optional) Feature-specific services
├── widgets/          # Feature-specific UI components
├── feature_screen.dart # The Container (Wiring)
└── feature_layout.dart # The View (Rendering)
```

### Layers
- **Presentation**: `widgets/`, `feature_screen.dart`, `feature_layout.dart`.
- **Application/Logic**: `providers/`. Notifiers handle user flows, state updates, and service calls.
- **Data/Core**: `lib/core/services/`. Shared services (e.g., `BreezSdkService`) are accessed by providers.

## 2. Separation of Concerns (SoC)

### Inversion of Control (IoC)
- **Do not instantiate dependencies** inside widgets.
- **Inject dependencies** using Riverpod.

### State Management
- **Separate business logic from UI code.**
- Use dedicated State objects (simple immutable classes with `equatable`) to represent the UI state.
- Use `Notifier` / `AsyncNotifier` to handle logic.
- Widgets should only *consume* state.

### Visual Dedicated Layout Widgets
Split "Screens" into two distinct widgets:

#### A. The Screen Widget (The "Container")
- **Responsibility**: Wiring and Configuration.
- Reads navigation arguments.
- Sets up Providers/Notifiers.
- Returns the `Layout` widget.
- **Example**: `WalletImportScreen`

#### B. The Layout Widget (The "View")
- **Responsibility**: Rendering only.
- Accepts state/data as arguments.
- **No business logic.**
- **Example**: `WalletImportLayout`

## Example Structure

```dart
// 1. The Screen (Container)
class DetailScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ModalRoute.of(context)!.settings.arguments as int;
    final state = ref.watch(detailControllerProvider(id));
    
    return DetailLayout(
      state: state,
      onRefresh: () => ref.read(detailControllerProvider(id).notifier).refresh(),
    );
  }
}

// 2. The Layout (View)
class DetailLayout extends StatelessWidget {
  final DetailState state;
  final VoidCallback onRefresh;

  const DetailLayout({required this.state, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(state.title)),
      body: state.isLoading 
          ? const CircularProgressIndicator()
          : Text(state.data),
      floatingActionButton: FloatingActionButton(onPressed: onRefresh),
    );
  }
}
```

## 3. Development Standards

### Code Quality Standards

All code must comply with the linter rules defined in [analysis_options.yaml](../analysis_options.yaml).

**Key linter rules:**
- `always_specify_types` - Always declare explicit types for variables, parameters, and return values
- `always_declare_return_types` - All functions and methods must have explicit return types
- `prefer_const_constructors` - Use const constructors wherever possible for better performance
- `require_trailing_commas` - Add trailing commas for better formatting and cleaner diffs
- `prefer_single_quotes` - Use single quotes for strings
- `use_build_context_synchronously` - Prevent async context errors in widgets

**Before committing:** Run `flutter analyze` to ensure compliance with all linter rules.

### Widget Performance Guidelines

**No helper methods in widgets:**
- Do NOT use private helper methods (e.g., `_buildHeader()`, `_buildRow()`) inside widget classes
- Helper methods are not performant in Flutter as they are called on every rebuild
- They prevent Flutter from optimizing the widget tree

**Use separate widget classes instead:**
- Extract UI components into separate widget classes (e.g., `PaymentHeader`, `PaymentSummaryRow`)
- Separate widgets enable const constructors, reducing unnecessary rebuilds
- This improves performance and makes code more maintainable

**Example:**
```dart
// ❌ Bad - Helper method
class MyWidget extends StatelessWidget {
  Widget _buildHeader() {  // Called on every rebuild
    return Text('Header');
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [_buildHeader()]);
  }
}

// ✅ Good - Separate widget class
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(children: [HeaderWidget()]);  // Can be const!
  }
}

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Header');
  }
}
```

### Riverpod 3.0 Guidelines

**Provider Syntax:**
- Use `NotifierProvider<MyNotifier, MyState>` (not the old `StateNotifierProvider`)
- Use function reference syntax: `NotifierProvider<MyNotifier, MyState>(MyNotifier.new)`
- Always specify explicit types for provider declarations (required by linter)

**Notifier Classes:**
- Extend `Notifier<State>` or `AsyncNotifier<State>` (not `StateNotifier`)
- For async operations that return `Future`, use `AsyncNotifier<State>`

**Basic Notifier Example:**
```dart
// Provider declaration with explicit type
final NotifierProvider<CounterNotifier, int> counterProvider =
  NotifierProvider<CounterNotifier, int>(CounterNotifier.new);

// Notifier class
class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}
```

**Family Notifiers:**

In Riverpod 3.0, there are no separate `FamilyNotifier` or `AutoDisposeFamilyNotifier` classes.

**Key differences:**
- Notifier class extends `Notifier<State>` (same as non-family)
- Family parameters are passed through the constructor
- Provider declaration chains `.family` and optionally `.autoDispose`

**Family Notifier Example:**
```dart
// Provider declaration with family and autoDispose
final NotifierProviderFamily<TodoNotifier, TodoState, String> todoProvider =
  NotifierProvider.autoDispose.family<TodoNotifier, TodoState, String>(
    TodoNotifier.new,
  );

// Notifier class receives family parameter via constructor
class TodoNotifier extends Notifier<TodoState> {
  TodoNotifier(this.todoId);
  final String todoId;

  @override
  TodoState build() {
    // Use this.todoId to access the family parameter
    return TodoState.loading(todoId);
  }

  Future<void> load() async {
    final data = await fetchTodo(todoId);
    state = TodoState.loaded(data);
  }
}

// Usage in widget
ref.watch(todoProvider('todo-123'));
ref.read(todoProvider('todo-123').notifier).load();
```

**AsyncNotifier Family Example:**
```dart
// Provider declaration
final AsyncNotifierProviderFamily<UserNotifier, User, int> userProvider =
  AsyncNotifierProvider.autoDispose.family<UserNotifier, User, int>(
    UserNotifier.new,
  );

// AsyncNotifier class
class UserNotifier extends AsyncNotifier<User> {
  UserNotifier(this.userId);
  final int userId;

  @override
  Future<User> build() async {
    // Fetch data in build method
    return await fetchUser(userId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => fetchUser(userId));
  }
}

// Usage
ref.watch(userProvider(42));  // Returns AsyncValue<User>
```

### Logging Patterns

We use the `AppLogger` system for structured logging throughout the application. There are two approaches depending on the class type:

#### Use LoggerMixin for Instance-Based Classes

Use `LoggerMixin` for classes that have instances where you can access instance members:
- Services
- Widgets
- Notifiers
- Controllers

**Example:**
```dart
import 'package:glow/logging/logger_mixin.dart';

class DepositClaimer with LoggerMixin {
  Future<void> claimDeposit(String txid) async {
    log.i('Claiming deposit: $txid');
    try {
      // ... claim logic
      log.d('Deposit claimed successfully');
    } catch (e, stack) {
      log.e('Failed to claim deposit', error: e, stackTrace: stack);
    }
  }
}
```

#### Use Module-Level Loggers for Static/Immutable Classes

Use module-level loggers for classes where `LoggerMixin` cannot be applied:
- Static methods
- Immutable data classes (extending `Equatable`)
- Classes with only static factory methods
- Top-level functions

**Example:**
```dart
import 'package:glow/logging/app_logger.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('PendingDepositPayment');

class PendingDepositPayment extends Equatable {
  const PendingDepositPayment({required this.deposit});

  final DepositInfo deposit;

  static PendingDepositPayment? fromDepositInfo(DepositInfo deposit) {
    _log.d('Creating pending deposit from: ${deposit.txid}');

    if (deposit.claimError != null) {
      _log.w('Deposit has claim error: ${deposit.claimError}');
    }

    return PendingDepositPayment(deposit: deposit);
  }

  @override
  List<Object?> get props => <Object?>[deposit];
}
```

#### Log Levels

Use appropriate log levels:
- `log.d()` - Debug: Detailed information for debugging (e.g., "Deposit has no claim error, can be auto-claimed")
- `log.i()` - Info: General informational messages (e.g., "Deposit claimed successfully", "Missing UTXO")
- `log.w()` - Warning: Potentially problematic situations (e.g., "Max fee exceeded", "Generic error")
- `log.e()` - Error: Error events that might still allow the app to continue (e.g., "Failed to claim deposit")

**Example:**
```dart
// Debug - detailed diagnostic info
_log.d('Deposit $depositId has no claim error, can be auto-claimed');

// Info - important events
_log.i('Deposit $depositId: missingUtxo - UTXO not yet visible on network');

// Warning - something unusual but handled
_log.w('Deposit $depositId: maxDepositClaimFeeExceeded - requiredFee: $requiredFeeSats sats');

// Error - operation failed
_log.e('Failed to claim deposit: ${deposit.id}', error: e, stackTrace: stack);
```