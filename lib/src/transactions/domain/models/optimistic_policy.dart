import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:grumpy/grumpy.dart';

part 'optimistic_policy.freezed.dart';

/// Defines the optimistic update strategy for state modifications.
///
/// Describes how to compute an optimistic value and whether a failure should
/// revert it.
///
/// Legacy mutation flows need a small policy object for optimistic UI behavior.
///
/// The policy stores an [optimisticValue] transformer and a [shouldRevert]
/// predicate.
///
/// This policy is mainly used by the deprecated legacy mutation mixin. Prefer
/// transaction-based mutations for new code.
///
/// - `T`: the optimistic state type.
/// - [optimisticValue]: computes the projected state.
/// - [shouldRevert]: decides whether an error should roll back.
///
/// For example:
/// ```dart
/// OptimisticPolicy.alwaysRevert(
///   optimisticValue: (state) => state.copyWith(enabled: true),
/// );
/// ```
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
