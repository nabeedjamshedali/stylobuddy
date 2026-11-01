#!/usr/bin/env bash
# The ONE documented way to run the F22 Firestore rules emulator suite
# (test/firestore_rules_test/) against a real Firestore emulator.
#
# Why this script exists (task-9 fix round, finding 4): `flutter test`
# (unlike bare `dart test`) has no `--preset`/`-P` flag, so the two
# load-bearing flags below cannot be bundled into a single dart_test.yaml
# preset the way a plain `dart test` project could — that approach was
# tried and confirmed broken ("Could not find an option or flag '-P'").
# Hardcoding both flags here, in the one script every doc/comment points
# at, gives the same guarantee a preset would have: nobody can invoke the
# suite while accidentally dropping just one of the two flags.
#
#   --run-skipped   overrides dart_test.yaml's `skip:` on the
#                   `firestore-rules` tag. Without it, `flutter test
#                   test/firestore_rules_test` reports "0 run, N skipped"
#                   and exits 0 even with no emulator reachable — a
#                   vacuous pass that F22-A01 explicitly forbids.
#   --concurrency=1 required because every test file's setUp clears the
#                   WHOLE emulator project's data (no per-file
#                   namespacing); flutter test's default concurrent-file
#                   execution lets one file's clearData() wipe another
#                   file's fixtures mid-test, producing spurious
#                   NOT_FOUND/denied failures unrelated to the rules.
#
# JAVA_HOME/PATH are scoped to the JDK 21 install for this command only —
# firebase-tools 15.24.0 requires Java 21+, but the system default JDK
# stays at 17 for everything else (task-9-brief.md environment note).
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

JAVA_HOME="/c/Program Files/Eclipse Adoptium/jdk-21.0.12.101-hotspot" \
PATH="/c/Program Files/Eclipse Adoptium/jdk-21.0.12.101-hotspot/bin:$PATH" \
firebase emulators:exec --only firestore --project demo-stylobuddy \
  "flutter test --run-skipped --concurrency=1 test/firestore_rules_test"
