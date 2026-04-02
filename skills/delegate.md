Delegate a coding task to cheaper models via roundtable instead of using Claude Code's Opus tokens.

## Instructions

When the user wants to save Claude Code usage limits by delegating work to cheaper API models:

1. Take the user's task description (everything after `/delegate`)

2. Determine which Python command works:
   - Try `python3 --version` first. If it works, use `python3`.
   - If not, try `python --version`. If it works, use `python`.

3. Determine the task type and run the appropriate delegation:

**For code generation tasks:**
```bash
<python> -c "
from roundtable.core.panel import Panel
from roundtable.core.engine import DeliberationEngine
from roundtable.strategies.specialist_chain import SpecialistChainStrategy
from roundtable.core.keys import load_keys

panel = Panel.from_dict({
    'deepseek-v3': {
        'backend': 'openai_compat',
        'base_url': 'https://api.deepseek.com',
        'model_id': 'deepseek-chat',
        'cost_per_call_est': 0.001,
        'role': 'code_generator',
        'expertise': 'Write clean, correct, production-quality code.',
    },
    'openrouter-gemini-flash': {
        'backend': 'openai_compat',
        'base_url': 'https://openrouter.ai/api/v1',
        'model_id': 'google/gemini-2.5-flash',
        'cost_per_call_est': 0.001,
        'role': 'code_reviewer',
        'expertise': 'Review code for bugs, edge cases, and improvements.',
    },
})

strategy = SpecialistChainStrategy()
strategy.set_models(['deepseek-v3', 'openrouter-gemini-flash'])
engine = DeliberationEngine(panel, strategy=strategy)
result = engine.run(
    '''TASK_DESCRIPTION_HERE''',
    rounds=2,
    validate=True,
    auto_improve=True,
)

for rnd in result.rounds:
    for name, output in rnd.outputs.items():
        if output and not output.startswith('ERROR'):
            print(f'=== {name} (R{rnd.round_num}) ===')
            print(output)
            print()

print(f'Cost: \${result.total_cost:.4f} | Opus tokens saved: ~10-50x equivalent')
" 2>&1
```

**For research/analysis tasks:**
Use the regular `/roundtable` skill instead — it's already optimized for multi-model analysis.

4. Present the results to the user:
   - Show the generated code or analysis
   - Report the cost (typically $0.002-0.005)
   - Note: "This used DeepSeek V3 + Gemini Flash instead of Opus, saving usage limit"
   - If the code needs refinement, the user can ask Claude Code to make targeted edits (small Opus usage) rather than regenerating from scratch

5. If the delegated result has issues:
   - Try running the task through a full roundtable deliberation (more models, more review)
   - Only fall back to Claude Code (Opus) for tasks that require deep reasoning or complex multi-file changes

## Notes
- DeepSeek V3 is the best code generation model available via API ($0.001/call)
- This saves Claude Code usage limits by offloading heavy generation to cheaper models
- Claude Code (Opus) should be used for: orchestration, small edits, complex reasoning, multi-file refactors
- Cheaper models should be used for: initial code generation, research, reviews, test writing
- Typical savings: a coding task that would use ~5% of Opus daily limit costs $0.003 via delegation
- The SpecialistChain strategy ensures code is generated then reviewed before returning
- auto_improve=True means the system learns which models are best at which coding tasks
