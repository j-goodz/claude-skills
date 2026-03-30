# claude-skills

Custom Claude Code skills (slash commands). Each `.md` file in `skills/` is a skill that can be invoked via `/skill-name` in any Claude Code session.

## Setup

Symlink into Claude's commands directory:

```bash
# Link all skills
ln -sf ~/claude-skills/skills/*.md ~/.claude/commands/

# Or use chezmoi (add to .chezmoiexternal.toml):
# [".claude/commands"]
#   type = "archive"
#   url = "https://github.com/j-goodz/claude-skills/archive/main.tar.gz"
#   stripComponents = 2
#   include = ["*/skills/*"]
```

## Skills

| Skill | Description |
|-------|-------------|
| `/roundtable` | Run a multi-model deliberation on any question |
| `/validate-models` | Check all roundtable model IDs against live provider APIs |

## Adding a Skill

Create `skills/my-skill.md` with:
1. A one-line description (first line)
2. `## Instructions` section with step-by-step actions
3. `## Notes` section with context and caveats

## Dependencies

- [roundtable](https://github.com/j-goodz/roundtable) -- multi-model deliberation library
- Provider API keys in `~/.config/keys.toml`
