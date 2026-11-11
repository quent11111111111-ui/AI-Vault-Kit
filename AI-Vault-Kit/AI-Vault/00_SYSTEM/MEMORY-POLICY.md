---
type: system
id: memory-policy
status: active
updated: 2026-11-11
tags: [system, memory]
---
# MEMORY-POLICY — Ce que les IA enregistrent

## Enregistrer
- Décisions importantes (avec date, raison, statut).
- Informations durables sur un projet, contraintes techniques.
- Préférences **confirmées** par l'utilisateur.
- Découvertes réellement réutilisables.
- Changements de statut / d'avancement.
- Résumés des sessions importantes.

## Ne jamais enregistrer
- Conversations banales, réponses sans valeur durable.
- Informations incertaines présentées comme des faits (les marquer `hypothesis`).
- **Clés API, mots de passe, tokens, certificats privés.**
- Données sensibles sans nécessité.

## Où écrire
| Information | Destination | Outil MCP |
|---|---|---|
| Décision projet | `<projet>/02-Decisions.md` | `vault_append` / `vault_patch` |
| Tâches | `<projet>/03-Tasks.md` | `vault_patch` (section) |
| Source | `<projet>/04-References.md` | `vault_append` |
| Résumé de session | `<projet>/05-Session-Summaries/AAAA-MM-JJ-<sujet>.md` | `vault_write` (nouveau fichier, `ifNoneMatch: "*"`) |
| Connaissance générale | `03_KNOWLEDGE/<domaine>/` | `vault_write` (nouveau fichier) |
| Incertain / à trier | `99_INBOX/` | `vault_write` |

## Validation
- Décision non explicitement confirmée par l'utilisateur → **demander validation** ou l'enregistrer `status: proposed`.
- Profil (`01_PROFILE/`) : jamais modifié sans confirmation explicite.
- Ne jamais remplacer ni supprimer une note existante sans autorisation explicite. Utiliser `ifMatch` (version renvoyée par `vault_read`) pour éviter d'écraser une modification concurrente.
- Toujours mettre à jour `updated:` dans le frontmatter de la note modifiée.

## Format d'une entrée de décision
```
### AAAA-MM-JJ — <titre court>
- Statut : confirmed | proposed | hypothesis | superseded
- Décision : …
- Raison : …
- Source : <utilisateur | session | note>
- Remplace : <lien éventuel>
```
