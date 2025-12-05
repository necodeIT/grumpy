// ignore_for_file: empty_constructor_bodies

import 'package:modular_foundation/modular_foundation.dart';

abstract class ShouldError extends Repo<int> {
  // expect_lint: avoid_abstract_initialize_calls
  ShouldError() {
    initialize();
  }
}

abstract class NotCallingInitializeShouldNotError extends Repo<int>
    with UseRepoMixin {
  NotCallingInitializeShouldNotError() {
    // No lint expected here
  }
}
