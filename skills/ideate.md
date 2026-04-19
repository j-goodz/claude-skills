Scan recent work in the current project and surface novel ideas worth writing about. Drafts one-pagers to `~/papers-draft/ideas/`.

## Instructions

User typed `/ideate` (optionally with args). Goal: identify novel engineering solutions from their recent work, verify they're not already published, and capture as paper one-pagers.

### Step 1: Gather context from current project

```bash
cd "$PWD"
echo "=== Recent commits ==="
git log --oneline -20 2>/dev/null || echo "(not a git repo)"

echo "=== Files modified in last 7 days ==="
find . -type f \( -name "*.py" -o -name "*.md" -o -name "*.toml" \) -mtime -7 -not -path '*/\.*' -not -path '*/__pycache__/*' 2>/dev/null | head -20

echo "=== Current CLAUDE.md (if any) ==="
[ -f CLAUDE.md ] && head -80 CLAUDE.md
```

### Step 2: Check existing ideas (avoid duplicates)

```bash
ls ~/papers-draft/ideas/ 2>/dev/null
```

Read each existing one-pager briefly — don't re-pitch anything already captured.

### Step 3: Run roundtable to identify novel work

```bash
python3 -c "
from roundtable.core.engine import DeliberationEngine
from roundtable.core.panel import Panel
from roundtable.strategies.fixed_rounds import FixedRoundsStrategy

panel = Panel.from_config('/home/justin/roundtable/roundtable.toml')
reliable = ['deepseek-v3', 'deepseek-r1', 'groq-llama-4-scout', 'cerebras-qwen-3-235b']
strategy = FixedRoundsStrategy(rounds=2)
engine = DeliberationEngine(panel, strategy=strategy)
result = engine.run(
    content=open('/tmp/ideate_context.txt').read(),
    model_names=reliable, rounds=2, validate=True, auto_improve=True,
)
for rnd in result.rounds:
    for name, out in rnd.outputs.items():
        if out and not out.startswith('ERROR'):
            print(f'=== {name} (R{rnd.round_num}) ==='); print(out); print()
"
```

The prompt written to `/tmp/ideate_context.txt` should be:

> Review this recent work. Identify anything that could be a novel engineering contribution worth writing up as a short paper or blog post. For each candidate:
> 1. State what the user built/solved
> 2. What's novel about the approach (specific, not generic)
> 3. Check your knowledge: is this already a published paper, framework, or established pattern? Name any prior art you know.
> 4. Verdict: NOVEL / KNOWN / VARIANT (of known work with minor twist)
> 5. If NOVEL or strong VARIANT: draft a one-pager using this template:
>    # Title
>    ## Problem
>    ## Approach
>    ## What's Novel
>    ## Evidence
>    ## Status
>
> Be ruthlessly honest. Most engineering decisions aren't novel. Only flag genuinely new patterns.
>
> EXISTING IDEAS (skip these):
> [list from step 2]
>
> RECENT WORK:
> [from step 1]

### Step 4: Verify novelty against external sources (optional)

If the data-pipe MCP is available (check `claude mcp list`), use `mcp__data-pipe__search_web` to verify each candidate against known prior art before drafting. Search for: `<approach name> paper site:arxiv.org` and similar queries.

### Step 5: Write new one-pagers

For each NOVEL or strong VARIANT the panel surfaces:
1. Write to `~/papers-draft/ideas/<kebab-case-slug>.md`
2. Use the existing template (Problem / Approach / What's Novel / Evidence / Status)
3. Don't overwrite existing files — if slug conflicts, add a disambiguator

### Step 6: Report

Print a summary:
- Project scanned
- Candidates found
- Novel: [slugs of new one-pagers written]
- Known/Variant: [ideas the panel flagged as not novel, with reason]
- Files written

## Notes

- Run from inside ANY project directory — not just roundtable
- The point is to capture ideas AS YOU WORK across all projects (marketwatch, medvault, data-pipe, etc.)
- Be skeptical of "novel" claims — the panel should compare against known prior art
- Expected: most scans will produce 0-2 new ideas, that's fine
- Cost: ~$0.02 per scan using the reliable-only panel
- If nothing novel is found, say so and don't invent ideas
