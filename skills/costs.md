Show unified cost dashboard: provider balances, lifetime spend, delegation activity, and estimated Claude savings.

## Instructions

When the user runs `/costs`, show a consolidated view of every tracked API spend source plus delegation activity. Run this Python script:

```bash
python3 << 'PYEOF'
import json, os, sys
from datetime import datetime, timezone, timedelta
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

# --- Placeholder: estimated Claude cost per task avoided by /delegate ---
# This is a ROUGH estimate. Anthropic does not expose a usage API for Claude
# Code subscriptions, so we cannot compute true savings. Treat as directional.
ESTIMATED_CLAUDE_COST_PER_DELEGATED_TASK = 0.015

def _get_json(url, key, timeout=5):
    req = Request(url, headers={"Authorization": f"Bearer {key}"})
    with urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())

def _load_env_keys(path, prefix):
    keys = {}
    path = os.path.expanduser(path)
    if not os.path.exists(path):
        return keys
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line.startswith("#") or "=" not in line: continue
            if line.startswith("export "): line = line[7:]
            k, v = line.split("=", 1)
            k = k.strip()
            if k.startswith(prefix):
                keys[k] = v.strip().strip('"').strip("'")
    return keys

print("=" * 60)
print("  COST & DELEGATION DASHBOARD")
print("  " + datetime.now().strftime("%Y-%m-%d %H:%M"))
print("=" * 60)

# --- OpenRouter lifetime spend per key ---
print("\n--- OPENROUTER (lifetime spend per key) ---")
or_keys = _load_env_keys("~/.env.openrouter", "OPENROUTER_KEY_MW")
or_total = 0.0
for name, key in sorted(or_keys.items()):
    try:
        data = _get_json("https://openrouter.ai/api/v1/auth/key", key).get("data", {})
        usage = float(data.get("usage", 0))
        limit = data.get("limit")
        or_total += usage
        short = name.replace("OPENROUTER_KEY_MW_", "")
        if usage > 0 or limit is not None:
            limit_str = f" / ${limit:.2f}" if limit else ""
            print(f"  {short:25s} ${usage:.4f}{limit_str}")
    except (HTTPError, URLError, ValueError, KeyError):
        pass
print(f"  {'TOTAL':25s} ${or_total:.4f}")

# --- DeepSeek balance ---
print("\n--- DEEPSEEK (balance) ---")
ds_keys = _load_env_keys("~/.env.deepseek", "DEEPSEEK_KEY_MW_V3")
for name, key in ds_keys.items():
    try:
        data = _get_json("https://api.deepseek.com/user/balance", key)
        infos = data.get("balance_infos", [])
        if infos:
            info = infos[0]
            topped = float(info.get("topped_up_balance", 0))
            balance = float(info.get("total_balance", 0))
            used = topped - balance
            print(f"  Balance: ${balance:.2f} (topped up ${topped:.2f}, used ${used:.2f})")
        break
    except (HTTPError, URLError, ValueError, KeyError):
        pass

# --- Roundtable deliberation spend ---
print("\n--- ROUNDTABLE DELIBERATIONS ---")
rs_path = Path.home() / "roundtable" / "router_state.json"
if rs_path.exists():
    try:
        rs = json.loads(rs_path.read_text())
        outcomes = rs.get("outcomes", [])
        total = sum(o.get("cost", 0) for o in outcomes)
        print(f"  Total: ${total:.4f} across {len(outcomes)} deliberations")
        if outcomes:
            print(f"  Avg per run: ${total / len(outcomes):.4f}")
    except (OSError, json.JSONDecodeError):
        pass

# --- Delegation log analysis ---
print("\n--- DELEGATION ACTIVITY (from delegation_log.jsonl) ---")
log_path = Path(
    os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))
) / "roundtable" / "delegation_log.jsonl"
now = datetime.now(timezone.utc)
windows = {"last 24h": 1, "last 7d": 7, "last 30d": 30, "all time": 99999}

if not log_path.exists():
    print("  No delegation log yet. Run a roundtable/delegate invocation first.")
else:
    records = []
    with open(log_path) as f:
        for line in f:
            line = line.strip()
            if not line: continue
            try:
                records.append(json.loads(line))
            except json.JSONDecodeError:
                pass

    for label, days in windows.items():
        cutoff = now - timedelta(days=days)
        window = [
            r for r in records
            if datetime.fromisoformat(r["timestamp"]) >= cutoff
        ]
        if not window:
            continue
        win_cost = sum(r.get("total_cost", 0) for r in window)
        win_elapsed = sum(r.get("elapsed_s", 0) for r in window)
        est_saved = len(window) * ESTIMATED_CLAUDE_COST_PER_DELEGATED_TASK
        net_saved = est_saved - win_cost
        print(f"  {label:10s} {len(window):4d} runs  "
              f"actual=${win_cost:.4f}  "
              f"est saved ≈${net_saved:.2f}  "
              f"({win_elapsed/60:.1f} min)")

    # Top strategies
    strat_counts = {}
    for r in records:
        s = r.get("strategy", "?")
        strat_counts[s] = strat_counts.get(s, 0) + 1
    if strat_counts:
        print("\n  Strategies used:")
        for s, n in sorted(strat_counts.items(), key=lambda x: -x[1])[:6]:
            print(f"    {s:25s} {n}")

# --- Disclaimer + Claude note ---
print("\n--- CLAUDE CODE USAGE ---")
print("  No programmatic API. Run /check-usage or /usage inside Claude Code")
print("  to see 5-hour and 7-day rate-limit percentages.")

print("\n--- NOTES ---")
print(f"  'est saved' = num_delegations × ${ESTIMATED_CLAUDE_COST_PER_DELEGATED_TASK} placeholder cost")
print("  This is a DIRECTIONAL estimate. True savings are not knowable without")
print("  a Claude usage API. Treat as 'delegation is happening' signal, not")
print("  as precise accounting.")

print()
PYEOF
```

After running, summarize the output for the user in 2-3 bullet points:
- Total API spend across providers
- Recent delegation activity (last 7 days if available)
- One actionable observation (e.g., "you haven't used /delegate in N days" or "OpenRouter spend is growing")

## Notes

- Requires Python 3 and internet access to query OpenRouter and DeepSeek APIs
- Won't show Claude usage — no API exists for Claude Code subscriptions
- The "estimated savings" figure is a placeholder multiplier, NOT a real calculation. Be honest about this when summarizing
- Reads:
  - `~/.env.openrouter` for OpenRouter MW keys
  - `~/.env.deepseek` for DeepSeek key
  - `~/roundtable/router_state.json` for deliberation history
  - `~/.local/share/roundtable/delegation_log.jsonl` for invocation log
- If any source is missing, the script skips it gracefully rather than failing
- Not destructive, read-only
