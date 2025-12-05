import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:modular_foundation/modular_foundation.dart';

mixin MutationMixins<T> on Repo<T>, RepoLifecycleHooksMixin<T> {
  bool _installed = false;

  @mustCallInConstructor
  void installMutationHooks() {
    if (_installed) return;

    _installed = true;
  }

  /// Runs a stateful mutation on the repo's current data with telemetry + analytics.
  ///
  /// - [name] is the logical name of the mutation (also used for the span name).
  /// - [mutation] is called with the current data and returns the new value.
  /// - [attributes] (optional) are attached as analytics event properties.
  /// - [eventName] (optional) overrides the default `mutation_<name>` event key.
  ///
  /// Behavior:
  /// - Throws a [StateError] if [installMutationHooks] was not called.
  /// - Returns `null` if the repo has no data or if an error occurs.
  /// - Wraps the mutation in a telemetry span and tracks an analytics event.
  Future<T?> mutate(
    String name,
    FutureOr<T?> Function(T currentData) mutation, {
    Map<String, String>? attributes,
    String? eventName,
    bool setErrorState = true,
    bool setLoading = false,
  }) async {
    eventName ??= 'mutation_$name';

    if (!_installed) {
      throw StateError(
        'Mutation hooks are not installed. Please call installMutationHooks() in the constructor.',
      );
    }

    if (!state.hasData) {
      log('Cannot perform mutation $name: Repo has no data');
      return null;
    }

    final telemetry = GetIt.I.get<TelemetryService>();
    final analytics = GetIt.I.get<AnalyticsService>();

    try {
      await analytics.trackEvent(eventName, properties: attributes);
      return await telemetry.runSpan(name, () => mutation(state.requireData));
    } catch (e, st) {
      log('Error during mutation $name', e, st);
      return null;
    }
  }

  /// Runs a side-effecting action with telemetry + analytics, without repo data.
  ///
  /// - [name] is the logical name of the action (also used for the span name).
  /// - [action] is the callback to execute.
  /// - [attributes] (optional) are attached as analytics event properties.
  /// - [eventName] (optional) overrides the default `mutation_<name>` event key.
  ///
  /// Behavior:
  /// - Throws a [StateError] if [installMutationHooks] was not called.
  /// - Wraps the action in a telemetry span and tracks an analytics event.
  /// - Logs but swallows errors; failures do not throw.
  ///
  /// Similar to [mutate], but does not provide the current data.
  Future<void> action(
    String name,
    FutureOr<T> Function() action, {
    Map<String, String>? attributes,
    String? eventName,
  }) async {
    eventName ??= 'action_$name';

    if (!_installed) {
      throw StateError(
        'Mutation hooks are not installed. Please call installMutationHooks() in the constructor.',
      );
    }

    final telemetry = GetIt.I.get<TelemetryService>();
    final analytics = GetIt.I.get<AnalyticsService>();

    try {
      await analytics.trackEvent(eventName, properties: attributes);
      await telemetry.runSpan(name, action);
    } catch (e, st) {
      log('Error during action $name', e, st);
    }
  }
}
