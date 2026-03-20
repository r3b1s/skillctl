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
