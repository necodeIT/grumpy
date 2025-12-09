// this is not production code; it's just for test linting
// ignore_for_file: empty_constructor_bodies

import 'package:modular_foundation/modular_foundation.dart';

void stub() {}

class ShouldError extends Repo<int> {
  // expect_lint: call_initialize_last
  ShouldError() {
    initialize();

    stub();
  }
}

class CallingInitLastShouldNotError extends Repo<int> {
  CallingInitLastShouldNotError() {
    stub();
    initialize();
  }
}

abstract class AbstractShouldNotError extends Repo<int> with UseRepoMixin {}
