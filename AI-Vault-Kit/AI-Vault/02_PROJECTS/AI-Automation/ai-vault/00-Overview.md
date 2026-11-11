---
type: project
project: ai-vault
category: AI-Automation
file: overview
status: active
created: 2026-11-11
updated: 2026-11-11
tags: [project, ai-vault, mcp, obsidian]
aliases: [AI-Vault, mémoire IA centralisée]
---
# AI-Vault — Vue d'ensemble

## Description
Mémoire centrale commune à plusieurs IA (ChatGPT, Claude, Gemini, Google Antigravity, futures IA), basée sur ce coffre Obsidian exposé localement via le plugin *Local REST API with MCP*.

## Objectifs (énoncés par l'utilisateur)
- Passer d'une IA à l'autre sans réexpliquer projets, préférences, choix techniques.
- Chargement sélectif : index → projet → notes → agent → skills.
- Agents spécialisés et skills chargés à la demande.

## Architecture
- Coffre : `%USERPROFILE%\Documents\AI-Vault` (par défaut).
- Serveur MCP : `https://127.0.0.1:27124/mcp/` (Bearer, localhost uniquement).
- Antigravity : `%USERPROFILE%\.gemini\config\mcp_config.json` + agents/skills/règle dans `.agents/` (et copie globale optionnelle dans `~/.gemini/config/`).

## Situation actuelle
Kit généré le 2026-11-11 ; déploiement Windows et connexion MCP à réaliser par l'utilisateur (voir 03-Tasks).
