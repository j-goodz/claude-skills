Compact conversation context after building a plan, then re-read the plan to keep it salient.

## Instructions

1. Run the `/compact` command to compress the current conversation context.
2. After compaction completes, check if a plan file exists (e.g., `plan.md`, `TODO.md`, or a todo list in the conversation). If one exists, read it back to bring it into the fresh context.
3. Continue following the plan from where you left off. Do not restart completed steps.

## Notes

- Claude Code disabled automatic compaction before plan builds, which means long planning sessions can exhaust the context window.
- This skill re-adds that functionality as a manual trigger you invoke after the plan is created.
- Use it after creating a large plan to free up context tokens while preserving the plan itself.
- The plan is re-read after compaction to ensure it stays in the active context and does not get lost during compression.
