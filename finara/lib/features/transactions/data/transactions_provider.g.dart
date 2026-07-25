// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transactions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$transactionsDaoHash() => r'eac389fe6e6af3a31bd91f8fc566df1e06eab9de';

/// See also [transactionsDao].
@ProviderFor(transactionsDao)
final transactionsDaoProvider = Provider<TransactionsDao>.internal(
  transactionsDao,
  name: r'transactionsDaoProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$transactionsDaoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TransactionsDaoRef = ProviderRef<TransactionsDao>;
String _$pendingRecoveriesHash() => r'29ce53de1554feff6f32ad7116c34f2ae428bff4';

/// See also [pendingRecoveries].
@ProviderFor(pendingRecoveries)
final pendingRecoveriesProvider =
    AutoDisposeFutureProvider<List<Transaction>>.internal(
      pendingRecoveries,
      name: r'pendingRecoveriesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pendingRecoveriesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingRecoveriesRef = AutoDisposeFutureProviderRef<List<Transaction>>;
String _$settledRecoveriesHash() => r'357eb3aeafe2297a9d4358871fea895480a2c0a1';

/// See also [settledRecoveries].
@ProviderFor(settledRecoveries)
final settledRecoveriesProvider =
    AutoDisposeFutureProvider<List<Transaction>>.internal(
      settledRecoveries,
      name: r'settledRecoveriesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$settledRecoveriesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SettledRecoveriesRef = AutoDisposeFutureProviderRef<List<Transaction>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
