---
type: project
project: ai-vault
file: decisions
status: active
updated: 2026-11-11
tags: [project, ai-vault, decisions]
---
# Décisions

## Journal
### 2026-11-11 — Obsidian comme mémoire centrale via MCP
- Statut : confirmed
- Décision : utiliser le plugin « Local REST API with MCP » (`obsidian-local-rest-api`) comme serveur MCP unique.
- Raison : demande explicite de l'utilisateur ; serveur intégré à Obsidian.
- Source : utilisateur

### 2026-11-11 — Déploiement par kit + script PowerShell
- Statut : confirmed
- Décision : l'agent tournant sur une VM distante sans accès au PC, le système est livré comme kit (coffre + `.agents` + scripts `Install-AIVault.ps1` / `Test-AIVault.ps1`) exécuté par l'utilisateur sous Windows.
- Source : utilisateur (choix de l'option recommandée)

### 2026-11-11 — Projets rangés par catégorie
- Statut : proposed
- Décision : `02_PROJECTS/<Catégorie>/<projet-id>/` ; les 4 dossiers initiaux sont des catégories, pas des projets.
- Raison : l'utilisateur a précisé que ces dossiers sont des exemples de catégories.
- Source : session

### 2026-11-11 — Agents sans champ `tools`
- Statut : proposed
- Décision : les agents héritent de l'outillage par défaut (dont `call_mcp_tool`) ; restriction faite par `enabledTools` du serveur MCP + approbations.
- Raison : `tools:` remplace la liste par défaut et un nom erroné peut bloquer le sous-agent (problème connu documenté).
- Source : session
