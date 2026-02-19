import 'package:grumpy/grumpy.dart';

class MapProfileTxRepo extends Repo<Map<String, Profile>>
    with
        RepoLifecycleMixin<Map<String, Profile>>,
        RepoLifecycleHooksMixin<Map<String, Profile>>,
        TelemetryMixin,
        TransactionalMutationMixin<Map<String, Profile>> {
  MapProfileTxRepo() {
    installTransactionHooks();
  }

  @override
  String get logTag => 'MapProfileTxRepo';
}

class Profile {
  const Profile({required this.name, required this.status});

  final String name;
  final String status;

  Profile copyWith({String? name, String? status}) {
    return Profile(name: name ?? this.name, status: status ?? this.status);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Profile && other.name == name && other.status == status;
  }

  @override
  int get hashCode => Object.hash(name, status);

  @override
  String toString() => 'Profile(name: $name, status: $status)';
}
