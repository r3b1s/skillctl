#!/bin/bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: packaging/aur/render-pkgbuild.sh <tag> <sha256> [output-path]

Examples:
  packaging/aur/render-pkgbuild.sh v0.1.1 yourchecksum...
  packaging/aur/render-pkgbuild.sh v0.1.1 yourchecksum... packaging/aur/PKGBUILD
EOF
}

die() {
  echo "error: $*" >&2
  exit 1
}

[[ $# -ge 2 && $# -le 3 ]] || {
  usage >&2
  exit 1
}

tag="$1"
sha256="$2"
output_path="${3:-packaging/aur/PKGBUILD}"

[[ "$tag" =~ ^v[0-9]+(\.[0-9]+)*([.-][A-Za-z0-9]+)?$ ]] || die "tag must look like v0.1.1"
[[ "$sha256" =~ ^[0-9a-f]{64}$ ]] || die "sha256 must be a 64-character lowercase hex digest"

pkgver="${tag#v}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../.." && pwd)"
template_path="${repo_root}/packaging/aur/PKGBUILD.in"

[[ -f "$template_path" ]] || die "template not found: ${template_path}"

mkdir -p "$(dirname "$output_path")"
sed \
  -e "s/__PKGVER__/${pkgver}/g" \
  -e "s/__SHA256__/${sha256}/g" \
  "$template_path" > "$output_path"
