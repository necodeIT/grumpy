import 'package:grumpy/grumpy.dart';

/// A service interface for recording product and user analytics events.
///
/// The [AnalyticsService] defines a unified abstraction for **behavioral and
/// product analytics**, describing *what users do*, rather than *what the
/// system does*. It provides a vendor-agnostic API for event tracking,
/// user identification, navigation, and group association.
///
///
/// ## Overview
///
/// The purpose of this service is to give a consistent interface across
/// analytics backends (e.g. PostHog, Mixpanel, Amplitude, Segment).
/// Implementations should translate these calls into backend-specific API calls.
///
/// Common use cases:
/// - Tracking user interactions or conversion events
/// - Identifying users after login or signup
/// - Tracking navigation between pages or screens
/// - Aggregating users under organizations or groups
///
///
/// ## Difference from [TelemetryService]
///
/// - **TelemetryService** → system observability (errors, spans, performance)
/// - **AnalyticsService** → user behavior (clicks, navigation, funnels)
///
///
/// ## Implementation details
///
/// - All methods return `Future<void>` to encourage **fire-and-forget** behavior.
/// - Each concrete implementation should handle user/session context and
///   backend-specific payload translation.
/// - Optional parameters are safe to omit; unused fields can be ignored.
///
///
/// ## Example
///
/// ```dart
/// class PosthogAnalyticsService extends Service implements AnalyticsService {
///   final Posthog posthog;
///
///   PosthogAnalyticsService(this.posthog);
///
///   @override
///   Future<void> identifyUser(String userId, {Map<String, dynamic>? traits}) async {
///     posthog.identify(userId: userId, properties: traits);
///   }
///
///   @override
///   Future<void> trackEvent(String name, {Map<String, dynamic>? properties}) async {
///     posthog.capture(eventName: name, properties: properties);
///   }
///
///   @override
///   Future<void> recordPageView(String pageName, {Map<String, dynamic>? properties}) async {
///     posthog.capture(eventName: '$pageview', properties: {
///       'page': pageName,
///       ...?properties,
///     });
///   }
///
///   @override
///   Future<void> recordNavigation(String from, String to, {Map<String, dynamic>? properties}) async {
///     posthog.capture(eventName: '$screen', properties: {
///       'from': from,
///       'to': to,
///       ...?properties,
///     });
///   }
///
///   @override
///   Future<void> group(String groupId, {Map<String, dynamic>? traits}) async {
///     posthog.group(groupType: 'organization', groupKey: groupId, groupProperties: traits);
///   }
/// }
/// ```
///
///
/// ## See also
/// - [TelemetryService] — for technical and operational observability
/// - [TelemetryZoneMixin] — for zone-based tracing
/// - [TelemetryContext] — for span execution context
///
abstract class AnalyticsService extends Service {
  /// Identifies a user within the analytics system.
  ///
  /// Should be called once the user is known (e.g., after login or signup).
  ///
  /// [userId] — a stable unique identifier (e.g., database ID or auth UID).
  /// [traits] — persistent user properties (email, plan, locale, signup source, etc).
  Future<void> identifyUser(String userId, {Map<String, dynamic>? traits});

  /// Records a user-driven event such as a button click, feature use, or funnel milestone.
  ///
  /// [name] — descriptive event name (e.g., `"Button Clicked"`, `"Project Created"`).
  /// [properties] — contextual info (e.g., `"screen": "dashboard"`, `"method": "google"`).
  Future<void> trackEvent(String name, {Map<String, dynamic>? properties});

  /// Records a page or screen view.
  ///
  /// Intended for navigation analytics and screen engagement tracking.
  ///
  /// [pageName] — name or route identifier of the viewed page/screen.
  /// [properties] — optional additional attributes (e.g., `"referrer": "home"`).
  ///
  /// Example:
  /// ```dart
  /// await analytics.recordPageView('SettingsPage');
  /// ```
  Future<void> recordPageView(
    String pageName, {
    Map<String, dynamic>? properties,
  });

  /// Records a navigation event between two pages or routes.
  ///
  /// Useful for measuring user flow or app navigation funnels.
  ///
  /// [from] — the previous page or route name.
  /// [to] — the destination page or route name.
  /// [properties] — optional contextual info (e.g., `"method": "tap"`, `"via": "deep_link"`).
  ///
  /// Example:
  /// ```dart
  /// await analytics.recordNavigation('HomePage', 'SettingsPage');
  /// ```
  Future<void> recordNavigation(
    String from,
    String to, {
    Map<String, dynamic>? properties,
  });

  /// Associates a user with a group or organization.
  ///
  /// Useful for multi-tenant or B2B applications where analytics should
  /// aggregate by organization, workspace, or team.
  ///
  /// [groupId] — unique identifier for the group/organization.
  /// [traits] — group-level properties (plan, employee count, region, etc).
  Future<void> groupUser(String groupId, {Map<String, dynamic>? traits});
  @override
  String get group => '${super.group}.AnalyticsService';
}
