---
type: template
id: agent-template
updated: 2026-11-11
tags: [template]
---
# Modèle d'agent Antigravity

Fichier natif : `.agents/agents/<nom>.md` (workspace) ou `%USERPROFILE%\.gemini\config\agents\<nom>.md` (global).
Propriétés documentées : `name`, `description` (requis), `tools`, `mainAgent`, `subagent`, `model` (inherit|flash|pro), `commandExecutionPolicy` (off|auto|eager|sandbox), `mcpServers`, `skills`, `plugins`.

```markdown
---
name: <nom-en-minuscules>
description: <Quand le planificateur doit déléguer à cet agent. Précis, 1–2 phrases.>
subagent: true
mainAgent: true
model: inherit
commandExecutionPolicy: sandbox
skills:
  - skills/<skill-1>
---
# Rôle
# Spécialité
# Responsabilités
# Limites
# Projets traités
# Skills
# Outils nécessaires
# Règles de restitution
```
> `tools:` remplace la liste d'outils par défaut ; un nom erroné peut bloquer l'agent. Ne l'ajouter qu'avec des noms vérifiés.
Puis déclarer l'agent dans `04_AGENTS/AGENTS-INDEX.md`.
