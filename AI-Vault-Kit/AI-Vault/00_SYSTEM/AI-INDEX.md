---
type: system
id: ai-index
status: active
version: 1.0
updated: 2026-11-11
tags: [system, router]
---
# AI-INDEX — Routeur de contexte

> Point d'entrée unique pour toute IA (Antigravity, Claude, ChatGPT, Gemini…).
> Ce fichier est volontairement court. **Ne lis jamais tout le coffre.**

## 0. Faut-il consulter la mémoire ? (Règle C — pertinence)
| Demande | Action |
|---|---|
| Question générale, sans lien avec l'utilisateur ou ses projets | **Ne pas** lire la mémoire. Répondre directement. |
| Mentionne un projet, une décision passée, « mon/ma/mes », « reprendre », « comme d'habitude » | Continuer au §1. |
| Dépend des préférences personnelles (style, langue, outils) | Lire seulement `00_SYSTEM/PROFILE-INDEX.md`. |

## 1. Chargement progressif (Règle B)
Ne passer au niveau suivant que si le précédent ne suffit pas.

| Niveau | Contenu | Fichier(s) |
|---|---|---|
| 1 | Index + règles courtes | ce fichier, `PROJECTS-INDEX.md` |
| 2 | Description du projet concerné | `<projet>/00-Overview.md` |
| 3 | Notes et décisions pertinentes | `02-Decisions.md`, `03-Tasks.md`, dernier résumé de session, notes trouvées par recherche |
| 4 | Agent spécialisé | `AGENTS-INDEX.md` → 1 agent |
| 5 | Skills nécessaires | `SKILLS-INDEX.md` → instructions complètes du/des skill(s) |

**Limites de départ** (dépassables si la tâche l'exige, en le justifiant) :
1 projet principal · 3 à 5 notes au premier passage · 1–2 agents · 3 skills max.

## 2. Procédure (Règle A — recherche contextuelle)
1. **Identifier le sujet** : extraire 2–4 mots-clés de la demande.
2. **Identifier le projet** : lire `00_SYSTEM/PROJECTS-INDEX.md` et faire correspondre les mots-clés aux colonnes *id / alias / mots-clés*.
   - Aucun projet correspondant → le **dire explicitement**, proposer la création via `06_TEMPLATES/Project-Template.md`. **Ne jamais inventer d'historique.**
3. **Rechercher** (MCP Obsidian, dans cet ordre) :
   - `search_simple` avec les mots-clés, limité au dossier du projet (`maxResults` ≤ 10) ;
   - `search_query` (JsonLogic sur le frontmatter : `project`, `type`, `status`) pour filtrer ;
   - `vault_get_document_map` pour cibler une section avant de lire une longue note.
4. **Lire** uniquement les fichiers sélectionnés avec `vault_read`.
5. **Dernières décisions** : `02-Decisions.md` (entrées datées, statut `confirmed` prioritaire) + résumé de session le plus récent de `05-Session-Summaries/`.
6. **Choisir un agent** (si la tâche est spécialisée) : `00_SYSTEM/AGENTS-INDEX.md`.
7. **Choisir les skills** : uniquement ceux dont la description correspond (`00_SYSTEM/SKILLS-INDEX.md`).
8. **Répondre** en citant les notes utilisées (chemins).
9. **Mémoriser** si nécessaire selon `00_SYSTEM/MEMORY-POLICY.md`.

Ne poser une question à l'utilisateur **qu'après** avoir vérifié que la réponse n'existe pas déjà dans le coffre.

## 3. Fiabilité (Règle D — informations manquantes)
- Ne jamais inventer. Une information absente est signalée comme absente.
- Statuts : `hypothesis` < `proposed` < `confirmed` ; `superseded` = obsolète. Une hypothèse n'est jamais une décision.
- Vérifier les dates (`updated`, date de l'entrée).
- Contradiction entre notes → **signaler le conflit**, privilégier la décision `confirmed` la plus récente.

## 4. Écriture
Toute écriture suit `00_SYSTEM/MEMORY-POLICY.md` et `00_SYSTEM/SECURITY.md` :
ajout (`vault_append` / `vault_patch`) plutôt que remplacement ; jamais de suppression ; jamais de secret.

## 5. Carte du coffre
`00_SYSTEM` système · `01_PROFILE` profil (confirmé uniquement) · `02_PROJECTS/<Catégorie>/<projet-id>/` projets · `03_KNOWLEDGE` connaissances durables · `04_AGENTS` catalogue agents · `05_SKILLS` catalogue skills · `06_TEMPLATES` modèles · `90_ARCHIVE` archives · `99_INBOX` à trier · `.agents/` définitions natives Antigravity (invisible dans Obsidian).
