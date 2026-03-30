Run a multi-model deliberation on the user's question using the Roundtable library.

## Instructions

The user wants to run a roundtable deliberation — multiple AI models analyze their question across rounds (independent analysis, cross-review, rebuttal), then synthesize a consensus.

1. Take the user's prompt (everything after `/roundtable`)

2. Determine which Python command works on this machine:
   - Try `python3 --version` first. If it works, use `python3`.
   - If not, try `python --version`. If it works, use `python`.

3. Check if roundtable is available locally:
   - Run: `<python> -c "from roundtable.core.keys import load_keys; print('local')"`
   - If that succeeds, run locally (step 4)
   - If it fails, try SSH fallback (step 5)

4. LOCAL execution (preferred):
```bash
<python> -m roundtable.cli.main run "PROMPT_HERE"
```
Read the output. If it fails or no models are available, fall back to step 5.

5. SSH fallback (only if local fails):
```bash
ssh cloud 'cd /home/justin/marketwatch && python3 -c "
from deliberation import run_general_deliberation
result = run_general_deliberation(\"\"\"PROMPT_HERE\"\"\")
" 2>&1'
```

6. Read the deliberation output
7. Synthesize the panel's findings into a clear, actionable response
8. Report: which models participated, how many rounds, key agreements/disagreements, consensus
9. State the API cost

## Notes
- The deliberation uses DeepSeek, Groq, Cerebras, and OpenRouter models
- Typical cost: $0.02-0.04 per deliberation
- Typical time: 2-5 minutes
- If models fail or rate-limit, report which ones and continue with available results
- Always specify model names when reporting which models said what
- SSH host alias is `cloud` (not cloud-server)
