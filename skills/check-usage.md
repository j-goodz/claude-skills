Check current usage limits for Claude Code and Gemini API.

## Instructions

Show the user their current usage and remaining quota for Claude Code (Anthropic) and Google Gemini.

1. Determine which Python command works on this machine:
   - Try `python3 --version` first. If it works, use `python3`.
   - If not, try `python --version`. If it works, use `python`.

2. Run the usage check script:
```bash
<python> -c "
import json, os, sys, time
from datetime import datetime, timezone
from urllib.request import Request, urlopen
from urllib.error import HTTPError

# ── Claude Code (local credentials) ──────────────────────────
print('=== Claude Code ===')
creds_path = os.path.expanduser('~/.claude/.credentials.json')
try:
    with open(creds_path) as f:
        creds = json.load(f)
    oauth = creds.get('claudeAiOauth', {})
    sub = oauth.get('subscriptionType', 'unknown')
    tier = oauth.get('rateLimitTier', 'unknown')
    expires = oauth.get('expiresAt')
    print(f'  Plan: {sub}')
    print(f'  Rate limit tier: {tier}')
    if expires:
        exp_dt = datetime.fromtimestamp(expires / 1000, tz=timezone.utc)
        print(f'  Token expires: {exp_dt.strftime(\"%Y-%m-%d %H:%M UTC\")}')
        if exp_dt < datetime.now(timezone.utc):
            print('  WARNING: Token is expired — run: claude login')
    print()
    print('  Live session usage (run inside Claude Code):')
    print('    /usage  — shows 5-hour and 7-day usage percentages')
except FileNotFoundError:
    print('  No credentials file at ~/.claude/.credentials.json')
    print('  Run: claude login')
except Exception as e:
    print(f'  ERROR: {e}')

print()

# ── Gemini API ────────────────────────────────────────────────
print('=== Gemini API ===')
gemini_key = os.environ.get('GEMINI_API_KEY', '')
if not gemini_key:
    print('  SKIP: GEMINI_API_KEY not set')
else:
    try:
        url = f'https://generativelanguage.googleapis.com/v1beta/models?key={gemini_key}'
        req = Request(url)
        resp = urlopen(req, timeout=15)
        data = json.loads(resp.read())
        models = [m['name'].split('/')[-1] for m in data.get('models', [])
                  if 'gemini' in m.get('name', '').lower()]
        print(f'  API key is valid')
        print(f'  Available Gemini models: {len(models)}')
        for m in sorted(models):
            if any(k in m for k in ['flash', 'pro', '2.5', '2.0', '3']):
                print(f'    - {m}')

        # Show rate limit info from headers if present
        limit_headers = {k: v for k, v in resp.headers.items()
                         if 'limit' in k.lower() or 'quota' in k.lower()
                         or 'remaining' in k.lower() or 'retry' in k.lower()}
        if limit_headers:
            print('  Rate limit headers:')
            for k, v in limit_headers.items():
                print(f'    {k}: {v}')
        else:
            print()
            print('  Default rate limits (free tier):')
            print('    Flash:  15 RPM / 1M TPM / 1,500 RPD')
            print('    Pro:     2 RPM / 32K TPM / 50 RPD')
            print('  (Google does not expose a programmatic quota endpoint)')
    except HTTPError as e:
        body = e.read().decode() if e.fp else ''
        print(f'  ERROR: HTTP {e.code}')
        if body:
            try:
                err = json.loads(body)
                print(f'  {err.get(\"error\", {}).get(\"message\", body[:300])}')
            except Exception:
                print(f'  {body[:300]}')
    except Exception as e:
        print(f'  ERROR: {e}')

print()

# ── Roundtable API Costs ────────────────────────────────────
print('=== Roundtable Delegated Work ===')
try:
    rt_reliability = os.path.expanduser('~/.local/share/roundtable/model_reliability.json')
    if os.path.isfile(rt_reliability):
        with open(rt_reliability) as f:
            rel_data = json.load(f)
        total_calls = 0
        for model, events in rel_data.items():
            if isinstance(events, list):
                total_calls += len(events)
        print(f'  Models tracked: {len(rel_data)}')
        print(f'  Total delegated calls: {total_calls}')
    else:
        print('  No reliability data yet (run roundtable first)')

    # Check model_profiles.json for learned data
    profiles = [os.path.expanduser(p) for p in [
        '~/roundtable/model_profiles.json',
        'model_profiles.json',
    ]]
    for p in profiles:
        if os.path.isfile(p):
            with open(p) as f:
                learned = json.load(f)
            if learned:
                print(f'  Learned profiles: {len(learned)} models with adjustments')
            break
except Exception as e:
    print(f'  ERROR: {e}')

print()
print('=== Cost Saving Tips ===')
print('  Use /delegate for code generation (DeepSeek V3: ~\$0.001/call)')
print('  Use /roundtable for research/analysis (~\$0.02-0.04/deliberation)')
print('  Save Opus tokens for: orchestration, complex reasoning, multi-file edits')
print('  Run /usage to see live Claude Code limit status')
"
```

3. Present the results to the user:
   - **Claude Code**: Plan type, rate limit tier, token expiry status
   - **Gemini**: Key validity, available models, and applicable rate limits
   - If any check failed, explain what went wrong and how to fix it
   - Remind the user that `/usage` inside Claude Code shows live session percentages

## Notes
- Claude Code plan/tier info comes from `~/.claude/.credentials.json` (no network call needed)
- Live session usage (5-hour window, 7-day window) is only available via `/usage` inside an active Claude Code session — there is no external API for this
- Gemini has no programmatic quota-check endpoint; we validate the key and list available models
- `GEMINI_API_KEY` env var is expected for the Gemini check
- This skill uses only stdlib (`urllib`) — no `requests` dependency required
- If the OAuth token is expired, suggest `claude login` to refresh it
