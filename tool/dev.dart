// this is a tool script so a logging framework is lowkey overkill.
// ignore_for_file: avoid_print

import 'dart:io';

/// Sets up the development environment by copying `pubspec_overrides.dev.yaml` to `pubspec_overrides.yaml`.
/// This expects all other packages to be checked out in a sibling directory to the main `grumpy` package.
void main() async {
  final src = File('pubspec_overrides.dev.yaml');

  if (!await src.exists()) {
    print('No pubspec_overrides.dev.yaml found. Skipping.');
    return;
  }

  final dst = File('pubspec_overrides.yaml');

  await src.copy(dst.path);

  print('Copied pubspec_overrides.dev.yaml to pubspec_overrides.yaml');
}
