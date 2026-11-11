---
name: project-management
description: Creates projects from the vault template and records project decisions, task progress, references and session summaries in the Obsidian vault via MCP, following the memory policy. Use when starting a new project, logging a decision, updating tasks or closing an important work session.
---
# Project-Management

## Activation
Création de projet, décision à consigner, changement d'avancement, fin de session importante.

## Instructions
- Respecter `00_SYSTEM/MEMORY-POLICY.md`. Ajouter plutôt que remplacer. Jamais de suppression.
- Décision non confirmée explicitement par l'utilisateur → `status: proposed` et demander validation.
- Toujours mettre à jour `updated:` du frontmatter.

## Procédure
### A. Créer un projet
1. Obtenir de l'utilisateur : nom, catégorie, objectif (ne rien inventer).
2. Pour chaque fichier de `06_TEMPLATES/Project-Skeleton/` : `vault_read` puis `vault_write` vers `02_PROJECTS/<Catégorie>/<id>/…` avec `ifNoneMatch: "*"` (refuse d'écraser).
3. Remplacer les espaces réservés par les seules informations fournies.
4. Ajouter la ligne du projet dans `00_SYSTEM/PROJECTS-INDEX.md` (`vault_patch` ou `vault_append` sous le tableau).
### B. Consigner une décision
`vault_append` dans `<projet>/02-Decisions.md` au format de `06_TEMPLATES/Decision-Template.md`. Si elle remplace une ancienne, l'ancienne est marquée `superseded` (via `vault_patch`) — jamais effacée.
### C. Mettre à jour les tâches
`vault_get_document_map` sur `03-Tasks.md` puis `vault_patch` ciblant la section (`En cours`, `À faire`, `Terminées`).
### D. Résumé de session
Nouveau fichier `05-Session-Summaries/AAAA-MM-JJ-<sujet>.md` (template `Session-Summary-Template.md`), `vault_write` + `ifNoneMatch: "*"`.

## Limites
Pas de `vault_delete` / `vault_move` / `vault_copy`. Pas de secrets. Pas de modification du profil.

## Références
`06_TEMPLATES/`, `00_SYSTEM/MEMORY-POLICY.md`.
