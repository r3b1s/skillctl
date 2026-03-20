# skillctl
Manage agent skills across AI harnesses. Built with `git` source control in mind. By default, skills are **symlinked** — they live in one place and are linked into whichever harnesses and projects you choose, so updates to your skill repos propagate everywhere instantly. When you need a detached copy instead, use `--import`.

No extra bells and whistles. By design, this is *not* a skill browser or search engine. It doesn't include any built-in skills.

This a simple tool for explicitly specifying remote repositories / local directories as single sources of truth for agent skills. This let's you maintain version control via `git` without accidentally losing changes across multiple project directories.


https://github.com/user-attachments/assets/4b9c91a7-24e8-467b-a8e8-28ccef5079d7




## Installation

```bash
# One-liner install from GitHub
curl -fsSL https://raw.githubusercontent.com/r3b1s/skillctl/main/install-remote.sh | bash

# Local install from a git clone
git clone https://github.com/r3b1s/skillctl.git
cd skillctl
bash install.sh

# Update an installer-managed copy
skillctl-update

# Uninstall an installer-managed copy
skillctl-uninstall
```
### Arch Linux
You can also install `skillctl` via the AUR (https://aur.archlinux.org/packages/skillctl).

Just use your preferred package manager:

```
# yay
yay -S skillctl

# paru
paru -S skillctl
```

When installed via a package manager, manage updates and uninstallation with that package manager. `skillctl-update` and `skillctl-uninstall` are only intended for copies installed by `install.sh` or `install-remote.sh`.

## Supported harnesses

skillctl has built-in support for the following AI coding harnesses:

| Harness | Per-project directory | Global directory |
|---|---|---|
| Claude Code | `.claude/skills/<skill>` | `~/.claude/skills/<skill>` |
| Cursor | `.cursor/skills/<skill>` | `~/.cursor/skills/<skill>` |
| KiloCode | `.kilocode/skills/<skill>` | `~/.kilocode/skills/<skill>` |
| GitHub Copilot | `.github/skills/<skill>` | `~/.github/skills/<skill>` |
| cline | `.cline/skills/<skill>` | `~/.cline/skills/<skill>` |
| goose | `.goose/skills/<skill>` | `~/.goose/skills/<skill>` |
| pi | `.pi/skills/<skill>` | `~/.pi/skills/<skill>` |
| Qwen | `.qwen/skills/<skill>` | `~/.qwen/skills/<skill>` |
| OpenAI Codex | `.agents/skills/<skill>` | `~/.agents/skills/<skill>` |
| OpenCode | `.agents/skills/<skill>` | `~/.agents/skills/<skill>` |
| Gemini CLI | `.agents/skills/<skill>` | `~/.agents/skills/<skill>` |
| amp | `.agents/skills/<skill>` | `~/.agents/skills/<skill>` |
| Warp | `.agents/skills/<skill>` | `~/.agents/skills/<skill>` |

Many harnesses have converged on `.agents/skills/` as a shared convention. When selecting harnesses during `skillctl link`, you'll see a **"Most harnesses (.agents/)"** shortcut at the top of the list — this targets the `.agents/skills/` directory and covers Codex, Gemini, amp, Warp, OpenCode, and any other tool that follows the same convention. If you're unsure which harness-specific directory to use, `.agents/` is a reasonable default since it gives you the widest coverage with a single symlink.

## Commands

### `skillctl install <url|path>`

Clone a remote skill repo or register a local one. Accepts HTTPS or SSH URLs.

```bash
# Public repo over HTTPS
skillctl install https://github.com/example/my-skills

# Your own private repo over SSH — edits you push are reflected everywhere immediately
skillctl install git@github.com:you/my-skills

# Local directory (useful during development)
skillctl install ~/dev/my-skills
```

The repo must contain a `skills/` directory at its root. Each subdirectory inside `skills/` is treated as one skill.

---

### `skillctl config set clone-at <path>`

Change the directory where skill repos are cloned or copied. By default, skillctl uses `~/.config/skillctl/repos`. The configured path is stored in `~/.config/skillctl/config.toml`.

If repos are already installed in the current active clone directory, skillctl will ask whether you want to migrate them. Successful migrations move the repo, tear down tracked symlinks for that repo, and re-link them to the new location. Repos that fail migration are added to `~/.config/skillctl/orphans` for visibility.

```bash
# Change the active clone location
skillctl config set clone-at ~/Library/Mobile\ Documents/com~apple~CloudDocs/skillctl/repos

# Change the active clone location and request migration up front
skillctl config set clone-at ~/Dropbox/skillctl/repos --migrate
```

If you choose not to migrate, the new path becomes active immediately and the old repos are left in place as unmanaged leftovers.

### `skillctl config list`

Show the current config values, including the active clone location.

```bash
skillctl config list
```

---

### `skillctl link [skill] [--global] [--project <path>] [--import] [--force|-f] [--yes|-y]`

Symlink one or more skills into one or more harnesses. Without flags, links into the current directory. `--global` links into `$HOME`.

```bash
# Interactive: pick skills and harnesses via gum
skillctl link

# Link a specific skill globally
skillctl link my-skills/my-skill --global

# Link a skill into a specific project
skillctl link my-skills/my-skill --project ~/dev/myproject
```

If multiple harnesses share the same target path (e.g. several use `.agents/skills/`), the symlink is only created once.

#### `--import` — copy instead of symlink

Use `--import` when you need a detached copy of a skill rather than a live symlink. The skill's files are copied directly into the target directory.

```bash
# Import a skill globally (copy, not symlink)
skillctl link my-skills/my-skill --import --global

# Import into a specific project
skillctl link my-skills/my-skill --import --project ~/dev/myproject

# Overwrite an existing imported target after confirmation
skillctl link my-skills/my-skill --import --force --project ~/dev/myproject

# Overwrite an existing imported target without prompting
skillctl link my-skills/my-skill --import --force --yes --project ~/dev/myproject
```

If an import target already exists, `skillctl link --import` will leave it in place unless you add `--force` (or `-f`). With `--force`, skillctl shows one confirmation for the whole batch and lists every destination that will be overwritten. That overwrite applies whether or not the existing path is tracked by skillctl. Add `--yes` (or `-y`) to skip the prompt.

Managed symlinks and imported copies are tracked in `~/.config/skillctl/managed`. Imported copies are **not** updated automatically when the source repo changes — `skillctl update` will warn you about stale imports and show you how to refresh them by re-running the link command with `--import --force`.

---

### `skillctl unlink [skill] [--global] [--project <path>]`

Remove symlinks and imported copies. Without a skill argument, shows all currently linked or imported skills to choose from.

```bash
# Interactive: pick linked/imported skills to remove
skillctl unlink

# Remove a specific skill's global symlinks
skillctl unlink my-skill --global
```

When removing an imported copy (as opposed to a symlink), you'll be warned that any local changes will be lost and prompted to confirm before deletion.

---

### `skillctl wipe [target-dir] [--global] [--imports] [--all] [--yes|-y]`

Clear a whole target location rather than removing skills one by one. By default, `wipe` removes tracked symlinks under the current directory's harness skill folders.

```bash
# Remove all tracked symlinks under the current project
skillctl wipe

# Remove all tracked symlinks under a specific project
skillctl wipe ~/dev/myproject

# Remove all tracked global symlinks
skillctl wipe --global

# Also remove tracked imported copies
skillctl wipe --imports

# Remove every tracked symlink everywhere
skillctl wipe --all
```

`wipe` only removes files and directories explicitly tracked by `skillctl`. Unmanaged directories are ignored, even if they live under a harness skills folder. With `--imports`, `wipe` also removes tracked imported copies after an additional warning that local changes will be permanently deleted.

`--all` ignores the target directory and wipes every tracked symlink in the managed state file. Combined with `--imports`, it also removes every tracked imported copy.

---

### `skillctl update`

`git pull` all installed repos in the currently active clone directory. Because skills are symlinked, every project that references them picks up the changes with no further action.

```bash
skillctl update
```

---

### `skillctl uninstall <repo-name>`

Remove a repo and all symlinks pointing into it across your home directory.

```bash
skillctl uninstall my-skills
```

---

### `skillctl list`

Show all installed repos from the active clone directory, their skills, and where each skill is currently linked. If migration left any orphaned repos behind, they are shown in a separate `Orphans` section.

```bash
skillctl list
```

## Why symlinks by default?

skillctl's default mode symlinks skills rather than copying them. Every harness directory that "has" a skill is actually pointing at a single source of truth — the cloned repo under the active `clone-at` directory. By default, that is `~/.config/skillctl/repos/`. This means:

- Edit a skill once, every project sees it immediately.
- Use SSH URLs for your own repos: `git push` and the skill updates everywhere, no re-import needed.
- Remove or update a repo with one command instead of hunting down copies across projects.

Use `--import` when you specifically need a detached, independent copy — for example, when a project needs to diverge from the canonical version of a skill.
