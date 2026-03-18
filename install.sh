#!/bin/bash
set -euo pipefail

SKILLCTL_REPO="https://raw.githubusercontent.com/r3b1s/skillctl/main/skillctl"
GUM_API="https://api.github.com/repos/charmbracelet/gum/releases/latest"
SKILLCTL_CONFIG="${HOME}/.config/skillctl"
META_FILE="${SKILLCTL_CONFIG}/.install-meta"

# Cleaned up on EXIT
_TMPDIR=""
_cleanup() { [[ -n "$_TMPDIR" ]] && rm -rf "$_TMPDIR"; }
trap _cleanup EXIT

# ── Utilities ─────────────────────────────────────────────────────────────────

die()  { echo "error: $*" >&2; exit 1; }
info() { echo "  $*"; }

http_get() {
  local url="$1" dest="$2"
  if command -v curl &>/dev/null; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget &>/dev/null; then
    wget -qO "$dest" "$url"
  else
    die "Neither curl nor wget found. Please install one."
  fi
}

http_stdout() {
  local url="$1"
  if command -v curl &>/dev/null; then
    curl -fsSL "$url"
  elif command -v wget &>/dev/null; then
    wget -qO- "$url"
  else
    die "Neither curl nor wget found. Please install one."
  fi
}

# ── Metadata ──────────────────────────────────────────────────────────────────

meta_get() {
  local key="$1"
  [[ -f "$META_FILE" ]] || { echo ""; return; }
  grep "^${key}=" "$META_FILE" 2>/dev/null | tail -1 | cut -d= -f2- || echo ""
}

meta_set() {
  local key="$1" val="$2"
  mkdir -p "$(dirname "$META_FILE")"
  local existing=""
  [[ -f "$META_FILE" ]] && existing=$(grep -v "^${key}=" "$META_FILE" || true)
  { [[ -n "$existing" ]] && printf '%s\n' "$existing"; echo "${key}=${val}"; } > "$META_FILE"
}

# ── gum bootstrap ─────────────────────────────────────────────────────────────

GUM_MANAGED_BY=""      # "pacman" | "dnf" | "brew" | "binary"
GUM_BINARY_STAGING=""  # path to staged gum binary before final install

_install_gum_binary() {
  _TMPDIR=$(mktemp -d)

  local os arch
  os="Linux"
  arch=$(uname -m)
  case "$arch" in
    x86_64)        arch="x86_64" ;;
    aarch64|arm64) arch="arm64"  ;;
    armv7*)        arch="armv7"  ;;
    *)             die "Unsupported architecture: $arch" ;;
  esac

  info "Fetching latest gum release info..."
  local json download_url
  json=$(http_stdout "$GUM_API")
  download_url=$(printf '%s' "$json" \
    | grep '"browser_download_url"' \
    | grep "\"${os}_${arch}" \
    | grep '\.tar\.gz"' \
    | head -1 \
    | sed 's/.*"browser_download_url": *"\([^"]*\)".*/\1/')

  [[ -n "$download_url" ]] || die "Could not find a gum release for ${os}_${arch}"

  info "Downloading gum..."
  http_get "$download_url" "$_TMPDIR/gum.tar.gz"
  tar -xzf "$_TMPDIR/gum.tar.gz" -C "$_TMPDIR"

  local gum_bin
  gum_bin=$(find "$_TMPDIR" -name "gum" -type f | head -1)
  [[ -n "$gum_bin" ]] || die "gum binary not found in downloaded archive"

  chmod +x "$gum_bin"
  GUM_BINARY_STAGING="$gum_bin"
  GUM_MANAGED_BY="binary"

  # Make gum immediately usable for the rest of this script
  export PATH="$(dirname "$gum_bin"):$PATH"
}

ensure_gum() {
  command -v gum &>/dev/null && return 0

  echo "gum not found — attempting to install..."

  if command -v pacman &>/dev/null; then
    info "Detected pacman → sudo pacman -S --noconfirm gum"
    sudo pacman -S --noconfirm gum
    GUM_MANAGED_BY="pacman"
  elif command -v dnf &>/dev/null; then
    info "Detected dnf → sudo dnf install -y gum"
    sudo dnf install -y gum
    GUM_MANAGED_BY="dnf"
  elif command -v brew &>/dev/null; then
    info "Detected brew → brew install gum"
    brew install gum
    GUM_MANAGED_BY="brew"
  else
    _install_gum_binary
  fi
}

# ── Install directory selection ───────────────────────────────────────────────

_add_to_path() {
  local dir="$1"
  local shell rc
  shell=$(basename "${SHELL:-bash}")

  case "$shell" in
    zsh)  rc="${HOME}/.zshrc" ;;
    fish) rc="${HOME}/.config/fish/config.fish" ;;
    bash) rc="${HOME}/.bashrc" ;;
    *)    rc="${HOME}/.profile" ;;
  esac

  if [[ "$shell" == "fish" ]]; then
    echo "fish_add_path \"$dir\"" >> "$rc"
  else
    echo "export PATH=\"$dir:\$PATH\"" >> "$rc"
  fi

  info "Added ${dir} to PATH in ${rc}"
  info "Restart your shell or run: source ${rc}"
}

select_install_dir() {
  # Parse PATH into unique, existing directories.
  # Use a pipe-delimited string to track seen entries without array issues.
  local seen_str="" dir
  local candidates=()

  while IFS= read -r dir; do
    [[ -z "$dir" ]] && continue
    [[ "$seen_str" == *"|${dir}|"* ]] && continue
    seen_str+="|${dir}|"
    [[ -d "$dir" ]] && candidates+=("$dir")
  done < <(printf '%s\n' "${PATH//:/$'\n'}")

  # Offer ~/.local/bin if it is not already in $PATH
  local local_bin="${HOME}/.local/bin"
  local NOTINPATH="[not in \$PATH — will be added automatically]"
  local local_bin_label="${local_bin}  ${NOTINPATH}"

  local all_items=("${candidates[@]+"${candidates[@]}"}")
  if [[ "$seen_str" != *"|${local_bin}|"* ]]; then
    all_items+=("$local_bin_label")
  fi

  [[ ${#all_items[@]} -eq 0 ]] && die "No directories found in \$PATH."

  local chosen
  chosen=$(printf '%s\n' "${all_items[@]}" | gum choose --header "Select installation directory:")

  if [[ "$chosen" == "$local_bin_label" ]]; then
    mkdir -p "$local_bin"
    _add_to_path "$local_bin"
    echo "$local_bin"
  else
    echo "$chosen"
  fi
}

# ── File helpers ──────────────────────────────────────────────────────────────

install_bin() {
  local src="$1" dest_dir="$2" name="$3"
  if [[ -w "$dest_dir" ]]; then
    install -m 755 "$src" "${dest_dir}/${name}"
  else
    info "${dest_dir} is not writable — using sudo"
    sudo install -m 755 "$src" "${dest_dir}/${name}"
  fi
}

remove_path() {
  local path="$1"
  if [[ -w "$(dirname "$path")" ]]; then
    rm -f "$path"
  else
    sudo rm -f "$path"
  fi
}

# ── install ───────────────────────────────────────────────────────────────────

cmd_install() {
  echo
  echo "==> Installing skillctl"
  echo

  ensure_gum

  local install_dir
  install_dir=$(select_install_dir)
  echo

  # Finalize gum installation (binary was staged before we knew the target dir)
  if [[ "$GUM_MANAGED_BY" == "binary" && -n "$GUM_BINARY_STAGING" ]]; then
    info "Installing gum to ${install_dir}..."
    install_bin "$GUM_BINARY_STAGING" "$install_dir" "gum"
    meta_set "gum_managed_by" "binary"
    meta_set "gum_path" "${install_dir}/gum"
  elif [[ -n "$GUM_MANAGED_BY" ]]; then
    meta_set "gum_managed_by" "$GUM_MANAGED_BY"
  fi

  info "Downloading skillctl..."
  local tmp_bin
  tmp_bin=$(mktemp)
  http_get "$SKILLCTL_REPO" "$tmp_bin"
  chmod +x "$tmp_bin"

  info "Installing skillctl to ${install_dir}..."
  install_bin "$tmp_bin" "$install_dir" "skillctl"
  rm -f "$tmp_bin"

  meta_set "install_dir" "$install_dir"

  echo
  echo "Done. skillctl installed to ${install_dir}/skillctl"
  echo "Run 'skillctl --help' to get started."
}

# ── update ────────────────────────────────────────────────────────────────────

cmd_update() {
  echo
  echo "==> Updating skillctl"
  echo

  local install_dir
  install_dir=$(meta_get "install_dir")

  if [[ -z "$install_dir" ]]; then
    if command -v skillctl &>/dev/null; then
      install_dir=$(dirname "$(command -v skillctl)")
    else
      die "Cannot find a previous skillctl installation. Run install first."
    fi
  fi

  info "Downloading latest skillctl from GitHub..."
  local tmp_bin
  tmp_bin=$(mktemp)
  http_get "$SKILLCTL_REPO" "$tmp_bin"
  chmod +x "$tmp_bin"

  info "Installing to ${install_dir}..."
  install_bin "$tmp_bin" "$install_dir" "skillctl"
  rm -f "$tmp_bin"

  echo
  echo "skillctl updated."
}

# ── uninstall ─────────────────────────────────────────────────────────────────

cmd_uninstall() {
  echo
  echo "==> Uninstalling skillctl"
  echo

  command -v gum &>/dev/null || die "gum is required for interactive prompts."

  local install_dir
  install_dir=$(meta_get "install_dir")

  if [[ -z "$install_dir" ]]; then
    if command -v skillctl &>/dev/null; then
      install_dir=$(dirname "$(command -v skillctl)")
    else
      die "Cannot find skillctl installation."
    fi
  fi

  # Gather all decisions BEFORE taking any action so gum stays available
  # throughout the entire prompt sequence.
  local remove_gum=false remove_config=false
  local gum_managed_by
  gum_managed_by=$(meta_get "gum_managed_by")

  if [[ -n "$gum_managed_by" ]]; then
    if gum confirm "Remove gum? (it was installed by this script)"; then
      remove_gum=true
    fi
    echo
  fi

  if [[ -d "$SKILLCTL_CONFIG" ]]; then
    gum style --foreground 196 \
      "WARNING: Removing config data will also remove all installed skill repos and their symlinks from your system."
    echo
    if gum confirm "Remove all skillctl data (${SKILLCTL_CONFIG})?"; then
      remove_config=true
    fi
    echo
  fi

  # Perform removals
  local skillctl_bin="${install_dir}/skillctl"
  if [[ -f "$skillctl_bin" ]]; then
    remove_path "$skillctl_bin"
    info "Removed ${skillctl_bin}"
  fi

  if $remove_gum; then
    if [[ "$gum_managed_by" == "binary" ]]; then
      local gum_path
      gum_path=$(meta_get "gum_path")
      if [[ -n "$gum_path" && -f "$gum_path" ]]; then
        remove_path "$gum_path"
        info "Removed ${gum_path}"
      fi
    else
      info "gum was installed via ${gum_managed_by} — remove it manually:"
      case "$gum_managed_by" in
        pacman) info "  sudo pacman -R gum" ;;
        dnf)    info "  sudo dnf remove gum" ;;
        brew)   info "  brew uninstall gum" ;;
      esac
    fi
  fi

  if $remove_config; then
    rm -rf "$SKILLCTL_CONFIG"
    info "Removed ${SKILLCTL_CONFIG}"
  elif [[ -f "$META_FILE" ]]; then
    # Config dir kept but meta file is now stale — remove it
    rm -f "$META_FILE"
  fi

  echo "skillctl uninstalled."
}

# ── entry point ───────────────────────────────────────────────────────────────

usage() {
  cat <<'EOF'
install.sh — installer for skillctl

Usage:
  ./install.sh [install]   Install skillctl and gum (default)
  ./install.sh update      Update skillctl to the latest version
  ./install.sh uninstall   Remove skillctl from your system
EOF
}

case "${1:-install}" in
  install)        cmd_install ;;
  update)         cmd_update ;;
  uninstall)      cmd_uninstall ;;
  -h|--help|help) usage ;;
  *) echo "Unknown command: $1" >&2; echo >&2; usage >&2; exit 1 ;;
esac
