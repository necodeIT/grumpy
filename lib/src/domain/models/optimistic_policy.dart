import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:modular_foundation/modular_foundation.dart';

part 'optimistic_policy.freezed.dart';

/// Defines the optimistic update strategy for state modifications.
///
/// An [OptimisticPolicy] specifies how to compute optimistic values,
/// what snapshot to revert to on failure, and when to revert based on errors.
/// This is useful for implementing optimistic UI updates in applications,
/// allowing for a responsive user experience while handling potential failures.
@freezed
abstract class OptimisticPolicy<T> extends Model with _$OptimisticPolicy<T> {
  /// Creates an [OptimisticPolicy] with the given parameters.
  const factory OptimisticPolicy({
    /// The function to generate the optimistic value based on the current value.
    required T Function(T) optimisticValue,

    /// A function to determine whether to revert based on the error.
    ///
    /// If this function returns `true`, the operation will revert to the
    /// [snapshotValue].
    ///
    /// If it returns `false`, the optimistic update is retained despite the error
    /// when [propagateError] is `false`. If [propagateError] is `true`, the error is still thrown
    /// but the optimistic update is not reverted.
    required bool Function(Object? error) shouldRevert,

    /// If `true`, the error that caused the revert will be propagated after reverting.
    /// If `false`, the error will be swallowed.
    required bool propagateError,
  }) = _OptimisticPolicy;

  /// An [OptimisticPolicy] that always reverts on error and swallows the error.
  factory OptimisticPolicy.alwaysRevert({
    required T Function(T) optimisticValue,
  }) {
    return OptimisticPolicy(
      optimisticValue: optimisticValue,
      shouldRevert: _alwaysRevert,
      propagateError: false,
    );
  }

  /// An [OptimisticPolicy] that never reverts on error and swallows the error.
  factory OptimisticPolicy.neverRevert({
    required T Function(T) optimisticValue,
  }) {
    return OptimisticPolicy(
      optimisticValue: optimisticValue,
      shouldRevert: (_) => false,
      propagateError: false,
    );
  }

  /// An [OptimisticPolicy] that always reverts on error and propagates the error.
  factory OptimisticPolicy.propagateError({
    required T Function(T) optimisticValue,
  }) {
    return OptimisticPolicy(
      optimisticValue: optimisticValue,
      shouldRevert: _alwaysRevert,
      propagateError: true,
    );
  }

  static bool _alwaysRevert(Object? error) => true;
}
