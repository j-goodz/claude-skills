Save critical context to disk, compact, then restore — so nothing important is lost.

## Instructions

This skill replaces the built-in `/compact`. It writes a structured context snapshot to disk BEFORE compacting, then re-reads it after so you resume cleanly without amnesia.

### Step 1: Check Context Usage

Run `/context` to see current token count and percentage. Report to the user:

> Context: {tokens} tokens ({percentage}% used)

If `/context` is not available (older Claude Code version), skip this check and proceed.

If usage is below 40%, tell the user compaction isn't needed yet and ask if they want to proceed anyway. If they say no, stop here.

**Emergency mode:** If usage is above 90%, tell the user you're entering emergency compact mode. Skip Step 2 (git state) and keep the snapshot in Step 3 minimal — one line per section max. Speed matters more than detail when you're about to hit the wall.

### Step 2: Capture Git State

If the current directory is inside a git repo (check with `git rev-parse --is-inside-work-tree`), run these commands and note the output for Step 3:

```bash
git branch --show-current
git status --short
git log --oneline -5
```

If not a git repo, skip this — it's fine. Also skip if in emergency mode (Step 1).

### Step 3: Write Context Snapshot

Create or overwrite the file `.smart-compact.md` in the current working directory. If the directory is read-only, write to `/tmp/.smart-compact-{project-name}.md` instead and tell the user where it is.

Write it as a markdown file with these exact section headers. Fill in each section based on everything you know from this conversation. If a section has nothing relevant, write "None" under it — do NOT skip any section.

Use the Write tool to create this file (not bash echo/printf — this ensures cross-platform compatibility on Windows, WSL, and Linux).

**Section headers and what to write under each:**

`# Smart Compact Context` — followed by today's date and time

`## Current Task` — What you are currently working on. Be specific. Include step number if following a plan. In emergency mode, keep to one sentence.

`## Files Touched This Session` — Every file you read, created, or edited this session. One per line, with a brief note on what was done. Example format: `- /path/to/file.py — added validation to parse_input()`. In emergency mode, list paths only, no descriptions. Cap at 30 files — if more, list the 30 most recently touched.

`## Key Decisions Made` — Decisions and their reasoning. These are the hardest things to reconstruct after compaction. Example: `- Chose X over Y because {reason}`

`## Errors Encountered` — Any errors, failed attempts, or dead ends and how they were resolved.

`## Pending Work` — What still needs to be done. Use checkbox format. Be specific enough to resume without re-reading the full conversation.

`## Git State` — Paste the output from Step 2 (branch, status, recent commits). If not a git repo, write "Not a git repo." If emergency mode, write "Skipped (emergency mode)."

`## User Preferences Noted` — Anything the user said about how they want things done — tone, approach, tools to use or avoid, constraints.

`## Plan Reference` — If a plan file exists in the project (look for plan.md, TODO.md, PLAN.md, or any file the user designated as a plan), write its full path here. If no plan file exists, write "None."

### Step 4: Add to .gitignore

Only if the project is a git repo:

1. Check if `.gitignore` exists. If not, create it.
2. Check if `.smart-compact.md` is already listed in `.gitignore` (use grep to check).
3. If not listed, add it using the Edit tool (append to the file) or Write tool — do NOT use bash printf/echo, since those break on Windows.

If not a git repo, skip this step entirely.

### Step 5: Pre-Compact Announcement

This is critical. Before compacting, output this EXACT message to the user (it must appear in the conversation so the compact summary preserves it):

> SMART COMPACT: Context snapshot saved to .smart-compact.md
> AFTER COMPACTION: I must immediately read .smart-compact.md to restore working state.
> Current task: {one-line summary of current task}
> Files tracked: {count}
> Pending items: {count}
> Do not give me new instructions until I confirm restoration is complete.

This redundancy ensures key details survive in the compact summary even if the instruction to read the file gets compressed away.

### Step 6: Compact

Run `/compact` now.

### Step 7: Restore Context

**This step is the most important. Do this IMMEDIATELY after compaction — before responding to any user message.**

1. Check if `.smart-compact.md` exists in the current working directory (or `/tmp/.smart-compact-*.md` if the earlier write went to /tmp). Read it.
2. If the "Plan Reference" section names a file, read that file too.
3. Re-read the 1-2 most recently edited files from "Files Touched This Session" to get back into the code.
4. Tell the user: "Context restored from .smart-compact.md. Resuming: {current task}. Next step: {first pending item}."

If you find yourself post-compaction and DON'T remember these instructions, but you see ".smart-compact.md" mentioned in your compacted context — read that file. It will tell you everything you need.

### Step 8: Context Check Recommendation

After restoring, tell the user:

> Tip: Run `/context` periodically to check usage. Good time to run `/smart-compact` again:
> - 60% — consider it after finishing current task
> - 75% — do it soon
> - 85% — do it now

## Notes

- This replaces `/auto-compact`. Use `/smart-compact` instead.
- The context file is overwritten each compaction — it's a snapshot, not a log.
- Markdown format is intentional: Claude reads it naturally and humans can review it too.
- The file stays in the project root for easy access. It's gitignored so it won't pollute commits.
- If `/compact` itself fails (context too large), the snapshot is already on disk. Tell the user to start a new session with `claude --continue` and read `.smart-compact.md` as the first thing they do.
- Works with or without a formal plan file. Works with or without a git repo. Works on Linux, WSL, macOS, and Windows.
- For long sessions needing multiple compactions, each one overwrites the snapshot with fresh state. Still-relevant info carries forward because you re-read the previous snapshot before writing the new one.
- The Step 5 announcement is redundant on purpose — it puts key state into the conversation text so the compact summary captures it even if the instruction to read the file is lost.
- Emergency mode (>90% context) skips non-essential steps and writes a minimal snapshot to avoid running out of context during the compact process itself.
- **Safety net for restoration**: Consider adding this line to your project or global CLAUDE.md: `If .smart-compact.md exists in the project root, read it after any compaction or at the start of a continued session.` This guarantees restoration even if the compact summary is poor.
