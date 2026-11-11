---
type: project
project: ai-vault
file: requirements
status: active
updated: 2026-11-11
tags: [project, ai-vault, requirements]
---
# Exigences (fournies par l'utilisateur)
- Aucune suppression de données existantes ; sauvegarde avant toute modification de configuration.
- Aucun secret dans le coffre, un dépôt Git ou un rapport.
- Serveur MCP uniquement sur localhost, authentification active, TLS validé via la CA locale (accord requis avant ajout au magasin racine).
- Outils destructifs (`vault_delete`, `vault_move`, `vault_copy`, `command_execute`) non autorisés par défaut.
- Fusion de `mcp_config.json` sans supprimer les autres serveurs.
- Pas d'Obsidian Sync/Publish ni de service payant sans accord.
- Empreinte de contexte minimale : pas de gros `AGENTS.md`/`GEMINI.md`.
