# claude-skills

Custom Claude Code skills (slash commands). Each `.md` file in `skills/` is a skill that can be invoked via `/skill-name` in any Claude Code session.

## Setup

### Prerequisites

- **Python 3** (for `/check-usage` and `/validate-models`)
- **Claude Code** installed and logged in (`claude login`)
- **roundtable** library (for `/roundtable` and `/validate-models`):
  ```bash
  pip install roundtable          # or: pip install -e ~/roundtable
  ```
- **Provider API keys** in `~/.config/keys.toml` (managed by chezmoi)

### Installation

#### 1. Clone the repo

```bash
# All environments
git clone https://github.com/j-goodz/claude-skills.git ~/claude-skills
```

#### 2. Symlink skills into Claude Code

**Linux / WSL / macOS:**
```bash
mkdir -p ~/.claude/commands
ln -sf ~/claude-skills/skills/*.md ~/.claude/commands/
```

**Windows (PowerShell, run as admin or with Developer Mode enabled):**
```powershell
mkdir -Force "$env:USERPROFILE\.claude\commands"
Get-ChildItem "$env:USERPROFILE\claude-skills\skills\*.md" | ForEach-Object {
    New-Item -ItemType SymbolicLink `
        -Path "$env:USERPROFILE\.claude\commands\$($_.Name)" `
        -Target $_.FullName -Force
}
```

#### 3. Verify

```bash
# Inside Claude Code, skills should appear:
/check-usage
/roundtable
/validate-models
```

### Updating skills

After pulling new changes (`git pull`), skills update automatically via symlinks. No need to re-run `chezmoi apply` or re-link.

### Chezmoi integration

Flat copies of each skill are also stored in the chezmoi dotfiles repo (`dot_claude/commands/`) for portability. The live `~/.claude/commands/` uses symlinks to this repo for instant updates during development.

**Dotfiles helper commands** (defined in `.bashrc`):
```bash
dotup            # Update configs/skills only — no KeePass password
dotup-secrets    # Update KeePass-backed secrets — prompts for password
dotup-all        # Full update: git pull + apply everything
```

## Skills

| Skill | Description | Dependencies |
|-------|-------------|--------------|
| `/check-usage` | Check Claude Code plan/limits and Gemini API status | Python 3 (stdlib only) |
| `/roundtable` | Run a multi-model deliberation on any question | roundtable, provider API keys |
| `/validate-models` | Check all roundtable model IDs against live provider APIs | roundtable, provider API keys |
| `/auto-compact` | Compact context after plan creation, then re-read the plan | None |
| `/delegate` | Delegate coding tasks to cheaper models (saves Opus usage limits) | roundtable, provider API keys |

## Adding a Skill

Create `skills/my-skill.md` with:
1. A one-line description (first line)
2. `## Instructions` section with step-by-step actions
3. `## Notes` section with context and caveats

Then symlink it:
```bash
ln -sf ~/claude-skills/skills/my-skill.md ~/.claude/commands/
```

## Environment-specific notes

### Cloud VPS (Hetzner)
- Python 3 and roundtable are installed system-wide
- Provider keys deployed via `dotup-secrets` (chezmoi + KeePass)
- SSH alias: `cloud`

### WSL (Windows laptop)
- Install Python 3: `sudo apt install python3 python3-pip`
- Install roundtable: `pip install -e ~/roundtable`
- KeePass database at `/mnt/c/Sync/KeePass/AI API Keys.kdbx`
- Symlinks work natively in WSL

### Windows (native PowerShell)
- Requires Developer Mode or admin privileges for symlinks
- Python 3 from [python.org](https://www.python.org/) or Windows Store
- Install roundtable: `pip install -e $env:USERPROFILE\roundtable`
- KeePass database at `G:/My Drive/KeePass/AI API Keys.kdbx`

## Dependencies

- [roundtable](https://github.com/j-goodz/roundtable) -- multi-model deliberation library
- Provider API keys in `~/.config/keys.toml`
- `GEMINI_API_KEY` env var (for `/check-usage` Gemini check)
