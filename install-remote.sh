#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/r3b1s/skillctl.git"
TMPDIR=""

cleanup() {
  [[ -n "$TMPDIR" && -d "$TMPDIR" ]] && rm -rf "$TMPDIR"
}
trap cleanup EXIT

die() { echo "error: $*" >&2; exit 1; }

command -v git &>/dev/null || die "git is required for remote installation"

if [[ $# -eq 0 ]]; then
  set -- install
fi

TMPDIR="$(mktemp -d)"
git clone --depth 1 "$REPO_URL" "$TMPDIR/skillctl"

cd "$TMPDIR/skillctl"
SKILLCTL_INSTALL_METHOD=remote ./install.sh "$@"
