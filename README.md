# skillctl

Manage agent skills across AI harnesses. By default, skills are **symlinked** — they live in one place and are linked into whichever harnesses and projects you choose, so updates to your skill repos propagate everywhere instantly. When you need a detached copy instead, use `--import`.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/r3b1s/skillctl/main/install.sh | bash
# or
bash install.sh          # update
bash install.sh uninstall
```

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

### `skillctl link [skill] [--global] [--project <path>] [--import]`

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
```

Imported copies are tracked in `~/.config/skillctl/imports`. They are **not** updated automatically when the source repo changes — `skillctl update` will warn you about stale imports and show you how to refresh them by re-running the link command with `--import`.

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

### `skillctl update`

`git pull` all installed repos. Because skills are symlinked, every project that references them picks up the changes with no further action.

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

Show all installed repos, their skills, and where each skill is currently linked.

```bash
skillctl list
```

## Why symlinks by default?

skillctl's default mode symlinks skills rather than copying them. Every harness directory that "has" a skill is actually pointing at a single source of truth — the cloned repo under `~/.config/skillctl/repos/`. This means:

- Edit a skill once, every project sees it immediately.
- Use SSH URLs for your own repos: `git push` and the skill updates everywhere, no re-import needed.
- Remove or update a repo with one command instead of hunting down copies across projects.

Use `--import` when you specifically need a detached, independent copy — for example, when a project needs to diverge from the canonical version of a skill.
