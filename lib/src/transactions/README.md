# Transactions

`transactions` provides mutation orchestration primitives for retries, optimistic projection, settlement, and conflict handling. It exists so repos can expose optimistic mutations without each repo inventing its own retry, rollback, and replay machinery.

The model centers on `TxOperation`, which describes a mutation from optimistic apply through confirmed reconciliation, and `TxEngine`, which keeps confirmed state plus pending optimistic operations and replays them deterministically. Conflict helpers resolve overlapping touched keys, and `TransactionalMutationMixin` ties the whole flow into repo emissions, retries, analytics, and settlement.

The main parameters to keep in mind are `RetryPolicy` for delay and maximum attempts, `TxOperation.touchedKeys` for coarse replay conflict scope, and `TxResult<TState>` for the final visible state and success or failure outcome. `TransactionalMutationMixin` requires `installTransactionHooks()` in the repo constructor, `TxEngine` instances are per repo instance rather than singletons, and `MutationMixins` is legacy and deprecated in favor of the transaction model.

For example:

```dart
return transact<SettingsResponse>(
  SimpleTxOperation<SettingsState, SettingsResponse>(
    name: 'setTheme',
    id: nextTxId(),
    baseVersion: 0,
    touchedKeys: const {'settings.theme'},
    optimisticApply: (state) => state.copyWith(theme: theme),
    commit: (_) => datasource.setTheme(theme),
    applyConfirmed: (confirmed, result) => confirmed.copyWith(theme: result.theme),
  ),
);
```
