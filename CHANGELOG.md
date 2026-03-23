## v0.1.2

### Harness Paths

- Changed `OpenAI Codex` to link and import skills under `.codex/skills/<skill>` and `~/.codex/skills/<skill>` instead of the shared `.agents` path.
- Kept the shared "Most harnesses (.agents/)" shortcut on `.agents/skills/` for the other harnesses that still follow that convention.
- Updated the harness picker copy and README harness table to clarify that OpenAI Codex is separate from the shared `.agents` target.

### Wipe

- Fixed `skillctl wipe` so tracked symlinks are discovered correctly when `clone-at` points to a non-default repo directory.
- Fixed `skillctl wipe .` and other relative target paths by normalizing wipe targets to canonical absolute paths before matching tracked entries.
- Added `-g` as a short alias for `skillctl wipe --global`.

### Shared State

- Added an opt-in `state-dir = "clone-at"` config mode so managed state can live under `<clone-at>/.skillctl-state/` instead of `~/.config/skillctl/`.
- Added `skillctl config set state-dir <config|clone-at>` so the managed state location can be changed without editing `config.toml` by hand.
- Added `skillctl sync-state` to recreate missing tracked symlinks or imported copies from the managed state file, which is useful when multiple installations share the same clone-at directory and state.
- Added `--force` / `-f` and `--yes` / `-y` to `skillctl sync-state` so conflicting existing targets can be overwritten intentionally, with batch confirmation by default.
- Updated `skillctl config list` to show both the active state mode and the resolved state path.
- Fixed `skillctl config set clone-at --yes` so it can create a missing target clone-at directory without prompting for TTY confirmation.

## v0.1.1

### Repo Storage

- Added `skillctl config set clone-at <path>` to configure where skill repos are cloned or copied.
- Added `skillctl config list` to show the current config values.
- Added interactive migration support when changing `clone-at`, including per-repo conflict handling and relinking of tracked symlinks for successfully migrated repos.
- Added an informational `~/.config/skillctl/orphans` file and `skillctl list` orphan reporting for repos left behind during migration failures.
- Changed repo discovery so active installed repos come from the configured `clone-at` directory instead of always assuming `~/.config/skillctl/repos`.

### Installation

- Split installation into a local installer (`install.sh`) and a remote bootstrapper (`install-remote.sh`).
- Changed the GitHub one-liner flow to clone a temporary checkout and run the local installer from that checkout.
- Added `skillctl-update` for installer-managed copies of skillctl.
- Added `skillctl-uninstall` for installer-managed copies of skillctl.
- Installer metadata now records install ownership, install method, and local install source so `skillctl-update` and `skillctl-uninstall` only operate on installer-managed installs.
- Package-manager installs are expected to handle updates and uninstallation through the package manager instead of `skillctl-update` or `skillctl-uninstall`.

### Import Overwrites

- Added `--force` / `-f` to `skillctl link --import` so existing targets can be overwritten intentionally.
- Added `--yes` / `-y` support for `skillctl link --import --force` to skip overwrite confirmation prompts.
- Changed import overwrites to use a single batch confirmation prompt instead of prompting once per skill.
- Updated the batch overwrite warning to summarize every destination that will be replaced and to state clearly that `--force` overwrites existing paths even when they are not tracked by skillctl.
- Updated stale-import refresh guidance to point users at re-running `skillctl link` with `--import --force`.

### Interactive Prompts

- Fixed `gum` confirmation prompts in loop-driven flows to read from `/dev/tty`, which restores interactive confirmation for import overwrites and imported-copy removal.
- Fixed `Ctrl+C` during interactive skill selection so `skillctl link` exits immediately instead of continuing on to the harness picker.
- Changed harness selection to use an explicit presentation order instead of alphabetical sorting, with the shared "Most harnesses" option first.
- Reordered the harness picker so `Claude Code`, `OpenCode`, `pi`, `OpenAI Codex`, and `Gemini CLI` appear at the top in that order.
- Updated the install location picker in `install.sh` to clarify that the listed destinations are the current entries from the user's `PATH`.

### Documentation

- Updated CLI help text and README examples to document the new `link --import --force [--yes]` workflow.
- Updated installation documentation to cover the local installer, remote bootstrapper, and installer-managed update and uninstall flow.

### Release Process

- Added a GitHub Actions release workflow to render `PKGBUILD`, regenerate `.SRCINFO`, and push AUR package updates automatically when a GitHub release is published.
- Added AUR packaging metadata scaffolding under `packaging/aur/` so release automation uses a tracked `PKGBUILD` template and render script instead of inlined workflow logic.
- Added a GitHub Actions shell CI workflow that runs `shellcheck` and `bash -n` on the project scripts, with CI configured to fail on `info`, `warning`, and `error` severity findings while still printing full ShellCheck output.
- Added maintainer-facing release documentation for the AUR publishing workflow and required GitHub secret setup.
