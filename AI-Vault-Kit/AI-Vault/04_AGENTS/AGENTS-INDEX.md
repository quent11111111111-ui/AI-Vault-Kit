---
type: catalog
id: agents-index
status: active
updated: 2026-11-11
tags: [agents]
---
# Catalogue des agents

Définitions natives Antigravity : `.agents/agents/<nom>.md` (frontmatter officiel : `name`, `description`, `subagent`, `mainAgent`, `model`, `commandExecutionPolicy`, `skills`).
Tous sont `subagent: true` (appelables par l'agent principal via `invoke_subagent`) et `mainAgent: true` (sélectionnables directement).

| Agent | Quand l'utiliser | Skills | Écrit dans le coffre ? | Fichier |
|---|---|---|---|---|
| `project-researcher` | recherche documentaire, vérification, documentation | context-retrieval, web-research, knowledge-management | Sur validation | `.agents/agents/project-researcher.md` |
| `developer` | Python, APIs, automatisation, architecture, débogage, tests | context-retrieval, python-development, project-management | Sur validation (decisions/tasks) | `.agents/agents/developer.md` |
| `reviewer` | vérification, erreurs, sécurité, cohérence, validation | context-retrieval, code-review | Non (lecture seule) | `.agents/agents/reviewer.md` |

## Règles de sélection
- Tâche simple → aucun sous-agent, l'agent principal agit seul.
- Tâche spécialisée → **un** agent. Enchaînement typique : `developer` puis `reviewer`.
- Jamais tous les agents en parallèle par défaut.

## Pour les autres IA (Claude, ChatGPT…)
Elles ne lisent pas `.agents/` nativement : leur demander d'adopter le rôle décrit ci-dessus en lisant le fichier de l'agent via MCP (`vault_read` n'accède pas aux dossiers cachés → utiliser ce catalogue comme résumé).
