import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:grumpy/grumpy.dart';

part 'optimistic_policy.freezed.dart';

/// Defines the optimistic update strategy for state modifications.
///
/// An [OptimisticPolicy] specifies how to compute optimistic values,
/// what snapshot to revert to on failure, and when to revert based on errors.
/// This is useful for implementing optimistic UI updates in applications,
/// allowing for a responsive user experience while handling potential failures.
///
/// {@category transactions}

@freezed
abstract class OptimisticPolicy<T> extends Model with _$OptimisticPolicy<T> {
  /// Creates an [OptimisticPolicy] with the given parameters.
  const factory OptimisticPolicy({
    /// The function to generate the optimistic value based on the current value.
    required T Function(T) optimisticValue,

    /// A function to determine whether to revert based on the error.
    ///
    /// If this function returns `true`, the changes from [optimisticValue] will be reverted.
    required bool Function(Object? error) shouldRevert,
  }) = _OptimisticPolicy;
  const OptimisticPolicy._();

  /// An [OptimisticPolicy] that always reverts on error and swallows the error.
  factory OptimisticPolicy.alwaysRevert({
    required T Function(T) optimisticValue,
  }) {
    return OptimisticPolicy(
      optimisticValue: optimisticValue,
      shouldRevert: (_) => true,
    );
  }

  /// An [OptimisticPolicy] that never reverts on error and swallows the error.
  factory OptimisticPolicy.neverRevert({
    required T Function(T) optimisticValue,
  }) {
    return OptimisticPolicy(
      optimisticValue: optimisticValue,
      shouldRevert: (_) => false,
    );
  }
}
