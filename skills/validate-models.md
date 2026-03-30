Validate that all roundtable model IDs are still active on their providers before running a deliberation.

## Instructions

Before a roundtable deliberation, validate that every model in the auto-detect panel is still available on its provider's API. This prevents silent failures where 404/400 errors waste time and reduce panel coverage.

1. Determine which Python command works on this machine:
   - Try `python3 --version` first. If it works, use `python3`.
   - If not, try `python --version`. If it works, use `python`.

2. Run the validation script:
```bash
<python> -c "
import requests, json, sys
from roundtable.core.keys import load_keys

keys = load_keys()

# Provider model list endpoints (OpenAI-compatible)
PROVIDERS = {
    'groq': 'https://api.groq.com/openai/v1/models',
    'cerebras': 'https://api.cerebras.ai/v1/models',
    'deepseek': 'https://api.deepseek.com/models',
    'openrouter': 'https://openrouter.ai/api/v1/models',
}

# Current model IDs used by roundtable CLI auto-detect
EXPECTED = {
    'groq': ['openai/gpt-oss-120b', 'meta-llama/llama-4-scout-17b-16e-instruct', 'llama-3.3-70b-versatile'],
    'cerebras': ['qwen-3-235b-a22b-instruct-2507', 'llama3.1-8b'],
    'deepseek': ['deepseek-chat', 'deepseek-reasoner'],
    'openrouter': ['deepseek/deepseek-chat-v3-0324', 'google/gemini-2.5-flash'],
}

all_ok = True
for provider, url in PROVIDERS.items():
    # Get any key from this provider
    provider_keys = keys.get(provider, {})
    if not provider_keys:
        print(f'SKIP {provider}: no keys')
        continue
    api_key = list(provider_keys.values())[0]

    try:
        r = requests.get(url, headers={'Authorization': f'Bearer {api_key}'}, timeout=15)
        if r.status_code != 200:
            print(f'WARN {provider}: /models returned {r.status_code}')
            continue
        available = {m.get('id', '') for m in r.json().get('data', [])}
        for model_id in EXPECTED.get(provider, []):
            if model_id in available:
                print(f'  OK  {provider}/{model_id}')
            else:
                print(f'  FAIL {provider}/{model_id} -- NOT FOUND')
                # Show similar matches
                stem = model_id.split('/')[-1].split('-')[0]
                similar = sorted([m for m in available if stem in m])[:3]
                if similar:
                    print(f'       Possible replacements: {similar}')
                all_ok = False
    except Exception as e:
        print(f'WARN {provider}: {e}')

if all_ok:
    print()
    print('All model IDs validated successfully.')
else:
    print()
    print('ACTION REQUIRED: Update stale model IDs in roundtable/cli/run.py')
    sys.exit(1)
"
```

3. Report results to the user:
   - Which models passed validation
   - Which models failed and what the likely replacement ID is
   - If any failed, suggest updating `roundtable/cli/run.py` PROVIDER_MODELS dict

## Notes
- Run this before any deliberation if models have been failing
- Each provider exposes a `/models` endpoint that lists currently available model IDs
- Model IDs change without notice when providers rename, version, or deprecate models
- LiteLLM maintains a comprehensive model catalog at:
  https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json
  This can be used as a secondary reference for model metadata (costs, context windows, deprecation dates)
- Groq is geo-blocked in some countries (e.g., Thailand) -- 403 errors are not model ID issues
