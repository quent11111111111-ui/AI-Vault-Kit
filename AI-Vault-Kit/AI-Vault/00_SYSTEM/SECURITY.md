---
type: system
id: security
status: active
updated: 2026-11-11
tags: [system, security]
---
# SECURITY

1. **Aucun secret dans le coffre.** La clé API Obsidian est stockée uniquement dans les fichiers de configuration locaux des clients MCP (ex. `%USERPROFILE%\.gemini\config\mcp_config.json`).
2. **Localhost uniquement** : `https://127.0.0.1:27124/mcp/`. Pas de redirection de port, pas d'exposition Internet, pas de tunnel public.
3. **Authentification obligatoire** (Bearer). Ne jamais la désactiver.
4. **TLS** : faire confiance à l'autorité locale du plugin (CA à contraintes de nom : 127.0.0.1/localhost uniquement) plutôt que désactiver la vérification. Le serveur HTTP non chiffré (27123) reste **désactivé**.
5. **Outils MCP** autorisés par défaut : lecture/recherche + `vault_write`, `vault_append`, `vault_patch`, `open_file`.
   **Bloqués** : `vault_delete`, `vault_move`, `vault_copy`, `command_execute`, `command_list`, `vault_get_download_url`, `vault_get_upload_url`, `events_get_listener_url`.
6. Les écritures MCP restent en mode « Ask » (approbation) dans Antigravity sauf décision contraire de l'utilisateur.
7. Le plugin refuse déjà tout accès à `.obsidian/` via l'API.
8. Toute IA qui détecte un secret dans une note doit le signaler et proposer son retrait — sans le recopier.
