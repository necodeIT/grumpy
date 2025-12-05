import 'package:modular_foundation/modular_foundation.dart';

part 'retry_policy.freezed.dart';

@freezed
abstract class RetryPolicy<T> with _$RetryPolicy<T> implements Model {
  const factory RetryPolicy({
    required Duration timeout,
    required int maxAttempts,
  }) = _RetryPolicy;
}
