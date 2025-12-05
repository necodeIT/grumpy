// ignore_for_file: empty_constructor_bodies

import 'package:modular_foundation/modular_foundation.dart';

class ShouldError extends Repo<int> {
  // expect_lint: call_initialize_in_constructor
  ShouldError() {}
}

class CallingInitShouldNotError extends Repo<int> {
  CallingInitShouldNotError() {
    initialize();
  }
}

abstract class AbstractShouldNotError extends Repo<int> with UseRepoMixin {}
