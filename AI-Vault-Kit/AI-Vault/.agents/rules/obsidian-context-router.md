---
trigger: model_decision
description: "Use this rule when the request depends on previous conversations, personal preferences, existing projects, prior decisions or long-term knowledge stored in Obsidian."
---
# Obsidian context router

The user's long-term memory lives in an Obsidian vault exposed by the `obsidian` MCP server.

1. First read `00_SYSTEM/AI-INDEX.md` with the `vault_read` tool of the `obsidian` MCP server, and follow it.
2. Load context progressively (index → project overview → 3–5 relevant notes → 1 agent → ≤3 skills). Never read the whole vault or browse every folder.
3. Prefer `search_simple` / `search_query` to locate notes, then `vault_read` only the selected files.
4. Never invent missing information; report conflicts; prefer the most recent `confirmed` decision.
5. Write to memory only per `00_SYSTEM/MEMORY-POLICY.md` (append/patch, never delete, never store secrets).
6. If the `obsidian` server is unavailable, say so and continue without memory rather than guessing.
