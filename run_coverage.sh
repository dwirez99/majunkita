#!/bin/bash
# run_coverage.sh
#
# Runs the full test suite with coverage collection.
#
# WHY: flutter test --coverage writes lcov.info ALL AT ONCE at the end.
#      widget_test.dart loads the full Flutter rendering pipeline and crashes
#      the flutter_tester binary during coverage finalization, dropping ALL
#      collected data. We must pass an explicit file list that excludes it.
#      flutter test does NOT honour dart_test.yaml `exclude` keys.
#
# Usage: bash run_coverage.sh

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🧪  Running unit & repository tests (with coverage)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Build explicit file list — exclude widget_test.dart
TEST_FILES=$(find test -name "*_test.dart" ! -name "widget_test.dart" | sort | tr '\n' ' ')

# shellcheck disable=SC2086
flutter test --coverage $TEST_FILES

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🧪  Running widget test (no --coverage)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
flutter test test/widget_test.dart --no-pub

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📊  Coverage report"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  lcov data : coverage/lcov.info"

if command -v genhtml &>/dev/null; then
  genhtml coverage/lcov.info \
    --output-directory coverage/html \
    --title "Majunkita Coverage" \
    --quiet
  echo "  HTML report: coverage/html/index.html"
else
  echo "  (Install lcov for an HTML report: sudo apt install lcov)"
fi

echo ""
echo "✅  All done!"
