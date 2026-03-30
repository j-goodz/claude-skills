# CLAUDE.md -- claude-skills

Custom Claude Code skills repo. Each skill is a markdown file in `skills/` that gets symlinked to `~/.claude/commands/`.

## Structure

```
skills/          -- skill markdown files (one per skill)
tests/           -- validation scripts
README.md        -- setup and usage docs
```

## Adding Skills

Skills are markdown files with a one-line description, `## Instructions`, and `## Notes`. They tell Claude Code what to do when the user invokes `/skill-name`.

Skills should be self-contained and not assume prior context. They can call external tools (roundtable, git, etc.) via bash.

## NEVER

- Hardcode API keys or credentials in skill files
- Create skills that modify files without explicit user confirmation
- Add skills that duplicate built-in Claude Code commands (/help, /clear, etc.)
