---
type: profile
id: equipment
status: active
confidence: confirmed-only
updated: 2026-11-11
tags: [profile, equipment]
---
# Équipement & Environnement Système

## Poste de travail principal (déclaré par l'utilisateur)
- **Système d'exploitation :** Windows (PowerShell utilisé pour l'administration locale).
- **Emplacement standard du coffre :** `%USERPROFILE%\Documents\AI-Vault`
- **Configuration globale Antigravity :** `%USERPROFILE%\.gemini\config\mcp_config.json`

## Environnement Cloud / Sandbox Antigravity (session distante)
- **OS VM distante :** Debian GNU/Linux 12 (bookworm) x86_64 (`/home/antigravity`)
- **Node.js :** v24.22.2 / **npm :** 11.21.2
- **PowerShell Core (installé dans la VM) :** v7.7.0
- **Stockage persistant inter-sessions :** `/home/antigravity/.gemini` (`/shared/user/.gemini`)
