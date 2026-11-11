---
type: template
id: project-template
updated: 2026-11-11
tags: [template]
---
# Modèle de projet

Structure : `02_PROJECTS/<Catégorie>/<projet-id>/`
| Fichier | Rôle |
|---|---|
| `00-Overview.md` | Description, objectifs, situation actuelle, architecture |
| `01-Requirements.md` | Contraintes, spécifications, besoins |
| `02-Decisions.md` | Décisions datées avec raison et statut |
| `03-Tasks.md` | Terminé / en cours / à faire |
| `04-References.md` | Sources, documentation, liens |
| `05-Session-Summaries/` | Résumés des sessions importantes |

## Création
1. Copier `06_TEMPLATES/Project-Skeleton/` vers `02_PROJECTS/<Catégorie>/<projet-id>/` (via MCP : `vault_read` chaque fichier modèle puis `vault_write` avec `ifNoneMatch: "*"`).
2. Remplacer `<projet-id>`, `<Catégorie>`, les dates — **uniquement avec des informations fournies par l'utilisateur**.
3. Ajouter une ligne dans `00_SYSTEM/PROJECTS-INDEX.md`.

`projet-id` : minuscules, tirets (ex. `crypto-grid-bot`).
