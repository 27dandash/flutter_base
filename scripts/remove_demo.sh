#!/usr/bin/env bash
#
# Strips the bundled `products` demo feature from a fresh clone.
#
# The demo exists as the reference implementation (see
# lib/src/features/products/README.md). Once you've internalised the pattern,
# run this to remove it, then regenerate DI.
#
# Usage:
#   ./scripts/remove_demo.sh
#   dart run build_runner build --delete-conflicting-outputs
#
set -euo pipefail

DEMO="lib/src/features/products"

if [[ ! -d "$DEMO" ]]; then
  echo "✓ Demo already removed ($DEMO not found)."
  exit 0
fi

read -r -p "This deletes $DEMO and all its files. Continue? [y/N] " ans
case "$ans" in
  [yY]|[yY][eE][sS]) ;;
  *) echo "Aborted."; exit 1 ;;
esac

rm -rf "$DEMO"
echo "✓ Removed $DEMO"

# Warn if anything still references the demo (routes, navigation, etc.).
if grep -rn "features/products\|ProductsScreen\|ProductsCubit" lib >/dev/null 2>&1; then
  echo
  echo "⚠ Remaining references to the demo — clean these up manually:"
  grep -rn "features/products\|ProductsScreen\|ProductsCubit" lib || true
fi

echo
echo "Next: dart run build_runner build --delete-conflicting-outputs"
