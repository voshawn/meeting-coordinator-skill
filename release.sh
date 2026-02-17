#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./release.sh <version>

Example:
  ./release.sh v1.0.3
EOF
}

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

VERSION="$1"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASES_DIR="$ROOT_DIR/releases"
RELEASE_DIR="$RELEASES_DIR/$VERSION"

REQUIRED_PATHS=(
  "$ROOT_DIR/SKILL.md"
  "$ROOT_DIR/README.md"
  "$ROOT_DIR/references"
  "$ROOT_DIR/scripts"
)

for path in "${REQUIRED_PATHS[@]}"; do
  if [[ ! -e "$path" ]]; then
    echo "Missing required path: $path" >&2
    exit 1
  fi
done

if [[ -e "$RELEASE_DIR" ]]; then
  echo "Release directory already exists: $RELEASE_DIR" >&2
  echo "Choose a new version or remove the existing directory first." >&2
  exit 1
fi

mkdir -p "$RELEASE_DIR"
cp "$ROOT_DIR/SKILL.md" "$RELEASE_DIR/"
cp "$ROOT_DIR/README.md" "$RELEASE_DIR/"
cp -R "$ROOT_DIR/references" "$RELEASE_DIR/"
cp -R "$ROOT_DIR/scripts" "$RELEASE_DIR/"

echo "Release created at: $RELEASE_DIR"
