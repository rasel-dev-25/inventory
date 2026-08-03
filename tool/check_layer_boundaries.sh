#!/usr/bin/env bash
# Enforces the import-direction rules described in ARCHITECTURE.md.
#
# There is no first-party analyzer lint for "this layer must not import
# that layer", and pulling in a full custom_lint plugin for a single-shop
# app is more machinery than the problem needs. A grep-based CI check gets
# the same practical result — a red build the moment someone writes
# `import 'package:flutter/material.dart'` inside lib/domain/ — for a
# fraction of the setup cost. If the project outgrows this, replacing it
# with a real custom_lint rule is a contained follow-up, not a rewrite.
set -euo pipefail

cd "$(dirname "$0")/.."

fail=0

check() {
  local layer_dir="$1"
  local forbidden_pattern="$2"
  local description="$3"

  if [ ! -d "$layer_dir" ]; then
    return 0
  fi

  local matches
  matches=$(grep -rnE "$forbidden_pattern" "$layer_dir" --include="*.dart" || true)
  if [ -n "$matches" ]; then
    echo "❌ Layer boundary violation: $description"
    echo "$matches"
    echo ""
    fail=1
  fi
}

# domain/ is pure Dart — it must never import Flutter, Drift, or Supabase.
# This is the guarantee that every calculation in the domain layer (profit
# split, purchase reconciliation, rent pricing) is a plain function you can
# unit test with `dart test`, with zero widget/database ceremony, and the
# guarantee that a UI change can never accidentally alter a money formula.
check "lib/domain" \
  "^import '(package:flutter|package:drift|package:supabase|package:get)" \
  "lib/domain/** must not import Flutter, Drift, Supabase, or GetX"

# data/ (repositories, DAOs, DTOs, sync engine) must not import Flutter
# widget code — it has no business building UI.
check "lib/data" \
  "^import 'package:flutter/(material|cupertino|widgets)\.dart'" \
  "lib/data/** must not import Flutter widget libraries"

# core/ is shared infrastructure with no business knowledge — it must never
# import a feature module or the domain layer's entities. Dependencies
# point inward (features -> domain -> nothing; features/data -> core), never
# the other way.
check "lib/core" \
  "^import '(package:inventory/features|\.\./\.\./features|\.\./features)" \
  "lib/core/** must not import lib/features/**"

if [ "$fail" -ne 0 ]; then
  echo "One or more architectural layer boundaries were violated. See ARCHITECTURE.md."
  exit 1
fi

echo "✅ Layer boundaries OK"
