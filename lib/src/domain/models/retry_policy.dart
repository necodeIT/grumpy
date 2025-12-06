import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:modular_foundation/modular_foundation.dart';

part 'retry_policy.freezed.dart';

/// Defines the retry behavior for operations that may fail.

@freezed
abstract class RetryPolicy with _$RetryPolicy implements Model {
  const RetryPolicy._();

  /// Creates a [RetryPolicy] with the specified [delay] and [maxAttempts].
  @Assert('maxAttempts > 0', 'maxAttempts must be greater than 0')
  const factory RetryPolicy({
    /// The duration to wait before each retry attempt.
    required Duration delay,

    /// The maximum number of retry attempts before giving up.
    required int maxAttempts,
  }) = _RetryPolicy;

  /// A [RetryPolicy] that does not perform any retries.
  static const noRetry = RetryPolicy(delay: Duration.zero, maxAttempts: 1);
}
