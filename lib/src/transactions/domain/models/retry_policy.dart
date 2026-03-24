import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:grumpy/grumpy.dart';

part 'retry_policy.freezed.dart';

/// Defines the retry behavior for operations that may fail.
///
/// Describes how many times an operation should be retried and how long to wait
/// between attempts.
///
/// Mutation code often wants explicit retry policy instead of hard-coded loops.
///
/// [RetryPolicy] stores a fixed delay and maximum attempt count.
///
/// [noRetry] still represents one execution attempt.
///
/// - [delay]: wait time between attempts.
/// - [maxAttempts]: total attempts including the first run.
///
/// For example:
/// ```dart
/// const RetryPolicy(
///   delay: Duration(milliseconds: 250),
///   maxAttempts: 3,
/// );
/// ```
///
/// {@category transactions}

@freezed
abstract class RetryPolicy extends Model with _$RetryPolicy {
  /// Creates a [RetryPolicy] with the specified [delay] and [maxAttempts].
  @Assert('maxAttempts > 0', 'maxAttempts must be greater than 0')
  const factory RetryPolicy({
    /// The duration to wait before each retry attempt.
    required Duration delay,

    /// The maximum number of retry attempts before giving up.
    required int maxAttempts,
  }) = _RetryPolicy;
  const RetryPolicy._();

  /// A [RetryPolicy] that does not perform any retries.
  static const noRetry = RetryPolicy(delay: Duration.zero, maxAttempts: 1);
}
